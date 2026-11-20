-------------------------------------------------------------------------------
-- Title      : tb_mailbox_independent_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_independent_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario independent of tb_mailbox, from reset :
--              The channels are independent : fifo0 full while fifo1 is empty
--              (status and outputs of both), fifo1 used while fifo0 is full,
--              then fifo0 read back unchanged
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

package tb_mailbox_independent_pkg is

  -- The channels are independent : fifo0 full while fifo1 is empty (status and
  -- outputs of both), fifo1 used while fifo0 is full, then fifo0 read back
  -- unchanged
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_independent_pkg;

package body tb_mailbox_independent_pkg is

  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
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
    settle(clk);
    chk_status(cfg, ch0, 0, "fifo0 full", clk, sbi_if, empty, full);
    chk_status(cfg, ch1, 1, "fifo1 empty while fifo0 is full", clk, sbi_if, empty, full);
    chk_stall (cfg, C_FIFO(1), true, x"00", "fifo1 read while fifo0 is full (fifo1 empty)", clk, sbi_if);
    push(cfg, ch1, 1, "fifo1 write while fifo0 is full", clk, sbi_if);
    settle(clk);
    chk_status(cfg, ch1, 1, "one byte in fifo1", clk, sbi_if, empty, full);
    chk_status(cfg, ch0, 0, "fifo0 still full", clk, sbi_if, empty, full);
    pop(cfg, ch1, 1, "fifo1 read while fifo0 is full", clk, sbi_if);
    for i in 1 to capacity(cfg, 0) loop
      pop(cfg, ch0, 0, "fifo0 read : content not modified by the fifo1 accesses", clk, sbi_if);
    end loop;
    settle(clk);
    chk_status(cfg, ch0, 0, "drained", clk, sbi_if, empty, full);
    chk_status(cfg, ch1, 1, "drained", clk, sbi_if, empty, full);
  end procedure;

end package body tb_mailbox_independent_pkg;
