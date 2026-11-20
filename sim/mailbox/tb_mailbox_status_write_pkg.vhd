-------------------------------------------------------------------------------
-- Title      : tb_mailbox_status_write_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_status_write_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario status_write of tb_mailbox, from reset :
--              The status registers are read only : a write of status<n>,
--              empty or full channel, changes neither the register nor the
--              channel
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

package tb_mailbox_status_write_pkg is

  -- The status registers are read only : a write of status<n>, empty or full
  -- channel, changes neither the register nor the channel
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_status_write_pkg;

package body tb_mailbox_status_write_pkg is

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
      wr(C_STATUS(f), x"FF", "Write status" & integer'image(f) & " (empty channel)", clk, sbi_if);
      chk_status(cfg, ch, f, "unchanged after the write (empty)", clk, sbi_if, empty, full);
      chk_stall (cfg, C_FIFO(f), true, x"00", fifo(f) & " still empty after the status write", clk, sbi_if);
      for i in 1 to capacity(cfg, f) loop
        push(cfg, ch, f, fifo(f) & " write", clk, sbi_if);
      end loop;
      settle(clk);
      wr(C_STATUS(f), x"00", "Write status" & integer'image(f) & " (full channel)", clk, sbi_if);
      chk_status(cfg, ch, f, "unchanged after the write (full)", clk, sbi_if, empty, full);
      for i in 1 to capacity(cfg, f) loop
        pop(cfg, ch, f, fifo(f) & " read back after the status write", clk, sbi_if);
      end loop;
    end loop;
  end procedure;

end package body tb_mailbox_status_write_pkg;
