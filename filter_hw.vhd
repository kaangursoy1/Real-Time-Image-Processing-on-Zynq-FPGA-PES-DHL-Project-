--! @mainpage
--! @ref filter_hw "filter_hw documentation".


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! Toplevel component for the image processing chain containing the converter filter and the feature extraction.

--! Inputs are the pixel data an the HSV color classification thresholds. To retrieve the results, the BRAM readout interfaces
--! of the region_detect subcomponents are forwarded to the toplevel.
--! @see region_detect
entity filter_hw is
    generic(
        IMAGE_WIDTH                             : integer range 3 to 2047 := 640;    --! width of a the input image in pixels
        IMAGE_HEIGHT                            : integer range 3 to 2047 := 480;    --! height of a the input image in pixels
        LINE_BUFFER_ADDR_WIDTH                  : positive := 11;    --! Bitwidth 3*IMAGE_WIDTH
        LINE_BUFFER_DATA_WIDTH                  : positive := 1;    --! Bitwidth LINE_BUFFER
        FILTER_MAJOR_PIXEL_COUNT                : positive := 4;  --! Pixel count for the converter_filter subcomponent
        REGION_DETECT_ROW_LENGTH_WIDTH          : positive := 10;    --! Bitwidth IMAGE_WIDTH
        REGION_DETECT_ROW_NUMBER_WIDTH          : positive := 9;    --! Bitwidth IMAGE_HEIGHT
        REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH   : positive :=11;    --! Bitwidth FEATURE_BRAM_ADDR. Determines the size of the feature BRAM
        REGION_DETECT_PIXEL_OFFSET              : integer range 0 to 10 :=2*2;--! 2*Numer of filter_major modules in the respective pipeline
        REGION_DETECT_LINE_OFFSET               : integer range 0 to 10 :=2*2;  --! 2*Numer of filter_major modules in the respective pipeline
        C_SLV_DWIDTH                            : integer              := 32
    );
    port (
        clk      : in std_logic;   --! Clock input
        en       : in std_logic;   --! Enabe the filter component
        rstn     : in std_logic;   --! Negated asynchronous reset

        data_rdy : in std_logic;   --! Input bit indicating if the input data (#r, #g, #b) is ready to be processed
        r        : in std_logic_vector(7 downto 0); --! 8 bit red component of the input pixel
        g        : in std_logic_vector(7 downto 0); --! 8 bit green component of the input pixel
        b        : in std_logic_vector(7 downto 0); --! 8 bit blue component of the input pixel
        h_min_1  : in std_logic_vector(8 downto 0); --! lower threshold for the hue component for the first color
        h_max_1  : in std_logic_vector(8 downto 0); --! upper threshold for the hue component for the first color
        h_min_2  : in std_logic_vector(8 downto 0); --! lower threshold for the hue component for the second color
        h_max_2  : in std_logic_vector(8 downto 0); --! upper threshold for the hue component for the second color
        s_min_1  : in std_logic_vector(7 downto 0); --! lower threshold for the saturation component for the first color
        s_max_1  : in std_logic_vector(7 downto 0); --! upper threshold for the saturation component for the first color
        s_min_2  : in std_logic_vector(7 downto 0); --! lower threshold for the saturation component for the second color
        s_max_2  : in std_logic_vector(7 downto 0); --! upper threshold for the saturation component for the second color

        feature_bram_readout_2      : in std_logic; --! readout input for the second region_detect subcomponent. @see region_detect.FEATURE_BRAM_READOUT
        feature_bram_raddr_2        : in std_logic_vector(REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH-1 downto 0);  --! BRAM address input for the second region_detect subcomponent. @see region_detect.FEATURE_BRAM_RADDR
        feature_bram_readout_1      : in std_logic; --! readout input for the first region_detect subcomponent. @see region_detect.FEATURE_BRAM_READOUT
        feature_bram_raddr_1        : in std_logic_vector(REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH-1 downto 0); --! BRAM address input for the first region_detect subcomponent. @see region_detect.FEATURE_BRAM_RADDR

        feature_bram_left_border_1  : out std_logic_vector(REGION_DETECT_ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_right_border_1 : out std_logic_vector(REGION_DETECT_ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_upper_border_1 : out std_logic_vector(REGION_DETECT_ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_lower_border_1 : out std_logic_vector(REGION_DETECT_ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_valid_1        : out std_logic;
        feature_bram_count_1        : out std_logic_vector(REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH-1 downto 0);

        feature_bram_left_border_2  : out std_logic_vector(REGION_DETECT_ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_right_border_2 : out std_logic_vector(REGION_DETECT_ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_upper_border_2 : out std_logic_vector(REGION_DETECT_ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_lower_border_2 : out std_logic_vector(REGION_DETECT_ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_valid_2        : out std_logic;
        feature_bram_count_2        : out std_logic_vector(REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH-1 downto 0);

        idle                        : out std_logic   --! Indicates whether the filter is IDLE (i.e. all image data has been processed completely)
    );

end filter_hw;



architecture rtl of filter_hw is

    component converter_filter is
        generic(
            IMAGE_WIDTH  : integer range 3 to 2047;
            IMAGE_HEIGHT : integer range 3 to 2047;
            ADDR_WIDTH   : positive;
            DATA_WIDTH   : positive;
            PIXEL_COUNT  : positive

        );
        port (
            clk         : in std_logic;
            rstn        : in std_logic;
            data_rdy    : in std_logic;
            r           : in std_logic_vector(7 downto 0);
            g           : in std_logic_vector(7 downto 0);
            b           : in std_logic_vector(7 downto 0);
            h_min1      : in std_logic_vector(8 downto 0);
            h_max1      : in std_logic_vector(8 downto 0);
            h_min2      : in std_logic_vector(8 downto 0);
            h_max2      : in std_logic_vector(8 downto 0);
            s_min1      : in std_logic_vector(7 downto 0);
            s_max1      : in std_logic_vector(7 downto 0);
            s_min2      : in std_logic_vector(7 downto 0);
            s_max2      : in std_logic_vector(7 downto 0);
            result_rdy  : out std_logic;
            result_1    : out std_logic;
            result_2    : out std_logic
        );
    end component;

    component region_detect is
        generic(
            ROW_LENGTH                  : positive;
            ROW_LENGTH_WIDTH            : positive;
            NUMBER_OF_ROWS              : positive;
            ROW_NUMBER_WIDTH            : positive;
            FEATURE_BRAM_ADDR_WIDTH     : positive;
            PIXEL_OFFSET                : integer range 0 to 10;    --offset in the first line because of filter_major
            LINE_OFFSET                 : integer range 0 to 10     --each filter_major absorbs 2 lines
        );
        port(
            clk                         : in std_logic;
            rstn                        : in std_logic;
            data_in                     : in std_logic;
            data_rdy                    : in std_logic;
            FEATURE_BRAM_READOUT        : in std_logic;
            FEATURE_BRAM_RADDR          : in std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0);
            FEATURE_BRAM_LEFT_BORDER    : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
            FEATURE_BRAM_RIGHT_BORDER   : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
            FEATURE_BRAM_UPPER_BORDER   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
            FEATURE_BRAM_LOWER_BORDER   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
            FEATURE_BRAM_VALID          : out std_logic;
            FEATURE_BRAM_COUNT          : out std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0);
            idle                        : out std_logic
        );
    end component;

    signal result_rdy_f_c           : std_logic;
    signal result_1                 : std_logic;
    signal result_2                 : std_logic;
    signal idle_1                   : std_logic;
    signal idle_2                   : std_logic;
    signal data_rdy_region_detect   : std_logic;

    constant FRAME_PIXEL            : positive := IMAGE_WIDTH * IMAGE_HEIGHT;
    signal filter_hw_pixel_ctr      : unsigned(19 downto 0);
    signal frame_done               : std_logic;

begin
    pixel_counter: process(clk,en,rstn,data_rdy)
    begin
        if rstn = '0' then
            filter_hw_pixel_ctr <= (others => '0');
            frame_done <= '1';
        elsif rising_edge(clk) and en = '1' and data_rdy = '1' then
            filter_hw_pixel_ctr <= filter_hw_pixel_ctr + 1;
            frame_done <= '0';
            if(filter_hw_pixel_ctr = FRAME_PIXEL - 1) then
                frame_done <= '1';
            end if;
        end if;
    end process;

    data_rdy_region_detect <= result_rdy_f_c;

    --frame_done gets LOW one tick after the first pixel was read and gets HIGH with the last pixel of the frame
    idle <= idle_1 and idle_2 and frame_done;--not data_rdy;


    converter_filter_module: converter_filter
    generic map(
        IMAGE_WIDTH  => IMAGE_WIDTH,
        IMAGE_HEIGHT => IMAGE_HEIGHT,
        ADDR_WIDTH   => LINE_BUFFER_ADDR_WIDTH,
        DATA_WIDTH   => LINE_BUFFER_DATA_WIDTH,
        PIXEL_COUNT  => FILTER_MAJOR_PIXEL_COUNT
    )
    port map(
        clk         => clk,
        rstn        => rstn,
        data_rdy    => data_rdy,
        r           => r,
        g           => g,
        b           => b,
        h_min1      => h_min_1,
        h_max1      => h_max_1,
        h_min2      => h_min_2,
        h_max2      => h_max_2,
        s_min1      => s_min_1,
        s_max1      => s_max_1,
        s_min2      => s_min_2,
        s_max2      => s_max_2,
        result_rdy  => result_rdy_f_c,
        result_1    => result_1,
        result_2    => result_2
    );

    region_detect_1: region_detect
    generic map(
        ROW_LENGTH              => IMAGE_WIDTH,
        ROW_LENGTH_WIDTH        => REGION_DETECT_ROW_LENGTH_WIDTH,
        NUMBER_OF_ROWS          => IMAGE_HEIGHT,
        ROW_NUMBER_WIDTH        => REGION_DETECT_ROW_NUMBER_WIDTH,
        FEATURE_BRAM_ADDR_WIDTH => REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH,
        PIXEL_OFFSET            => REGION_DETECT_PIXEL_OFFSET,
        LINE_OFFSET             => REGION_DETECT_LINE_OFFSET
    )
    port map(
        clk                         => clk,
        rstn                        => rstn,
        data_in                     => result_1,
        data_rdy                    => data_rdy_region_detect,
        feature_bram_readout        => feature_bram_readout_1,
        feature_bram_raddr          => feature_bram_raddr_1,
        feature_bram_left_border    => feature_bram_left_border_1,
        feature_bram_right_border   => feature_bram_right_border_1,
        feature_bram_upper_border   => feature_bram_upper_border_1,
        feature_bram_lower_border   => feature_bram_lower_border_1,
        feature_bram_valid          => feature_bram_valid_1,
        feature_bram_count          => feature_bram_count_1,
        idle                        => idle_1
    );

    region_detect_2: region_detect
    generic map(
        ROW_LENGTH              => IMAGE_WIDTH,
        ROW_LENGTH_WIDTH        => REGION_DETECT_ROW_LENGTH_WIDTH,
        NUMBER_OF_ROWS          => IMAGE_HEIGHT,
        ROW_NUMBER_WIDTH        => REGION_DETECT_ROW_NUMBER_WIDTH,
        FEATURE_BRAM_ADDR_WIDTH => REGION_DETECT_FEATURE_BRAM_ADDR_WIDTH,
        PIXEL_OFFSET            => REGION_DETECT_PIXEL_OFFSET,
        LINE_OFFSET             => REGION_DETECT_LINE_OFFSET
    )
    port map(
        clk                         => clk,
        rstn                        => rstn,
        data_in                     => result_2,
        data_rdy                    => data_rdy_region_detect,
        feature_bram_readout        => feature_bram_readout_2,
        feature_bram_raddr          => feature_bram_raddr_2,
        feature_bram_left_border    => feature_bram_left_border_2,
        feature_bram_right_border   => feature_bram_right_border_2,
        feature_bram_upper_border   => feature_bram_upper_border_2,
        feature_bram_lower_border   => feature_bram_lower_border_2,
        feature_bram_valid          => feature_bram_valid_2,
        feature_bram_count          => feature_bram_count_2,
        idle                        => idle_2
    );
end rtl;

