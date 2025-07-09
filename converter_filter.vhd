library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! Encapsulates all components required to generate filtered black and white images for two different colors.

--! Pixels in the output image are white if they belong to the respective color range.
--! The color ranges can be specified using minimum and maxuimum thresholds for the hue and saturation channel.
entity converter_filter is
    generic(
        IMAGE_WIDTH  : integer range 3 to 2047 := 640;    --! width of a the input image in pixels
        IMAGE_HEIGHT : integer range 3 to 2047 := 480;    --! height of a the input image in pixels
        ADDR_WIDTH   : positive := 11;  --! Address width for the filter_chain subcomponent
        DATA_WIDTH   : positive := 1;   --! Data width for the filter_chain subcomponent
        PIXEL_COUNT  : positive := 4    --! Pixel count for the filter_chain subcomponent
    );
    port (
        clk         : in std_logic;   --! Clock input
        rstn        : in std_logic;   --! Negated asynchronous reset
        data_rdy    : in std_logic;   --! Input bit indicating if the input data (#r, #g, #b) is ready to be processed
        r           : in std_logic_vector(7 downto 0); --! 8 bit red component of the input pixel
        g           : in std_logic_vector(7 downto 0); --! 8 bit green component of the input pixel
        b           : in std_logic_vector(7 downto 0); --! 8 bit blue component of the input pixel
        h_min1      : in std_logic_vector(8 downto 0); --! lower threshold for the hue component for the first color
        h_max1      : in std_logic_vector(8 downto 0); --! upper threshold for the hue component for the first color
        h_min2      : in std_logic_vector(8 downto 0); --! lower threshold for the hue component for the second color
        h_max2      : in std_logic_vector(8 downto 0); --! upper threshold for the hue component for the second color
        s_min1      : in std_logic_vector(7 downto 0); --! lower threshold for the saturation component for the first color
        s_max1      : in std_logic_vector(7 downto 0); --! upper threshold for the saturation component for the first color
        s_min2      : in std_logic_vector(7 downto 0); --! lower threshold for the saturation component for the second color
        s_max2      : in std_logic_vector(7 downto 0); --! upper threshold for the saturation component for the second color
        result_rdy  : out std_logic;  --! Indicates whether the outputs (#result_1 and #result_2) represent a valid pixel
        result_1    : out std_logic;  --! 1 bit black/white output pixel for the filter chain of the first color
        result_2    : out std_logic   --! 1 bit black/white output pixel for the filter chain of the second color
    );

end converter_filter;

architecture rtl of converter_filter is

    component rgb2hsv is
        port (

                 clk        : in  std_logic;
                 rstn       : in  std_logic;
                 data_rdy   : in  std_logic;
                 r          : in  std_logic_vector(7 downto 0);
                 g          : in  std_logic_vector(7 downto 0);
                 b          : in  std_logic_vector(7 downto 0);
                 result_rdy : out std_logic;
                 h          : out std_logic_vector(8 downto 0);
                 s          : out std_logic_vector(7 downto 0);
                 v          : out std_logic_vector(7 downto 0)
             );
    end component;

    component filter_chain is
        generic(
        IMAGE_WIDTH  : integer range 3 to 2047 := 640;
        IMAGE_HEIGHT : integer range 3 to 2047 := 480;
        ADDR_WIDTH   : positive := 11;
        DATA_WIDTH   : positive := 1;
        PIXEL_COUNT  : positive := 4
    );
    port (
             clk        : in std_logic;
             data_rdy   : in std_logic;
             rstn       : in std_logic;
             h          : in std_logic_vector(8 downto 0);
             s          : in std_logic_vector(7 downto 0);
             h_min      : in std_logic_vector(8 downto 0);
             h_max      : in std_logic_vector(8 downto 0);
             s_min      : in std_logic_vector(7 downto 0);
             s_max      : in std_logic_vector(7 downto 0);

             result_rdy  : out  std_logic;
             result      : out  std_logic
         );
    end component;


    signal r_h : std_logic_vector(8 downto 0);
    signal r_s : std_logic_vector(7 downto 0);
    signal r_v : std_logic_vector(7 downto 0);

    signal r_result_rdy_rgb2hsv : std_logic;
    signal r_result_rdy_fc1     : std_logic;
    signal r_result_rdy_fc2     : std_logic;
begin

    rgb2hsv_inst: rgb2hsv
    port map(
        clk          => clk,
        rstn         => rstn,
        data_rdy     => data_rdy,
        r            => r,
        g            => g,
        b            => b,
        h            => r_h,
        s            => r_s,
        v            => r_v,
        result_rdy   => r_result_rdy_rgb2hsv
    );

    filter_chain1 : filter_chain
    generic map(
        IMAGE_WIDTH  => IMAGE_WIDTH,
        IMAGE_HEIGHT => IMAGE_HEIGHT,
        ADDR_WIDTH   => ADDR_WIDTH,
        DATA_WIDTH   => DATA_WIDTH,
        PIXEL_COUNT  => PIXEL_COUNT
    )
    port map(
        clk          => clk,
        rstn         => rstn,
        data_rdy     => r_result_rdy_rgb2hsv,
        h            => r_h,
        s            => r_s,
        h_min        => h_min1,
        h_max        => h_max1,
        s_max        => s_max1,
        s_min        => s_min1,
        result_rdy   => r_result_rdy_fc1,
        result       => result_1
    );

    filter_chain2 : filter_chain
    generic map(
        IMAGE_WIDTH  => IMAGE_WIDTH,
        IMAGE_HEIGHT => IMAGE_HEIGHT,
        ADDR_WIDTH   => ADDR_WIDTH,
        DATA_WIDTH   => DATA_WIDTH,
        PIXEL_COUNT  => PIXEL_COUNT
    )
    port map(
        clk          => clk,
        rstn         => rstn,
        data_rdy     => r_result_rdy_rgb2hsv,
        h            => r_h,
        s            => r_s,
        h_min        => h_min2,
        h_max        => h_max2,
        s_max        => s_max2,
        s_min        => s_min2,
        result_rdy   => r_result_rdy_fc2,
        result       => result_2
    );

    result_rdy <= '0' when (rstn = '0') else r_result_rdy_fc1 and r_result_rdy_fc2;

end rtl;

