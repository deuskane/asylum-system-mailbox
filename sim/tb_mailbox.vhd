-------------------------------------------------------------------------------
-- Title      : tb_mailbox
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM/SBI self-checking testbench for sbi_mailbox
--              sbi_mailbox loops the SW2HW FIFO (TX) of each channel back
--              into its HW2SW FIFO (RX) : the bytes written in a channel are
--              read back in order from the same channel. The capacity of a
--              channel is DEPTH_TX + DEPTH_RX.
--              Blocking accesses : a read of an empty channel / a write in a
--              full channel keeps sbi ready low. The only initiator is the
--              SBI port of the testbench, so a stalled access can not be
--              completed by an access from the other side : the stall is
--              checked during C_STALL_CYCLES cycles then the access is
--              aborted (cs/re/we released) by the testbench.
--              Non blocking accesses (BLOCKING_READ/WRITE = false) : such an
--              access completes without wait state and has no effect; a read
--              polls the status register until a data is available.
--              The status registers (empty, full) are checked against the
--              model of the channel.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.mailbox_pkg.all;
use     asylum.mailbox_csr_pkg.all;

entity tb_mailbox is
  generic (
    FIFO0_DEPTH_TX : natural := 4;
    FIFO0_DEPTH_RX : natural := 4;
    FIFO1_DEPTH_TX : natural := 4;
    FIFO1_DEPTH_RX : natural := 4;
    BLOCKING_READ  : boolean := true;
    BLOCKING_WRITE : boolean := true
  );
end entity tb_mailbox;

architecture sim of tb_mailbox is

  constant C_SCOPE        : string  := "TB_MAILBOX";
  constant C_ADDR_WIDTH   : natural := MAILBOX_ADDR_WIDTH;
  constant C_DATA_WIDTH   : natural := MAILBOX_DATA_WIDTH;
  constant C_STALL_CYCLES : natural := 16;   -- Cycles with ready = '0' checked on a blocked access
  constant C_NB_RANDOM    : natural := 200;  -- Random push/pop operations per channel
  constant C_POLL_MAX     : natural := 16;   -- Status reads before a non blocking read

  type t_addr_array is array (natural range <>) of unsigned(C_ADDR_WIDTH-1 downto 0);
  type t_nat_array  is array (natural range <>) of natural;

  constant C_FIFO         : t_addr_array(0 to 1) := (MAILBOX_FIFO0, MAILBOX_FIFO1);
  constant C_CAPACITY     : t_nat_array (0 to 1) := (FIFO0_DEPTH_TX + FIFO0_DEPTH_RX,
                                                     FIFO1_DEPTH_TX + FIFO1_DEPTH_RX);
  constant C_STATUS       : t_addr_array(0 to 1) := (MAILBOX_STATUS0, MAILBOX_STATUS1);

  signal clk_i            : std_logic := '0';
  signal clk_ena          : boolean   := true;
  signal arst_b_i         : std_logic := '0';

  signal sbi_ini          : sbi_ini_t(addr (C_ADDR_WIDTH-1 downto 0),
                                      wdata(C_DATA_WIDTH-1 downto 0));
  signal sbi_tgt          : sbi_tgt_t(rdata(C_DATA_WIDTH-1 downto 0));

  signal sbi_if           : t_sbi_if(addr (C_ADDR_WIDTH-1 downto 0),
                                     wdata(C_DATA_WIDTH-1 downto 0),
                                     rdata(C_DATA_WIDTH-1 downto 0));

begin

  clock_generator(clk_i, clk_ena, 20 ns, "TB Clock");

  ins_dut : sbi_mailbox
    generic map (
      NAME           => "MAILBOX",
      FIFO0_DEPTH_TX => FIFO0_DEPTH_TX,
      FIFO0_DEPTH_RX => FIFO0_DEPTH_RX,
      FIFO1_DEPTH_TX => FIFO1_DEPTH_TX,
      FIFO1_DEPTH_RX => FIFO1_DEPTH_RX,
      BLOCKING_READ  => BLOCKING_READ,
      BLOCKING_WRITE => BLOCKING_WRITE
    )
    port map (
      clk_i          => clk_i,
      arst_b_i       => arst_b_i,
      sbi_ini_i      => sbi_ini,
      sbi_tgt_o      => sbi_tgt
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  p_sequencer : process
    variable v_checks : natural  := 0;
    variable v_seed1  : positive := 7;
    variable v_seed2  : positive := 1000 + FIFO0_DEPTH_TX*64 + FIFO0_DEPTH_RX*16 + FIFO1_DEPTH_TX*4 + FIFO1_DEPTH_RX;
    variable v_r      : real;
    variable v_data   : std_logic_vector(7 downto 0);

    -- Model of a channel
    type t_queue is array (0 to 255) of std_logic_vector(7 downto 0);
    variable v_queue  : t_queue;
    variable v_head   : natural;
    variable v_count  : natural;
    variable v_next   : natural;  -- Next byte value pushed

    procedure wr(constant addr : in unsigned; constant data : in std_logic_vector; constant msg : in string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_if, C_SCOPE);
    end procedure;

    procedure chk(constant addr : in unsigned; constant data : in std_logic_vector; constant msg : in string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_if, error, C_SCOPE);
      v_checks := v_checks + 1;
    end procedure;

    -- Access of an empty (read) / full (write) channel
    --   blocking     : check that ready stays low during C_STALL_CYCLES cycles, then abort it
    --   non blocking : check that the access completes without wait state
    procedure chk_stall(constant addr : in unsigned; constant is_read : in boolean; constant data : in std_logic_vector; constant msg : in string) is
      variable v_ready_low : boolean := true;
      variable v_blocking  : boolean;
    begin
      if is_read then
        v_blocking := BLOCKING_READ;
      else
        v_blocking := BLOCKING_WRITE;
      end if;
      wait until falling_edge(clk_i);
      sbi_if.cs    <= '1';
      sbi_if.addr  <= addr;
      if is_read then
        sbi_if.rena  <= '1';
      else
        sbi_if.wena  <= '1';
        sbi_if.wdata <= data;
      end if;
      if v_blocking then
        for i in 1 to C_STALL_CYCLES loop
          wait until rising_edge(clk_i);
          if sbi_if.ready /= '0' then
            v_ready_low := false;
          end if;
        end loop;
        check_value(v_ready_low, error, msg & " : ready low during " & integer'image(C_STALL_CYCLES) & " cycles", C_SCOPE);
      else
        wait until rising_edge(clk_i);
        check_value(sbi_if.ready, '1', error, msg & " : non blocking access completes without wait state", C_SCOPE);
      end if;
      v_checks := v_checks + 1;
      -- Abort / end the access
      sbi_if.cs    <= '0';
      sbi_if.rena  <= '0';
      sbi_if.wena  <= '0';
      sbi_if.addr  <= (others => '0');
      sbi_if.wdata <= (others => '0');
      wait until rising_edge(clk_i);
    end procedure;

    procedure model_reset is
    begin
      v_head  := 0;
      v_count := 0;
    end procedure;

    procedure push(constant f : in natural; constant msg : in string) is
      variable v : std_logic_vector(7 downto 0);
    begin
      v := std_logic_vector(to_unsigned(v_next mod 256, 8));
      v_next := v_next + 37;  -- distinct consecutive values
      wr(C_FIFO(f), v, msg);
      v_queue((v_head + v_count) mod 256) := v;
      v_count := v_count + 1;
    end procedure;

    -- Status expected from the model of the channel (bytes settled in the RX FIFO)
    procedure chk_status(constant f : in natural; constant msg : in string) is
      variable v : std_logic_vector(7 downto 0) := (others => '0');
    begin
      if v_count = 0 then
        v(0) := '1';  -- empty
      end if;
      if v_count = C_CAPACITY(f) then
        v(1) := '1';  -- full
      end if;
      chk(C_STATUS(f), v, "status" & integer'image(f) & " " & msg);
    end procedure;

    -- Non blocking read : poll the status until a data is available
    procedure wait_data(constant f : in natural) is
      variable v_status : std_logic_vector(7 downto 0);
    begin
      if not BLOCKING_READ then
        for i in 1 to C_POLL_MAX loop
          sbi_read(C_STATUS(f), v_status, "poll status" & integer'image(f), clk_i, sbi_if, C_SCOPE);
          exit when v_status(0) = '0';
        end loop;
        check_value(v_status(0), '0', error, "fifo" & integer'image(f) & " : status not empty before the read", C_SCOPE);
        v_checks := v_checks + 1;
      end if;
    end procedure;

    procedure pop(constant f : in natural; constant msg : in string) is
    begin
      wait_data(f);
      chk(C_FIFO(f), v_queue(v_head), msg);
      v_head  := (v_head + 1) mod 256;
      v_count := v_count - 1;
    end procedure;

    procedure do_reset is
    begin
      arst_b_i <= '0';
      wait for 100 ns;
      arst_b_i <= '1';
      wait until rising_edge(clk_i);
    end procedure;

    procedure settle is
    begin
      -- Let the bytes move from the TX FIFO to the RX FIFO
      for i in 1 to 4 loop
        wait until rising_edge(clk_i);
      end loop;
    end procedure;

  begin
    sbi_if <= init_sbi_if_signals(C_ADDR_WIDTH, C_DATA_WIDTH);
    do_reset;
    v_next := 1;

    log(ID_LOG_HDR, "FIFO0 TX/RX = " & integer'image(FIFO0_DEPTH_TX) & "/" & integer'image(FIFO0_DEPTH_RX) &
                    ", FIFO1 TX/RX = " & integer'image(FIFO1_DEPTH_TX) & "/" & integer'image(FIFO1_DEPTH_RX), C_SCOPE);

    for f in C_FIFO'range loop
      ---------------------------------------------------------------------
      log(ID_LOG_HDR, "fifo" & integer'image(f) & " T1 : a read of the empty channel stalls", C_SCOPE);
      ---------------------------------------------------------------------
      model_reset;
      chk_status(f, "after reset : empty");
      chk_stall(C_FIFO(f), true, x"00", "fifo" & integer'image(f) & " read after reset (empty)");
      settle;
      chk_status(f, "still empty after the read");

      ---------------------------------------------------------------------
      log(ID_LOG_HDR, "fifo" & integer'image(f) & " T2 : fill (" & integer'image(C_CAPACITY(f)) & " bytes), write in full channel stalls, read back in order", C_SCOPE);
      ---------------------------------------------------------------------
      for i in 1 to C_CAPACITY(f) loop
        push(f, "fifo" & integer'image(f) & " push " & integer'image(i));
        settle;
        chk_status(f, "after push " & integer'image(i));
      end loop;
      chk_stall(C_FIFO(f), false, x"EE", "fifo" & integer'image(f) & " write in the full channel");
      settle;
      chk_status(f, "still full after the write (aborted or dropped)");
      for i in 1 to C_CAPACITY(f) loop
        pop(f, "fifo" & integer'image(f) & " pop " & integer'image(i));
      end loop;
      settle;
      chk_status(f, "after draining : empty");
      chk_stall(C_FIFO(f), true, x"00", "fifo" & integer'image(f) & " read after draining (empty)");

      ---------------------------------------------------------------------
      log(ID_LOG_HDR, "fifo" & integer'image(f) & " T3 : write then read immediately (blocking read completes when the byte arrives)", C_SCOPE);
      ---------------------------------------------------------------------
      for i in 1 to 4 loop
        push(f, "fifo" & integer'image(f) & " push");
        pop (f, "fifo" & integer'image(f) & " pop just after the push");
      end loop;

      ---------------------------------------------------------------------
      log(ID_LOG_HDR, "fifo" & integer'image(f) & " T4 : " & integer'image(C_NB_RANDOM) & " random push/pop", C_SCOPE);
      ---------------------------------------------------------------------
      for i in 1 to C_NB_RANDOM loop
        uniform(v_seed1, v_seed2, v_r);
        if (v_count < C_CAPACITY(f)) and ((v_count = 0) or (v_r < 0.5)) then
          push(f, "fifo" & integer'image(f) & " random push");
        else
          pop (f, "fifo" & integer'image(f) & " random pop");
        end if;
      end loop;
      while v_count > 0 loop
        pop(f, "fifo" & integer'image(f) & " final pop");
      end loop;
      settle;
      chk_status(f, "after the random sequence : empty");
      chk_stall(C_FIFO(f), true, x"00", "fifo" & integer'image(f) & " read after the random sequence (empty)");
    end loop;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T5 : channels are independent", C_SCOPE);
    -------------------------------------------------------------------------
    -- fill fifo0, fifo1 stays empty
    model_reset;
    for i in 1 to C_CAPACITY(0) loop
      push(0, "fifo0 push");
    end loop;
    settle;
    chk_status(0, "fifo0 full");
    chk(MAILBOX_STATUS1, x"01", "status1 : fifo1 empty while fifo0 is full");
    chk_stall(MAILBOX_FIFO1, true, x"00", "fifo1 read while fifo0 is full (fifo1 empty)");
    wr (MAILBOX_FIFO1, x"C3", "fifo1 push 0xC3");
    wait_data(1);
    chk(MAILBOX_FIFO1, x"C3", "fifo1 pop 0xC3");
    for i in 1 to C_CAPACITY(0) loop
      pop(0, "fifo0 pop : content not modified by the fifo1 accesses");
    end loop;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T6 : status registers : writes ignored", C_SCOPE);
    -------------------------------------------------------------------------
    for a in C_STATUS'range loop
      wr (C_STATUS(a), x"FF", "Write status" & integer'image(a));
      chk(C_STATUS(a), x"01", "status" & integer'image(a) & " unchanged (empty) after the write");
    end loop;
    chk_stall(MAILBOX_FIFO0, true, x"00", "fifo0 still empty after the status writes");
    chk_stall(MAILBOX_FIFO1, true, x"00", "fifo1 still empty after the status writes");

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T7 : asynchronous reset flushes both channels", C_SCOPE);
    -------------------------------------------------------------------------
    wr(MAILBOX_FIFO0, x"11", "fifo0 push");
    wr(MAILBOX_FIFO1, x"22", "fifo1 push");
    settle;
    v_count := 1;  -- one byte in each channel
    chk_status(0, "one byte before reset");
    chk_status(1, "one byte before reset");
    do_reset;
    model_reset;
    chk_status(0, "empty after reset");
    chk_status(1, "empty after reset");
    chk_stall(MAILBOX_FIFO0, true, x"00", "fifo0 empty after reset");
    chk_stall(MAILBOX_FIFO1, true, x"00", "fifo1 empty after reset");

    log(ID_LOG_HDR, "Number of checks : " & integer'image(v_checks), C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process;

end architecture sim;
