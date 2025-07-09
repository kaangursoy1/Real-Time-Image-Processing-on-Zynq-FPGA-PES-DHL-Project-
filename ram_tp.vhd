library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! Provides a BRAM with three ports.

--! There are one port for writing and two ports for reading. The BRAM is implemented using two dual ported BRAMs using ram_dp.
--! @see ram_dp
entity ram_tp is
    generic (
        ADDR_WIDTH     : positive  := 2;  --! Width of the BRAM addresses
        DATA_WIDTH     : positive  := 6;  --! Width of the data fields in the BRAM
        USE_OUTPUT_REG : std_logic := '0' --! Specifies if the output is buffered in a separate register
    );
    port (
        clk      : in std_logic;   --! Clock input
        w_addr   : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! Address for writing to the BRAM.
        w_data   : in std_logic_vector(DATA_WIDTH-1 downto 0); --! Data to write through the writing port.
        w_enable : in std_logic; --! write enable for BRAM writing port. If set to '1', the value on #w_data will be written to position #w_addr in the RAM.
        r_addr_1 : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! Address input for reading through port 1.
        r_data_1 : out std_logic_vector(DATA_WIDTH-1 downto 0);--! Outputs the data in the BRAM at #r_addr_1.
        r_addr_2 : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! Address input for reading through port 2.
        r_data_2 : out std_logic_vector(DATA_WIDTH-1 downto 0) --! Outputs the data in the BRAM at #r_addr_2.
    );
end ram_tp;

architecture rtl of ram_tp is

    component ram_dp is
    generic (
        ADDR_WIDTH : positive  := 2;
        DATA_WIDTH : positive  := 6;
        USE_OUTPUT_REG : std_logic  := '0');
    port(
        clk   : in std_logic;

        wena  : in std_logic;
        wenb  : in std_logic;
        addra : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        addrb : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        dina  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dinb  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        douta : out std_logic_vector(DATA_WIDTH-1 downto 0);
        doutb : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
    end component;

begin


    -- STUDENT CODE HERE


    -- STUDENT CODE until HERE

end rtl;

