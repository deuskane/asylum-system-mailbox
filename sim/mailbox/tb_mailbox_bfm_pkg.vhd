-------------------------------------------------------------------------------
-- Title      : tb_mailbox_bfm_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_bfm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_mailbox scenarios : configuration of the
--              DUT (generics), model of a channel, SBI accesses (SBI VIP),
--              accesses of an empty / full channel, checks of the status
--              registers and outputs, reset pulse.
--              sbi_mailbox loops the SW2HW FIFO (TX) of each channel back
--              into its HW2SW FIFO (RX) : the bytes written in a channel are
--              read back in order from the same channel. The capacity of a
--              channel is DEPTH_TX + DEPTH_RX.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (helpers of tb_mailbox)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.mailbox_csr_pkg.all;

package tb_mailbox_bfm_pkg is

  constant C_TB_SCOPE        : string  := "TB_MAILBOX_BFM";
  constant C_CLK_PERIOD      : time    := 20 ns;
  constant C_STALL_CYCLES    : natural := 16; -- Cycles with ready = '0' checked on a blocked access
  constant C_POLL_MAX        : natural := 16; -- Status reads before a non blocking read
  constant C_SETTLE_CYCLES   : natural := 4;  -- Bytes moved from the TX FIFO to the RX FIFO
  constant C_MAX_WAIT_CYCLES : natural := 4;  -- Wait states of a completed access

  subtype  byte_t  is std_logic_vector(8-1 downto 0);
  subtype  addr_t  is unsigned(MAILBOX_ADDR_WIDTH-1 downto 0);

  type     addr2_t is array (0 to 1) of addr_t;
  type     nat2_t  is array (0 to 1) of natural;

  -- Registers of the channels
  constant C_FIFO            : addr2_t := (MAILBOX_FIFO0  , MAILBOX_FIFO1  );
  constant C_STATUS          : addr2_t := (MAILBOX_STATUS0, MAILBOX_STATUS1);

  -- Fields of status<n> (bits of mailbox.hjson, mailbox_csr.h : the
  -- regtool VHDL package has no field constant)
  constant C_STATUS_EMPTY    : natural := 0;
  constant C_STATUS_FULL     : natural := 1;

  -- Bounded wait states : a completed access never waits more than
  -- C_MAX_WAIT_CYCLES cycles (status read : 1, blocking read of a byte just
  -- written : transfer from the TX FIFO to the RX FIFO)
  constant C_SBI_CFG         : t_sbi_bfm_config := (
    max_wait_cycles            => C_MAX_WAIT_CYCLES,
    max_wait_cycles_severity   => error,
    use_fixed_wait_cycles_read => false,
    fixed_wait_cycles_read     => 0,
    clock_period               => -1 ns,
    clock_period_margin        => 0 ns,
    clock_margin_severity      => TB_ERROR,
    setup_time                 => -1 ns,
    hold_time                  => -1 ns,
    bfm_sync                   => SYNC_ON_CLOCK_ONLY,
    match_strictness           => MATCH_EXACT,
    id_for_bfm                 => ID_BFM,
    id_for_bfm_wait            => ID_BFM_WAIT,
    id_for_bfm_poll            => ID_BFM_POLL,
    use_ready_signal           => true
  );

  -- Configuration of the DUT (generics of tb_mailbox), index : channel
  type cfg_t is record
    depth_tx       : nat2_t;  -- FIFO<n>_DEPTH_TX
    depth_rx       : nat2_t;  -- FIFO<n>_DEPTH_RX
    blocking_read  : boolean; -- BLOCKING_READ
    blocking_write : boolean; -- BLOCKING_WRITE
  end record cfg_t;

  -- Model of a channel : the bytes written and not read yet, in order
  type queue_t is array (0 to 255) of byte_t;
  type channel_t is record
    queue          : queue_t;
    head           : natural; -- Index of the next byte read
    count          : natural; -- Number of bytes in the channel
    next_value     : natural; -- Next byte written
  end record channel_t;

  -- Number of bytes a channel holds : DEPTH_TX + DEPTH_RX
  function capacity
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ) return natural;

  -- Empty channel f, first byte written 1 (fifo0) or 0x81 (fifo1) :
  -- the two channels never hold the same values
  function channel_init
    (constant f        : in    natural
    ) return channel_t;

  -- Channel f as a string ("fifo0", "fifo1")
  function fifo
    (constant f        : in    natural
    ) return string;

  -- SBI write
  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- SBI read and check
  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Access of an empty (read) / full (write) channel
  --   blocking     : ready stays low during C_STALL_CYCLES cycles, then the
  --                  testbench aborts the access (cs / re / we released) :
  --                  the only initiator can not unblock it
  --   non blocking : the access completes without wait state
  procedure chk_stall
    (constant cfg      : in    cfg_t
    ;constant addr     : in    unsigned
    ;constant is_read  : in    boolean
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Non blocking write : poll the status of channel f until it has a free
  -- slot, then check it has (blocking write : nothing). The bytes move from
  -- the TX FIFO to the RX FIFO in a few cycles : a write right after another
  -- one can find the TX FIFO full while the channel holds less than
  -- DEPTH_TX + DEPTH_RX bytes
  procedure wait_room
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Write the next byte of the model in channel f
  procedure push
    (constant cfg      : in    cfg_t
    ;variable ch       : inout channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Non blocking read : poll the status of channel f until a byte is
  -- available, then check it is (blocking read : nothing)
  procedure wait_data
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Read channel f and check the oldest byte of the model
  procedure pop
    (constant cfg      : in    cfg_t
    ;variable ch       : inout channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Check status<f> and the status outputs against the model : empty when
  -- the channel holds no byte, full when it holds capacity bytes
  procedure chk_status
    (constant cfg      : in    cfg_t
    ;constant ch       : in    channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

  -- Check of a status output bit
  procedure chk_bit
    (constant val      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    );

  -- Wait n rising edges
  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    );

  -- Let the bytes move from the TX FIFO to the RX FIFO
  procedure settle
    (signal   clk      : in    std_logic
    );

  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

end package tb_mailbox_bfm_pkg;

package body tb_mailbox_bfm_pkg is

  function capacity
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ) return natural is
  begin
    return cfg.depth_tx(f) + cfg.depth_rx(f);
  end function;

  function channel_init
    (constant f        : in    natural
    ) return channel_t is
    variable res : channel_t;
  begin
    res.queue      := (others => (others => '0'));
    res.head       := 0;
    res.count      := 0;
    res.next_value := 1 + 128*f;
    return res;
  end function;

  function fifo
    (constant f        : in    natural
    ) return string is
  begin
    return "fifo" & integer'image(f);
  end function;

  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_write(addr_value => addr
             ,data_value => data
             ,msg        => msg
             ,clk        => clk
             ,sbi_if     => sbi_if
             ,scope      => C_TB_SCOPE
             ,config     => C_SBI_CFG
             );
  end procedure;

  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_check(addr_value  => addr
             ,data_exp    => data
             ,msg         => msg
             ,clk         => clk
             ,sbi_if      => sbi_if
             ,alert_level => error
             ,scope       => C_TB_SCOPE
             ,config      => C_SBI_CFG
             );
  end procedure;

  procedure chk_stall
    (constant cfg      : in    cfg_t
    ;constant addr     : in    unsigned
    ;constant is_read  : in    boolean
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable ready_low : boolean := true;
    variable blocking  : boolean;
  begin
    if is_read
    then
      blocking := cfg.blocking_read;
    else
      blocking := cfg.blocking_write;
    end if;
    wait until falling_edge(clk);
    sbi_if.cs      <= '1';
    sbi_if.addr    <= addr;
    if is_read
    then
      sbi_if.rena  <= '1';
    else
      sbi_if.wena  <= '1';
      sbi_if.wdata <= data;
    end if;
    if blocking
    then
      for i in 1 to C_STALL_CYCLES loop
        wait until rising_edge(clk);
        if sbi_if.ready /= '0'
        then
          ready_low := false;
        end if;
      end loop;
      check_value(ready_low, error, msg & " : ready low during " & integer'image(C_STALL_CYCLES) & " cycles", C_TB_SCOPE);
    else
      wait until rising_edge(clk);
      check_value(sbi_if.ready, '1', error, msg & " : non blocking access completes without wait state", C_TB_SCOPE);
    end if;
    -- Abort / end the access
    wait until falling_edge(clk);
    sbi_if.cs      <= '0';
    sbi_if.rena    <= '0';
    sbi_if.wena    <= '0';
    sbi_if.addr    <= (others => '0');
    sbi_if.wdata   <= (others => '0');
    wait until rising_edge(clk);
  end procedure;

  procedure wait_room
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable status : byte_t;
  begin
    if not cfg.blocking_write
    then
      for i in 1 to C_POLL_MAX loop
        sbi_read(addr_value => C_STATUS(f)
                ,data_value => status
                ,msg        => "poll status" & integer'image(f)
                ,clk        => clk
                ,sbi_if     => sbi_if
                ,scope      => C_TB_SCOPE
                ,config     => C_SBI_CFG
                );
        exit when status(C_STATUS_FULL) = '0';
      end loop;
      check_value(status(C_STATUS_FULL), '0', error, fifo(f) & " : status not full before the write", C_TB_SCOPE);
    end if;
  end procedure;

  procedure push
    (constant cfg      : in    cfg_t
    ;variable ch       : inout channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable v : byte_t;
  begin
    wait_room(cfg, f, clk, sbi_if);
    v             := std_logic_vector(to_unsigned(ch.next_value mod 256, 8));
    ch.next_value := ch.next_value + 37; -- distinct consecutive values
    wr(C_FIFO(f), v, msg, clk, sbi_if);
    ch.queue((ch.head + ch.count) mod 256) := v;
    ch.count      := ch.count + 1;
  end procedure;

  procedure wait_data
    (constant cfg      : in    cfg_t
    ;constant f        : in    natural
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable status : byte_t;
  begin
    if not cfg.blocking_read
    then
      for i in 1 to C_POLL_MAX loop
        sbi_read(addr_value => C_STATUS(f)
                ,data_value => status
                ,msg        => "poll status" & integer'image(f)
                ,clk        => clk
                ,sbi_if     => sbi_if
                ,scope      => C_TB_SCOPE
                ,config     => C_SBI_CFG
                );
        exit when status(C_STATUS_EMPTY) = '0';
      end loop;
      check_value(status(C_STATUS_EMPTY), '0', error, fifo(f) & " : status not empty before the read", C_TB_SCOPE);
    end if;
  end procedure;

  procedure pop
    (constant cfg      : in    cfg_t
    ;variable ch       : inout channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    wait_data(cfg, f, clk, sbi_if);
    chk(C_FIFO(f), ch.queue(ch.head), msg, clk, sbi_if);
    ch.head  := (ch.head + 1) mod 256;
    ch.count := ch.count - 1;
  end procedure;

  procedure chk_status
    (constant cfg      : in    cfg_t
    ;constant ch       : in    channel_t
    ;constant f        : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector
    ;signal   full     : in    std_logic_vector
    ) is
    variable v : byte_t := (others => '0');
  begin
    if ch.count = 0
    then
      v(C_STATUS_EMPTY) := '1';
    end if;
    if ch.count = capacity(cfg, f)
    then
      v(C_STATUS_FULL)  := '1';
    end if;
    chk(C_STATUS(f), v, "status" & integer'image(f) & " " & msg, clk, sbi_if);
    -- Status outputs : same flags
    chk_bit(empty(f), v(C_STATUS_EMPTY), "fifo_empty_o(" & integer'image(f) & ") " & msg);
    chk_bit(full (f), v(C_STATUS_FULL  ), "fifo_full_o("  & integer'image(f) & ") " & msg);
  end procedure;

  procedure chk_bit
    (constant val      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    ) is
  begin
    check_value(val, exp, error, msg, C_TB_SCOPE);
  end procedure;

  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    ) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

  procedure settle
    (signal   clk      : in    std_logic
    ) is
  begin
    cycles(C_SETTLE_CYCLES, clk);
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait for 100 ns;
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
  end procedure;

end package body tb_mailbox_bfm_pkg;
