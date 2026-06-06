-------------------------------------------------------------------------------
-- Title      : mailbox_pkg
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : mailbox_pkg.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2026-05-27
-- Last update: 2026-05-27
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-05-27  1.0      mrosiere Created
-------------------------------------------------------------------------------
library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.sbi_pkg.all;

package mailbox_pkg is
  
-- [COMPONENT_INSERT][BEGIN]
component sbi_mailbox is
  generic (
    NAME             : string  := ""
   ;FIFO0_DEPTH_TX   : natural -- FIFO0 Depth of FIFO TX (SW2HW)
   ;FIFO0_DEPTH_RX   : natural -- FIFO0 Depth of FIFO RX (HW2SW)
   ;FIFO1_DEPTH_TX   : natural -- FIFO1 Depth of FIFO TX (SW2HW)
   ;FIFO1_DEPTH_RX   : natural -- FIFO1 Depth of FIFO RX (HW2SW)
  );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in  sbi_ini_t;
    sbi_tgt_o        : out sbi_tgt_t
    );

end component sbi_mailbox;

-- [COMPONENT_INSERT][END]

end mailbox_pkg;
