-- Generated VHDL Package for mailbox

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.sbi_pkg.all;
--==================================
-- Module      : mailbox
-- Description : CSR for mailbox
-- Width       : 8
--==================================

package mailbox_csr_pkg is

  --==================================
  -- Register    : fifo0
  -- Description : FIFO0
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  type mailbox_fifo0_sw2hw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
    sw2hw_empty : std_logic;
    sw2hw_full  : std_logic;
    hw2sw_empty : std_logic;
    hw2sw_full  : std_logic;
  end record mailbox_fifo0_sw2hw_t;

  type mailbox_fifo0_hw2sw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record mailbox_fifo0_hw2sw_t;

  --==================================
  -- Register    : fifo1
  -- Description : FIFO1
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  type mailbox_fifo1_sw2hw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : FIFO1 : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
    sw2hw_empty : std_logic;
    sw2hw_full  : std_logic;
    hw2sw_empty : std_logic;
    hw2sw_full  : std_logic;
  end record mailbox_fifo1_sw2hw_t;

  type mailbox_fifo1_hw2sw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : FIFO1 : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record mailbox_fifo1_hw2sw_t;

  ------------------------------------
  -- Structure mailbox_t
  ------------------------------------
  type mailbox_sw2hw_t is record
    fifo0 : mailbox_fifo0_sw2hw_t;
    fifo1 : mailbox_fifo1_sw2hw_t;
  end record mailbox_sw2hw_t;

  type mailbox_hw2sw_t is record
    fifo0 : mailbox_fifo0_hw2sw_t;
    fifo1 : mailbox_fifo1_hw2sw_t;
  end record mailbox_hw2sw_t;


  constant mailbox_ADDR_WIDTH : natural := 2;
  constant mailbox_DATA_WIDTH : natural := 8;

  ------------------------------------
  -- Component
  ------------------------------------
component mailbox_registers is
  generic (
    MODULE_NAME :  string := "" -- Name of the module
   ;FIFO0_DEPTH_TX : natural -- FIFO0 Depth of FIFO TX (SW2HW)
   ;FIFO0_DEPTH_RX : natural -- FIFO0 Depth of FIFO RX (HW2SW)
   ;FIFO1_DEPTH_TX : natural -- FIFO1 Depth of FIFO TX (SW2HW)
   ;FIFO1_DEPTH_RX : natural -- FIFO1 Depth of FIFO RX (HW2SW)
  );
  port (
    -- Clock and Reset
    clk_i      : in  std_logic
   ;arst_b_i   : in  std_logic
    -- Bus
   ;sbi_ini_i  : in  sbi_ini_t
   ;sbi_tgt_o  : out sbi_tgt_t
    -- CSR
   ;sw2hw_o    : out mailbox_sw2hw_t
   ;hw2sw_i    : in  mailbox_hw2sw_t
  );
end component mailbox_registers;


end package mailbox_csr_pkg;
