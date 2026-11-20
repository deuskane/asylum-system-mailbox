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
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_mailbox_tests_pkg), each one after a reset
--                           pulse ; "" : build and elaboration only
--              FIFO<n>_DEPTH_TX/RX, BLOCKING_READ/WRITE : generics of the
--              DUT
--              Blocking accesses : a read of an empty channel / a write in a
--              full channel keeps sbi ready low. The only initiator is the
--              SBI port of the testbench, so a stalled access can not be
--              completed by an access from the other side : the stall is
--              checked during C_STALL_CYCLES cycles then the access is
--              aborted (cs/re/we released) by the testbench.
--              Non blocking accesses (BLOCKING_READ/WRITE = false) : such an
--              access completes without wait state and has no effect; a read
--              polls the status register until a data is available, a write
--              until a slot is free (the bytes take a few cycles to move from
--              the TX FIFO to the RX FIFO : a write right after another one
--              can find the TX FIFO full before the channel is).
--              The status registers (empty, full) and the status outputs
--              (fifo_empty_o, fifo_full_o) are checked against the model of
--              the channel.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-- 2026-11-20  2.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_mailbox_<name>_pkg), helpers in
--                               tb_mailbox_bfm_pkg, reset pulse before each
--                               scenario
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.mailbox_pkg.all;
use     asylum.mailbox_csr_pkg.all;

library work;
use     work.tb_mailbox_bfm_pkg.all;
use     work.tb_mailbox_tests_pkg.all;

entity tb_mailbox is
  generic (
    TESTS_LIST     : string  := ""   -- Scenarios, e.g. "fill,random"
   ;FIFO0_DEPTH_TX : natural := 4
   ;FIFO0_DEPTH_RX : natural := 4
   ;FIFO1_DEPTH_TX : natural := 4
   ;FIFO1_DEPTH_RX : natural := 4
   ;BLOCKING_READ  : boolean := true
   ;BLOCKING_WRITE : boolean := true
  );
end entity tb_mailbox;

architecture sim of tb_mailbox is

  constant C_SCOPE        : string  := "TB_MAILBOX";
  constant C_ADDR_WIDTH   : natural := MAILBOX_ADDR_WIDTH;
  constant C_DATA_WIDTH   : natural := MAILBOX_DATA_WIDTH;

  constant C_CFG          : cfg_t   := (depth_tx       => (FIFO0_DEPTH_TX, FIFO1_DEPTH_TX)
                                       ,depth_rx       => (FIFO0_DEPTH_RX, FIFO1_DEPTH_RX)
                                       ,blocking_read  => BLOCKING_READ
                                       ,blocking_write => BLOCKING_WRITE
                                       );

  signal   clk_i          : std_logic := '0';
  signal   clk_ena        : boolean   := true;
  signal   arst_b_i       : std_logic := '0';
  signal   fifo_empty     : std_logic_vector(2-1 downto 0);
  signal   fifo_full      : std_logic_vector(2-1 downto 0);

  signal   sbi_ini        : sbi_ini_t(addr (C_ADDR_WIDTH-1 downto 0),
                                      wdata(C_DATA_WIDTH-1 downto 0));
  signal   sbi_tgt        : sbi_tgt_t(rdata(C_DATA_WIDTH-1 downto 0));

  signal   sbi_if         : t_sbi_if(addr (C_ADDR_WIDTH-1 downto 0),
                                     wdata(C_DATA_WIDTH-1 downto 0),
                                     rdata(C_DATA_WIDTH-1 downto 0));

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : sbi_mailbox
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
      sbi_tgt_o      => sbi_tgt,
      fifo_empty_o   => fifo_empty,
      fifo_full_o    => fifo_full
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "FIFO0 TX/RX = " & integer'image(FIFO0_DEPTH_TX) & "/" & integer'image(FIFO0_DEPTH_RX) &
                    ", FIFO1 TX/RX = " & integer'image(FIFO1_DEPTH_TX) & "/" & integer'image(FIFO1_DEPTH_RX) &
                    ", BLOCKING_READ = " & boolean'image(BLOCKING_READ) & ", BLOCKING_WRITE = " & boolean'image(BLOCKING_WRITE) &
                    ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, bus inactive : each scenario starts from reset
      sbi_if <= init_sbi_if_signals(C_ADDR_WIDTH, C_DATA_WIDTH);
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), C_CFG, clk_i, arst_b_i, sbi_if, fifo_empty, fifo_full);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
