-------------------------------------------------------------------------------
-- Title      : tb_mailbox_reset_values_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_reset_values_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset_values of tb_mailbox, from reset :
--              After reset each channel is empty : status<n> = empty,
--              fifo_empty_o = 1, fifo_full_o = 0 ; a read of the empty channel
--              stalls (blocking) or completes at once (non blocking) and
--              changes nothing
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

package tb_mailbox_reset_values_pkg is

  -- After reset each channel is empty : status<n> = empty, fifo_empty_o = 1,
  -- fifo_full_o = 0 ; a read of the empty channel stalls (blocking) or
  -- completes at once (non blocking) and changes nothing
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_reset_values_pkg;

package body tb_mailbox_reset_values_pkg is

  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    ) is
    variable ch : channel_t;
  begin
    for f in 0 to 1 loop
      ch := channel_init(f);
      chk_status(cfg, ch, f, "after reset : empty", clk, sbi_if, empty, full);
      chk_stall (cfg, C_FIFO(f), true, x"00", fifo(f) & " read after reset (empty)", clk, sbi_if);
      settle(clk);
      chk_status(cfg, ch, f, "still empty after the read", clk, sbi_if, empty, full);
    end loop;
  end procedure;

end package body tb_mailbox_reset_values_pkg;
