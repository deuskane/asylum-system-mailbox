-------------------------------------------------------------------------------
-- Title      : tb_mailbox_fill_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_fill_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario fill of tb_mailbox, from reset :
--              Each channel : fill it (DEPTH_TX + DEPTH_RX bytes) with the
--              status after each write, a write in the full channel stalls
--              (blocking) or is dropped (non blocking), read back in order,
--              status read right after the last read (read wait state of the
--              status register), read of the drained channel
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

package tb_mailbox_fill_pkg is

  -- Each channel : fill it (DEPTH_TX + DEPTH_RX bytes) with the status after
  -- each write, a write in the full channel stalls (blocking) or is dropped
  -- (non blocking), read back in order, status read right after the last read
  -- (read wait state of the status register), read of the drained channel
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_fill_pkg;

package body tb_mailbox_fill_pkg is

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
      for i in 1 to capacity(cfg, f) loop
        push(cfg, ch, f, fifo(f) & " write " & integer'image(i), clk, sbi_if);
        settle(clk);
        chk_status(cfg, ch, f, "after write " & integer'image(i), clk, sbi_if, empty, full);
      end loop;
      chk_stall (cfg, C_FIFO(f), false, x"EE", fifo(f) & " write in the full channel", clk, sbi_if);
      settle(clk);
      chk_status(cfg, ch, f, "still full after the write (aborted or dropped)", clk, sbi_if, empty, full);
      for i in 1 to capacity(cfg, f) loop
        pop(cfg, ch, f, fifo(f) & " read " & integer'image(i), clk, sbi_if);
      end loop;
      -- No idle cycle : the read wait state of the status register returns
      -- the flags updated by the last read
      chk_status(cfg, ch, f, "right after the last read : empty", clk, sbi_if, empty, full);
      settle(clk);
      chk_status(cfg, ch, f, "after draining : empty", clk, sbi_if, empty, full);
      chk_stall (cfg, C_FIFO(f), true, x"00", fifo(f) & " read after draining (empty)", clk, sbi_if);
    end loop;
  end procedure;

end package body tb_mailbox_fill_pkg;
