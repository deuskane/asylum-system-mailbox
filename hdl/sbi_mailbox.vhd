-------------------------------------------------------------------------------
-- Title      : sbi_mailbox
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : sbi_mailbox.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2026-05-27
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-04  0.1      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_Logic_1164.ALL;
use     IEEE.numeric_std.ALL;
use     ieee.std_logic_textio.all;
use     std.textio.all;

library asylum;
use     asylum.logic_pkg.all;
use     asylum.sbi_pkg.all;
use     asylum.mailbox_pkg.all;
use     asylum.mailbox_csr_pkg.all;
use     asylum.techmap_pkg.all;

entity sbi_mailbox is
  generic (
    FIFO0_DEPTH_TX : natural -- FIFO0 Depth of FIFO TX (SW2HW)
   ;FIFO0_DEPTH_RX : natural -- FIFO0 Depth of FIFO RX (HW2SW)
   ;FIFO1_DEPTH_TX : natural -- FIFO1 Depth of FIFO TX (SW2HW)
   ;FIFO1_DEPTH_RX : natural -- FIFO1 Depth of FIFO RX (HW2SW)
  );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in  sbi_ini_t;
    sbi_tgt_o        : out sbi_tgt_t
    );

end entity sbi_mailbox;

architecture rtl of sbi_mailbox is

  signal   sw2hw                  : mailbox_sw2hw_t;
  signal   hw2sw                  : mailbox_hw2sw_t;

begin  -- architecture rtl

  ins_csr : mailbox_registers
  generic map(
    FIFO0_DEPTH_TX => FIFO0_DEPTH_TX
   ,FIFO0_DEPTH_RX => FIFO0_DEPTH_RX
   ,FIFO1_DEPTH_TX => FIFO1_DEPTH_TX
   ,FIFO1_DEPTH_RX => FIFO1_DEPTH_RX
    )
  port map(
    clk_i     => clk_i    
   ,arst_b_i  => arst_b_i 
   ,sbi_ini_i => sbi_ini_i
   ,sbi_tgt_o => sbi_tgt_o
   ,sw2hw_o   => sw2hw    
   ,hw2sw_i   => hw2sw   
    );
  
end architecture rtl;
