library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! This copmonent implements a run-length encoder for 1 bit black/white images.

--! The resulting runs are parametrized using the start position (#start_pos), end position (#end_pos) and
--! the corresponding row number (#row_number).
entity rle is
    generic(
        ROW_LENGTH          : positive := 640;   --! Length of a row in the input image
        ROW_LENGTH_WIDTH    : positive := 10;  --! Bitwidth of #ROW_LENGTH
        NUMBER_OF_ROWS      : positive := 480; --! Number of rows in the input image
        ROW_NUMBER_WIDTH    : positive := 9;   --! Bitwidth of #NUMBER_OF_ROWS
        PIXEL_OFFSET        : integer range 0 to 10 := 2;    --! Offset in the first line caused by filter_major
        LINE_OFFSET         : integer range 0 to 10 := 2     --! Number of lines absorbed by filter_major
        );
    port(
        clk         : in std_logic;   --! Clock input
        rstn        : in std_logic;   --! Negated asynchronous reset
        data_in     : in std_logic; --! 1 bit black or white input pixel
        data_rdy    : in std_logic; --! Indicates if the input data (#data_in) is ready to be processed
        start_pos   : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);  --! The starting position of the detected run. Only valid if #new_run is '1'.
        end_pos     : out std_logic_vector(ROW_LENGTH_WIDTH-1 downto 0);  --! The end position of the detected run. Only valid if #new_run is '1'.
        row_number  : out std_logic_vector(ROW_NUMBER_WIDTH-1 downto 0);--! The row number of the detected run. Only valid if #new_run is '1'.
        new_run     : out std_logic;    --! Indicates if a new run has been detected. The run parameters are only valid if #new_run is '1'.
        eol         : out std_logic;  --! Indicates if the run-length encoder has reached the end of a row in the image.
        eof         : out std_logic   --! Indicates if the run-length encoder has reached the end of the data stream (i.e. the image has been processed completely).
        );
end rle;

architecture behavioral of rle is

    -- STUDENT CODE HERE
    type state_t is (IDLE, RUN);
    signal state : state_t;
    
    signal col_cnt : unsigned(ROW_LENGTH_WIDTH-1 downto 0);
    signal row_cnt : unsigned(ROW_NUMBER_WIDTH-1 downto 0);

    signal start_pos_reg : unsigned(ROW_LENGTH_WIDTH-1 downto 0);
    signal end_pos_reg   : unsigned(ROW_LENGTH_WIDTH-1 downto 0);

    signal row_num_reg   : unsigned(ROW_LENGTH_WIDTH-1 downto 0);

    signal last_fg_col   : unsigned(ROW_LENGTH_WIDTH-1 downto 0);

    signal new_run_int : std_logic;
    signal eol_int     : std_logic;
    signal eof_int     : std_logic;



    --the first valid row has already been processed
    signal first_row_done : std_logic;
    --last valid row number after cropping 
    constant LAST_ROW_C : unsigned(ROW_NUMBER_WIDTH-1 downto 0) := to_unsigned(NUMBER_OF_ROWS - LINE_OFFSET - 1, ROW_NUMBER_WIDTH);

    --compute the last column index for the current row
    function row_end_value(f_row :unsigned) return unsigned is
    begin
	 if f_row = LAST_ROW_C then
	    return to_unsigned(ROW_LENGTH - PIXEL_OFFSET - 1, ROW_LENGTH_WIDTH);
	 else
	    return to_unsigned(ROW_LENGTH - 1, ROW_LENGTH_WIDTH);
	 end if;
    end function;

    signal cur_row_end : unsigned(ROW_LENGTH_WIDTH-1 downto 0);

    -- STUDENT CODE until HERE

begin

    -- STUDENT CODE HERE
    -- combinational helper
    cur_row_end <= row_end_value(row_cnt);


    ---------------------------------------------------------------------------
    --  Main sequential process: state machine, counters, flag generation
    ---------------------------------------------------------------------------



    process(clk, rstn)
    begin
        if rstn = '0' then
            -- async reset: initialise counters and flags
            state           <= IDLE;
            col_cnt         <= to_unsigned(PIXEL_OFFSET, ROW_LENGTH_WIDTH);
            row_cnt         <= to_unsigned(LINE_OFFSET, ROW_NUMBER_WIDTH);
            row_num_reg     <= to_unsigned(LINE_OFFSET, ROW_NUMBER_WIDTH);
            last_fg_col     <= to_unsigned(PIXEL_OFFSET, ROW_LENGTH_WIDTH);
            first_row_done  <= '0';

            start_pos_reg   <= (others => '0');
            end_pos_reg     <= (others => '0');

            new_run_int <= '0';
            eol_int     <= '0';
            eof_int     <= '0';

        elsif rising_edge(clk) then
            -- clear pulses (single‑cycle)
            new_run_int <= '0';
            eol_int     <= '0';
            eof_int     <= '0';

            -- ================= PIXEL VALID PATH =================
            if data_rdy = '1' then
                -- remember last foreground pixel column (for safe end_pos)
                if data_in = '1' then
                    last_fg_col <= col_cnt;
                end if;

                -- ------------- FSM for Run detection -------------
                case state is
                    when IDLE =>
                        new_run_int <= '0';
                        if data_in = '1' then -- start of a run
                            start_pos_reg <= col_cnt;
                          if col_cnt = cur_row_end then
                             end_pos_reg <= col_cnt;
                             new_run_int <= '1';
                          end if;
                           state         <= RUN;
                            
                        end if;

                    when RUN =>
                        if data_in = '0' then -- run ends by 0
                            end_pos_reg <= last_fg_col;
                            row_num_reg <= row_cnt;
                            new_run_int <= '1';
                            state       <= IDLE;
                        elsif col_cnt = cur_row_end then -- ends at last pixel
                            end_pos_reg <= col_cnt;
                            row_num_reg <= row_cnt;
                            new_run_int <= '1';
                            
                           --eol_int     <= '1';            
                           --if row_cnt = LAST_ROW_C then
                              --eof_int <= '1';            
                           --end if
                            state       <= IDLE;
                        end if;
                        
                        if col_cnt = 0 then
                            new_run_int <= '0';
                        end if;
                            
                end case;
            end if; -- data_rdy

            -- ================= LINE SYNC (independent of data_rdy) =================
            if col_cnt = cur_row_end then -- this cycle processes last column of row
                eol_int <= '1';
                if row_cnt = LAST_ROW_C then
                    eof_int <= '1';
                end if;

                -- prepare counters for next row (if any)
                if row_cnt /= LAST_ROW_C then
                    row_cnt <= row_cnt + 1;
                end if;
                col_cnt <= (others => '0');
                if first_row_done = '0' then
                    first_row_done <= '1';
                end if;

            elsif data_rdy = '1' then
                -- normal pixel advance
                col_cnt <= col_cnt + 1;
            end if;
        end if; -- clk
    end process;


          -- output mapping
    start_pos  <= std_logic_vector(start_pos_reg);
    end_pos    <= std_logic_vector(end_pos_reg);
    row_number <= std_logic_vector(row_num_reg);
    new_run    <= new_run_int;
    eol        <= eol_int;
    eof        <= eof_int;

    -- STUDENT CODE until HERE


end behavioral;
