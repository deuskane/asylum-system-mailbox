-------------------------------------------------------------------------------
-- Title      : tb_mailbox_tests_pkg
-- Project    : mailbox
-------------------------------------------------------------------------------
-- File       : tb_mailbox_tests_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_mailbox : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_mailbox_<name>_pkg)
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

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_mailbox_bfm_pkg.all;

package tb_mailbox_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "reset_values,fill,write_read,random,independent,status_write,async_reset";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic        -- arst_b_i
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    );

end package tb_mailbox_tests_pkg;

package body tb_mailbox_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;constant cfg      : in    cfg_t            -- Generics of the DUT
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic        -- arst_b_i
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   empty    : in    std_logic_vector -- fifo_empty_o
    ;signal   full     : in    std_logic_vector -- fifo_full_o
    ) is
  begin
    if    string_eq(name, "reset_values")
    then
      work.tb_mailbox_reset_values_pkg.run(cfg, clk, sbi_if, empty, full);
    elsif string_eq(name, "fill")
    then
      work.tb_mailbox_fill_pkg.run(cfg, clk, sbi_if, empty, full);
    elsif string_eq(name, "write_read")
    then
      work.tb_mailbox_write_read_pkg.run(cfg, clk, sbi_if);
    elsif string_eq(name, "random")
    then
      work.tb_mailbox_random_pkg.run(cfg, clk, sbi_if, empty, full);
    elsif string_eq(name, "independent")
    then
      work.tb_mailbox_independent_pkg.run(cfg, clk, sbi_if, empty, full);
    elsif string_eq(name, "status_write")
    then
      work.tb_mailbox_status_write_pkg.run(cfg, clk, sbi_if, empty, full);
    elsif string_eq(name, "async_reset")
    then
      work.tb_mailbox_async_reset_pkg.run(cfg, clk, arst_b, sbi_if, empty, full);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_mailbox_tests_pkg;
