-------------------------------------------------------------------------------
-- Title      : tb_mailbox_random_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_random_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario random of tb_mailbox, from reset :
--              Each channel : C_NB_RANDOM random writes and reads (a write
--              when the channel is empty, a read when it is full), drained,
--              then empty
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.math_real.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library work;
use     work.tb_mailbox_bfm_pkg.all;

package tb_mailbox_random_pkg is

  -- Each channel : C_NB_RANDOM random writes and reads (a write when the
  -- channel is empty, a read when it is full), drained, then empty
  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_random_pkg;

package body tb_mailbox_random_pkg is

  procedure run
    (constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    ) is
    constant C_NB_RANDOM : natural := 200; -- Random writes / reads per channel
    variable ch          : channel_t;
    variable seed1       : positive := 7;
    variable seed2       : positive;
    variable r           : real;
  begin
    seed2 := 1000 + cfg.depth_tx(0)*64 + cfg.depth_rx(0)*16 + cfg.depth_tx(1)*4 + cfg.depth_rx(1);
    for f in 0 to 1 loop
      ch := channel_init(f);
      for i in 1 to C_NB_RANDOM loop
        uniform(seed1, seed2, r);
        if (ch.count < capacity(cfg, f)) and ((ch.count = 0) or (r < 0.5))
        then
          push(cfg, ch, f, fifo(f) & " random write", clk, sbi_if);
        else
          pop (cfg, ch, f, fifo(f) & " random read", clk, sbi_if);
        end if;
      end loop;
      while ch.count > 0 loop
        pop(cfg, ch, f, fifo(f) & " final read", clk, sbi_if);
      end loop;
      settle(clk);
      chk_status(cfg, ch, f, "after the random sequence : empty", clk, sbi_if, empty, full);
      chk_stall (cfg, C_FIFO(f), true, x"00", fifo(f) & " read after the random sequence (empty)", clk, sbi_if);
    end loop;
  end procedure;

end package body tb_mailbox_random_pkg;
