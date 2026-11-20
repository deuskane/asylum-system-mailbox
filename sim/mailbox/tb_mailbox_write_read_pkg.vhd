-------------------------------------------------------------------------------
-- Title      : tb_mailbox_write_read_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_write_read_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario write_read of tb_mailbox, from reset :
--              Each channel : a byte read just after its write, 4 times (the
--              blocking read waits until the byte reaches the RX FIFO, the non
--              blocking read polls the status first)
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

package tb_mailbox_write_read_pkg is

  -- Each channel : a byte read just after its write, 4 times (the blocking
  -- read waits until the byte reaches the RX FIFO, the non blocking read polls
  -- the status first)
  procedure run
    (constant cfg      : in    cfg_t     -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

end package tb_mailbox_write_read_pkg;

package body tb_mailbox_write_read_pkg is

  procedure run
    (constant cfg      : in    cfg_t     -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable ch : channel_t;
  begin
    for f in 0 to 1 loop
      ch := channel_init(f);
      for i in 1 to 4 loop
        push(cfg, ch, f, fifo(f) & " write", clk, sbi_if);
        pop (cfg, ch, f, fifo(f) & " read just after the write", clk, sbi_if);
      end loop;
    end loop;
  end procedure;

end package body tb_mailbox_write_read_pkg;
