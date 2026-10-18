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

  ------------------------------------
  -- Global Constants
  ------------------------------------

  constant MAILBOX_ADDR_WIDTH : natural := 2;
  constant MAILBOX_DATA_WIDTH : natural := 8;

  --==================================
  -- Register    : fifo0
  -- Description : FIFO0
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  constant MAILBOX_FIFO0 : unsigned(MAILBOX_ADDR_WIDTH-1 downto 0) := to_unsigned(0, MAILBOX_ADDR_WIDTH);

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
  -- Register    : status0
  -- Description : FIFO0 status (read only, writes are ignored)
  -- Address     : 0x1
  -- Width       : 2
  -- Sw Access   : rw
  -- Hw Access   : wo
  -- Hw Type     : ext
  --==================================
  constant MAILBOX_STATUS0 : unsigned(MAILBOX_ADDR_WIDTH-1 downto 0) := to_unsigned(1, MAILBOX_ADDR_WIDTH);

  type mailbox_status0_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  end record mailbox_status0_sw2hw_t;

  type mailbox_status0_hw2sw_t is record
    we : std_logic;
  --==================================
  -- Field       : empty
  -- Description : 1: no data to read in fifo0, a read stalls (BLOCKING_READ) or returns a non valid data
  -- Width       : 1
  --==================================
    empty : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : full
  -- Description : 1: no free slot in fifo0, a write stalls (BLOCKING_WRITE) or is dropped
  -- Width       : 1
  --==================================
    full : std_logic_vector(1-1 downto 0);
  end record mailbox_status0_hw2sw_t;

  --==================================
  -- Register    : fifo1
  -- Description : FIFO1
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  constant MAILBOX_FIFO1 : unsigned(MAILBOX_ADDR_WIDTH-1 downto 0) := to_unsigned(2, MAILBOX_ADDR_WIDTH);

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

  --==================================
  -- Register    : status1
  -- Description : FIFO1 status (read only, writes are ignored)
  -- Address     : 0x3
  -- Width       : 2
  -- Sw Access   : rw
  -- Hw Access   : wo
  -- Hw Type     : ext
  --==================================
  constant MAILBOX_STATUS1 : unsigned(MAILBOX_ADDR_WIDTH-1 downto 0) := to_unsigned(3, MAILBOX_ADDR_WIDTH);

  type mailbox_status1_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  end record mailbox_status1_sw2hw_t;

  type mailbox_status1_hw2sw_t is record
    we : std_logic;
  --==================================
  -- Field       : empty
  -- Description : 1: no data to read in fifo1, a read stalls (BLOCKING_READ) or returns a non valid data
  -- Width       : 1
  --==================================
    empty : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : full
  -- Description : 1: no free slot in fifo1, a write stalls (BLOCKING_WRITE) or is dropped
  -- Width       : 1
  --==================================
    full : std_logic_vector(1-1 downto 0);
  end record mailbox_status1_hw2sw_t;

  ------------------------------------
  -- Structure mailbox_t
  ------------------------------------
  type mailbox_sw2hw_t is record
    fifo0 : mailbox_fifo0_sw2hw_t;
    status0 : mailbox_status0_sw2hw_t;
    fifo1 : mailbox_fifo1_sw2hw_t;
    status1 : mailbox_status1_sw2hw_t;
  end record mailbox_sw2hw_t;

  type mailbox_hw2sw_t is record
    fifo0 : mailbox_fifo0_hw2sw_t;
    status0 : mailbox_status0_hw2sw_t;
    fifo1 : mailbox_fifo1_hw2sw_t;
    status1 : mailbox_status1_hw2sw_t;
  end record mailbox_hw2sw_t;

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
   ;BLOCKING_READ : boolean -- True : a read of an empty channel waits for a data (sbi ready low), False : it completes at once (data not valid, nothing popped)
   ;BLOCKING_WRITE : boolean -- True : a write in a full channel waits for a free slot (sbi ready low), False : it completes at once (data dropped)
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
