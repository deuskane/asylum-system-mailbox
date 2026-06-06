-- Generated VHDL Module for mailbox


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.mailbox_csr_pkg.ALL;
library asylum;
use     asylum.csr_pkg.ALL;
library asylum;
use     asylum.sbi_pkg.all;

--==================================
-- Module      : mailbox
-- Description : CSR for mailbox
-- Width       : 8
--==================================
entity mailbox_registers is
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
end entity mailbox_registers;

architecture rtl of mailbox_registers is

  signal   sig_wcs   : std_logic;
  signal   sig_we    : std_logic;
  signal   sig_waddr : std_logic_vector(sbi_ini_i.addr'length-1 downto 0);
  signal   sig_wdata : std_logic_vector(sbi_ini_i.wdata'length-1 downto 0);
  signal   sig_wbusy : std_logic;

  signal   sig_rcs   : std_logic;
  signal   sig_re    : std_logic;
  signal   sig_raddr : std_logic_vector(sbi_ini_i.addr'length-1 downto 0);
  signal   sig_rdata : std_logic_vector(sbi_tgt_o.rdata'length-1 downto 0);
  signal   sig_rbusy : std_logic;

  signal   sig_busy  : std_logic;

  function INIT_fifo0
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_fifo0
    tmp(7 downto 0) := "00000000"; -- value
    return tmp;
  end function INIT_fifo0;

  signal   fifo0_wcs       : std_logic;
  signal   fifo0_we        : std_logic;
  signal   fifo0_wdata     : std_logic_vector(8-1 downto 0);
  signal   fifo0_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   fifo0_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   fifo0_wbusy     : std_logic;

  signal   fifo0_rcs       : std_logic;
  signal   fifo0_re        : std_logic;
  signal   fifo0_rdata     : std_logic_vector(8-1 downto 0);
  signal   fifo0_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   fifo0_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   fifo0_rbusy     : std_logic;

  function INIT_fifo1
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_fifo1
    tmp(7 downto 0) := "00000000"; -- value
    return tmp;
  end function INIT_fifo1;

  signal   fifo1_wcs       : std_logic;
  signal   fifo1_we        : std_logic;
  signal   fifo1_wdata     : std_logic_vector(8-1 downto 0);
  signal   fifo1_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   fifo1_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   fifo1_wbusy     : std_logic;

  signal   fifo1_rcs       : std_logic;
  signal   fifo1_re        : std_logic;
  signal   fifo1_rdata     : std_logic_vector(8-1 downto 0);
  signal   fifo1_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   fifo1_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   fifo1_rbusy     : std_logic;

begin  -- architecture rtl

  -- Interface 
  sig_wcs   <= sbi_ini_i.cs;
  sig_we    <= sbi_ini_i.we;
  sig_waddr <= sbi_ini_i.addr;
  sig_wdata <= sbi_ini_i.wdata;

  sig_rcs   <= sbi_ini_i.cs;
  sig_re    <= sbi_ini_i.re;
  sig_raddr <= sbi_ini_i.addr;
  sbi_tgt_o.rdata <= sig_rdata;
  sbi_tgt_o.ready <= not sig_busy;

  sig_busy  <= sig_wbusy when sig_we = '1' else
               sig_rbusy when sig_re = '1' else
               '0';

  gen_fifo0: if (True)
  generate
  --==================================
  -- Register    : fifo0
  -- Description : FIFO0
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================


    fifo0_rcs     <= '1' when     (sig_raddr(mailbox_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,mailbox_ADDR_WIDTH))) else '0';
    fifo0_re      <= sig_rcs and sig_re and fifo0_rcs;
    fifo0_rdata   <= (
      0 => fifo0_rdata_sw(0), -- value(0)
      1 => fifo0_rdata_sw(1), -- value(1)
      2 => fifo0_rdata_sw(2), -- value(2)
      3 => fifo0_rdata_sw(3), -- value(3)
      4 => fifo0_rdata_sw(4), -- value(4)
      5 => fifo0_rdata_sw(5), -- value(5)
      6 => fifo0_rdata_sw(6), -- value(6)
      7 => fifo0_rdata_sw(7), -- value(7)
      others => '0');

    fifo0_wcs     <= '1' when       (sig_waddr(mailbox_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,mailbox_ADDR_WIDTH)))   else '0';
    fifo0_we      <= sig_wcs and sig_we and fifo0_wcs;
    fifo0_wdata   <= sig_wdata;
    fifo0_wdata_sw(7 downto 0) <= fifo0_wdata(7 downto 0); -- value
    fifo0_wdata_hw(7 downto 0) <= hw2sw_i.fifo0.value; -- value
    sw2hw_o.fifo0.value <= fifo0_rdata_hw(7 downto 0); -- value

    ins_fifo0 : csr_fifo
      generic map
        (WIDTH         => 8
        ,BLOCKING_READ => True
        ,BLOCKING_WRITE => True
        ,DEPTH_SW2HW => FIFO0_DEPTH_TX
        ,DEPTH_HW2SW => FIFO0_DEPTH_RX
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => fifo0_wdata_sw
        ,sw_rd_o       => fifo0_rdata_sw
        ,sw_we_i       => fifo0_we
        ,sw_re_i       => fifo0_re
        ,sw_rbusy_o    => fifo0_rbusy
        ,sw_wbusy_o    => fifo0_wbusy
        ,hw_tx_valid_i        => hw2sw_i.fifo0.valid
        ,hw_tx_ready_o        => sw2hw_o.fifo0.ready
        ,hw_tx_data_i         => fifo0_wdata_hw
        ,hw_tx_empty_o        => sw2hw_o.fifo0.hw2sw_empty
        ,hw_tx_full_o         => sw2hw_o.fifo0.hw2sw_full
        ,hw_rx_valid_o        => sw2hw_o.fifo0.valid
        ,hw_rx_ready_i        => hw2sw_i.fifo0.ready
        ,hw_rx_data_o         => fifo0_rdata_hw
        ,hw_rx_empty_o        => sw2hw_o.fifo0.sw2hw_empty
        ,hw_rx_full_o         => sw2hw_o.fifo0.sw2hw_full
        );

  end generate gen_fifo0;

  gen_fifo0_b: if not (True)
  generate
    fifo0_rcs     <= '0';
    fifo0_rbusy   <= '0';
    fifo0_rdata   <= (others => '0');
    fifo0_wcs      <= '0';
    fifo0_wbusy    <= '0';
    sw2hw_o.fifo0.value <= "00000000";
    sw2hw_o.fifo0.ready <= '0';
    sw2hw_o.fifo0.valid <= '0';
  end generate gen_fifo0_b;

  gen_fifo1: if (True)
  generate
  --==================================
  -- Register    : fifo1
  -- Description : FIFO1
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  --==================================
  -- Field       : value
  -- Description : FIFO1 : Data TX or Data RX
  -- Width       : 8
  --==================================


    fifo1_rcs     <= '1' when     (sig_raddr(mailbox_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,mailbox_ADDR_WIDTH))) else '0';
    fifo1_re      <= sig_rcs and sig_re and fifo1_rcs;
    fifo1_rdata   <= (
      0 => fifo1_rdata_sw(0), -- value(0)
      1 => fifo1_rdata_sw(1), -- value(1)
      2 => fifo1_rdata_sw(2), -- value(2)
      3 => fifo1_rdata_sw(3), -- value(3)
      4 => fifo1_rdata_sw(4), -- value(4)
      5 => fifo1_rdata_sw(5), -- value(5)
      6 => fifo1_rdata_sw(6), -- value(6)
      7 => fifo1_rdata_sw(7), -- value(7)
      others => '0');

    fifo1_wcs     <= '1' when       (sig_waddr(mailbox_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,mailbox_ADDR_WIDTH)))   else '0';
    fifo1_we      <= sig_wcs and sig_we and fifo1_wcs;
    fifo1_wdata   <= sig_wdata;
    fifo1_wdata_sw(7 downto 0) <= fifo1_wdata(7 downto 0); -- value
    fifo1_wdata_hw(7 downto 0) <= hw2sw_i.fifo1.value; -- value
    sw2hw_o.fifo1.value <= fifo1_rdata_hw(7 downto 0); -- value

    ins_fifo1 : csr_fifo
      generic map
        (WIDTH         => 8
        ,BLOCKING_READ => True
        ,BLOCKING_WRITE => True
        ,DEPTH_SW2HW => FIFO1_DEPTH_TX
        ,DEPTH_HW2SW => FIFO1_DEPTH_RX
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => fifo1_wdata_sw
        ,sw_rd_o       => fifo1_rdata_sw
        ,sw_we_i       => fifo1_we
        ,sw_re_i       => fifo1_re
        ,sw_rbusy_o    => fifo1_rbusy
        ,sw_wbusy_o    => fifo1_wbusy
        ,hw_tx_valid_i        => hw2sw_i.fifo1.valid
        ,hw_tx_ready_o        => sw2hw_o.fifo1.ready
        ,hw_tx_data_i         => fifo1_wdata_hw
        ,hw_tx_empty_o        => sw2hw_o.fifo1.hw2sw_empty
        ,hw_tx_full_o         => sw2hw_o.fifo1.hw2sw_full
        ,hw_rx_valid_o        => sw2hw_o.fifo1.valid
        ,hw_rx_ready_i        => hw2sw_i.fifo1.ready
        ,hw_rx_data_o         => fifo1_rdata_hw
        ,hw_rx_empty_o        => sw2hw_o.fifo1.sw2hw_empty
        ,hw_rx_full_o         => sw2hw_o.fifo1.sw2hw_full
        );

  end generate gen_fifo1;

  gen_fifo1_b: if not (True)
  generate
    fifo1_rcs     <= '0';
    fifo1_rbusy   <= '0';
    fifo1_rdata   <= (others => '0');
    fifo1_wcs      <= '0';
    fifo1_wbusy    <= '0';
    sw2hw_o.fifo1.value <= "00000000";
    sw2hw_o.fifo1.ready <= '0';
    sw2hw_o.fifo1.valid <= '0';
  end generate gen_fifo1_b;

  sig_wbusy <= 
    fifo0_wbusy when fifo0_wcs = '1' else
    fifo1_wbusy when fifo1_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    fifo0_rbusy when fifo0_rcs = '1' else
    fifo1_rbusy when fifo1_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    fifo0_rdata when fifo0_rcs = '1' else
    fifo1_rdata when fifo1_rcs = '1' else
    (others => '0'); -- Bad Address, return 0

  gen_tgt_info_name : if MODULE_NAME = ""
  generate
    sbi_tgt_o.info.name <= to_sbi_name("mailbox");
  else generate
    sbi_tgt_o.info.name <= to_sbi_name(MODULE_NAME);
  end generate;
end architecture rtl;
