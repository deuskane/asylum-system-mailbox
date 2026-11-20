-------------------------------------------------------------------------------
-- Title      : tb_mailbox_async_reset_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_async_reset_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario async_reset of tb_mailbox, from reset :
--              Asynchronous reset : both channels full, the reset empties them
--              without a clock edge (fifo_empty_o, fifo_full_o), then status
--              empty and reads of the empty channels
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library work;
use     work.tb_mailbox_bfm_pkg.all;

package tb_mailbox_async_reset_pkg is

  -- Asynchronous reset : both channels full, the reset empties them without a
  -- clock edge (fifo_empty_o, fifo_full_o), then status empty and reads of the
  -- empty channels
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic        -- arst_b_i
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_async_reset_pkg;

package body tb_mailbox_async_reset_pkg is

  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic        -- arst_b_i
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    ) is
    variable ch0 : channel_t := channel_init(0);
    variable ch1 : channel_t := channel_init(1);
  begin
    for i in 1 to capacity(cfg, 0) loop
      push(cfg, ch0, 0, "fifo0 write", clk, sbi_if);
    end loop;
    for i in 1 to capacity(cfg, 1) loop
      push(cfg, ch1, 1, "fifo1 write", clk, sbi_if);
    end loop;
    settle(clk);
    chk_status(cfg, ch0, 0, "full before the reset", clk, sbi_if, empty, full);
    chk_status(cfg, ch1, 1, "full before the reset", clk, sbi_if, empty, full);
    -- Reset in the middle of a low phase of the clock
    wait until falling_edge(clk);
    wait for C_CLK_PERIOD/4;
    arst_b <= '0';
    wait for 1 ns;
    for f in 0 to 1 loop
      chk_bit(empty(f), '1', "fifo_empty_o(" & integer'image(f) & ") : reset without clock edge");
      chk_bit(full (f), '0', "fifo_full_o("  & integer'image(f) & ") : reset without clock edge");
    end loop;
    wait until falling_edge(clk);
    arst_b <= '1';
    ch0 := channel_init(0);
    ch1 := channel_init(1);
    chk_status(cfg, ch0, 0, "empty after the reset", clk, sbi_if, empty, full);
    chk_status(cfg, ch1, 1, "empty after the reset", clk, sbi_if, empty, full);
    chk_stall (cfg, C_FIFO(0), true, x"00", "fifo0 empty after the reset", clk, sbi_if);
    chk_stall (cfg, C_FIFO(1), true, x"00", "fifo1 empty after the reset", clk, sbi_if);
    push(cfg, ch0, 0, "fifo0 write after the reset", clk, sbi_if);
    pop (cfg, ch0, 0, "fifo0 read after the reset", clk, sbi_if);
  end procedure;

end package body tb_mailbox_async_reset_pkg;
