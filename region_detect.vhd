library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! Implements a region detection algorithm which identifies rectangular regions in a black/white image.

--! The detected regions are stored in an internal BRAM which can be read out using the
--! #FEATURE_BRAM_READOUT and #FEATURE_BRAM_RADDR input ports.
entity region_detect is
   generic(
        ROW_LENGTH                  : positive := 640; --! Length of a row in the input image
        ROW_LENGTH_WIDTH            : positive := 10;  --! Bitwidth of #ROW_LENGTH
        NUMBER_OF_ROWS              : positive := 480; --! Number of rows in the input image
        ROW_NUMBER_WIDTH            : positive := 9;   --! Bitwidth of #NUMBER_OF_ROWS
        FEATURE_BRAM_ADDR_WIDTH     : positive := 11;  --! Address width for the BRAM holding the detected regions
        PIXEL_OFFSET                : integer range 0 to 10 := 2;    --! Offset in the first line of the image caused by filter_major
        LINE_OFFSET                 : integer range 0 to 10 := 2     --! Number of lines absorbed by filter_major
    );

   port(
        clk                         : in std_logic;   --! Clock input
        rstn                        : in std_logic;   --! Negated asynchronous reset
        data_in                     : in std_logic; --! 1 bit black or white input pixel
        data_rdy                    : in std_logic; --! Indicates if the input data (#data_in) is ready to be processed
        feature_bram_readout        : in std_logic;   --! Enables the feature BRAM readout. Should only be set to '1' if all image processing steps have been completed (#IDLE = '1').
        feature_bram_raddr          : in std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0);  --! Read addres for the feature BRAM
        feature_bram_left_border    : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);  --! Left border of the feature stored at the current BRAM address #FEATURE_BRAM_RADDR
        feature_bram_right_border   : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0); --! Right border of the feature stored at the current BRAM address #FEATURE_BRAM_RADDR
        feature_bram_upper_border   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0); --! Upper border of the feature stored at the current BRAM address #FEATURE_BRAM_RADDR
        feature_bram_lower_border   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);  --! Lower border of the feature stored at the current BRAM address #FEATURE_BRAM_RADDR
        feature_bram_valid          : out std_logic;  --! indicates if the feature at the current BRAM address #FEATURE_BRAM_RADDR is valid. Invalid features should be ignored.
        feature_bram_count          : out std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0); --! Outputs the total number of features in the BRAM. The value of #FEATURE_BRAM_RADDR should always be lower than this number.
        idle                        : out std_logic --! indicates whether the component is IDLE (i.e. all image data has been processed completely)
        );
end region_detect;




architecture structural of region_detect is

component label_selection is
   generic(
        ROW_LENGTH                  : positive := 640;
        ROW_LENGTH_WIDTH            : positive := 10;
        NUMBER_OF_ROWS              : positive := 480;
        ROW_NUMBER_WIDTH            : positive := 9;
        MAX_NUMBER_LABELS           : positive := 1023;
        FEATURE_BRAM_ADDR_WIDTH     : positive := 11;
        NUMBER_ROWS_BRAM            : positive := 3
        );
   port(
        clk                         : in std_logic;
        rstn                        : in std_logic;
        start_pos                   : in std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
        end_pos                     : in std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
        row_number                  : in std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
        new_run                     : in std_logic;
        eol                         : in std_logic;
        eof                         : in std_logic;
        idle                        : out std_logic;
        feature_bram_readout        : in std_logic;
        feature_bram_raddr          : in std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0);
        feature_bram_left_border    : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_right_border   : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
        feature_bram_upper_border   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_lower_border   : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
        feature_bram_valid          : out std_logic;
        feature_bram_count          : out std_logic_vector(FEATURE_BRAM_ADDR_WIDTH-1 downto 0)

    );
end component;

component rle is
   generic(
        ROW_LENGTH          : positive;
        ROW_LENGTH_WIDTH    : positive;
        NUMBER_OF_ROWS      : positive;
        ROW_NUMBER_WIDTH    : positive;

        -- Depending on filter_chain implementation following parameters may be useful here
        PIXEL_OFFSET    : integer range 0 to 10;    --offset in the first line because of noise filter
        LINE_OFFSET     : integer range 0 to 10 --offset in the last line because of noise filter
    );
   port(
        clk        : in std_logic;
        rstn       : in std_logic;
        data_in    : in std_logic;                                     -- Input pixels black/white
        data_rdy   : in std_logic;
        start_pos  : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0); -- Start position of run
        end_pos    : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0); -- End position of run
        row_number : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
        new_run    : out std_logic;                                     -- Indicates that a new run has been identified (= above output signals are valid)
        eol        : out std_logic;                                     -- end of current line
        eof        : out std_logic                                      -- end of file
    );
end component;


signal start_pos, end_pos : std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);
signal row_number         : std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);
signal new_run, eol, eof  : std_logic;


constant MAX_NUMBER_LABELS : positive := 2**FEATURE_BRAM_ADDR_WIDTH-1;



begin


    LABEL_SELECTION_MODULE : label_selection
    generic map (
        ROW_LENGTH              => ROW_LENGTH,
        ROW_LENGTH_WIDTH        => ROW_LENGTH_WIDTH,
        NUMBER_OF_ROWS          => NUMBER_OF_ROWS,
        ROW_NUMBER_WIDTH        => ROW_NUMBER_WIDTH,
        MAX_NUMBER_LABELS       => MAX_NUMBER_LABELS,
        FEATURE_BRAM_ADDR_WIDTH => FEATURE_BRAM_ADDR_WIDTH
    )
    port map (
        clk                         => clk,
        rstn                        => rstn,
        start_pos                   => start_pos,
        end_pos                     => end_pos,
        row_number                  => row_number,
        new_run                     => new_run,
        idle                        => idle,
        eol                         => eol,
        eof                         => eof,
        feature_bram_readout        => feature_bram_readout,
        feature_bram_raddr          => feature_bram_raddr,
        feature_bram_left_border    => feature_bram_left_border,
        feature_bram_right_border   => feature_bram_right_border,
        feature_bram_upper_border   => feature_bram_upper_border,
        feature_bram_lower_border   => feature_bram_lower_border,
        feature_bram_valid          => feature_bram_valid,
        feature_bram_count          => feature_bram_count
    );


   run_length_encoder: rle
   generic map(
        ROW_LENGTH          => ROW_LENGTH,
        ROW_LENGTH_WIDTH    => ROW_LENGTH_WIDTH,
        NUMBER_OF_ROWS      => NUMBER_OF_ROWS,
        ROW_NUMBER_WIDTH    => ROW_NUMBER_WIDTH,
        PIXEL_OFFSET        => PIXEL_OFFSET,
        LINE_OFFSET         => LINE_OFFSET
    )
   port map(
        clk         => clk,
        rstn        => rstn,
        data_in     => data_in,
        data_rdy    => data_rdy,
        start_pos   => start_pos,
        end_pos     => end_pos,
        row_number  => row_number,
        new_run     => new_run,
        eol         => eol,
        eof         => eof
    );

end structural;
