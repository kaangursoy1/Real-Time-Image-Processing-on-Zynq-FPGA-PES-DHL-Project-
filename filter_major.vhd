library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! This component implements noise filtering for a 1 bit black/white image.

--! Two image lines are buffered internally in order to have the values of all
--! pixels in an 3x3 pixel matrix available for filtering.
entity filter_major is
    generic (
        IMAGE_WIDTH  : integer range 3 to 2047 := 640; --! width of a the input image in pixels
        IMAGE_HEIGHT : integer range 3 to 2047 := 480; --! height of a the input image in pixels
        ADDR_WIDTH   : positive := 11;   --! Address width for the line_buffer subcomponent
        DATA_WIDTH   : positive := 1;    --! Data width for the line_buffer subcomponent
        PIXEL_COUNT  : positive := 4     --! Threashold for the number of pixels with value '1' in the 3x3 pixel matrix of the noise filter.
    );
  Port (
        clk         : in  std_logic;    --! Clock input
        rstn        : in  std_logic;    --! Negated asynchronous reset
        data_in     : in  std_logic;  --! 1 bit black or white input pixel
        data_rdy    : in  std_logic;  --! Input bit indicating if the input data (#data_in) is ready to be processed
        result      : out std_logic;  --! Output pixel
        result_rdy  : out std_logic --! Indicates whether the output (#result) represents a valid pixel
    );
end filter_major;

--! rtl implementation of filter_major
architecture rtl of filter_major is

    component line_buffer is
    Generic (
        LINE_LENGTH : positive;
        ADDR_WIDTH  : positive;
        DATA_WIDTH  : positive
    );
    Port (
        clk             : in std_logic;
        rstn            : in std_logic;
        data_in         : in std_logic;
        data_rdy        : in std_logic;
        result          : out std_logic;
        result_rdy      : out std_logic
    );
    end component;

    -- STUDENT CODE HERE
    --function used to calculate the sum of every column in the 3 x 3 Matirx 
    function adder(a : std_logic; b : std_logic; c : std_logic) return integer is variable result : integer := 0; 
    begin if(a='1')then 
            result:=result+1; 
          end if; 
          if(b='1')then 
            result:=result+1; 
          end if; 
          if(c='1')then 
            result:=result+1; 
            end if; 
          return result; 
    end function adder;
    
    
    type int_arr2 is array (0 to 1) of integer;
    signal store_reg : int_arr2 := ( others => 0);
    signal iterator : integer range 0 to 2 :=0;
    signal result1, result2, result_rdy1, result_rdy2, r1_delayed, delay, din_delayed : std_logic := '0';
    
    


    -- STUDENT CODE until HERE
begin

    -- STUDENT CODE HERE
    
lb0 : line_buffer
  generic map (
    LINE_LENGTH => IMAGE_WIDTH,
    ADDR_WIDTH  => ADDR_WIDTH,
    DATA_WIDTH  => DATA_WIDTH)
  port map (
    clk      => clk,
    rstn     => rstn,
    data_in  => data_in,
    data_rdy => data_rdy,
    result   => result1,
    result_rdy => result_rdy1);

-- \u7b2c 2 \u4e2a line_buffer\uff1a\u5728 result1 \u57fa\u7840\u4e0a\u518d\u5ef6\u8fdf\u4e00\u884c
lb1 : line_buffer
  generic map (
    LINE_LENGTH => IMAGE_WIDTH,
    ADDR_WIDTH  => ADDR_WIDTH,
    DATA_WIDTH  => DATA_WIDTH)
  port map (
    clk      => clk,
    rstn     => rstn,
    data_in  => result1,
    data_rdy => result_rdy1,
    result   => result2,
    result_rdy => result_rdy2);
    
    
    
    
process(clk,rstn)
variable store:integer:=0;
variable sum:integer:=0;
begin
if(rstn='0') then
store_reg<=(others=>0);
sum:=0;
iterator<=0;
elsif rising_edge(clk) then
result_rdy<='0';
r1_delayed<=result1; --delay one clock cycle of result1
delay<=data_in;
din_delayed<=delay; --delay two clock cycles of data_in
if(result_rdy2='1')then --control the output of filter_major
--get sum of every column in 3x3 matrix
store:=adder(din_delayed, r1_delayed, result2);
store_reg(1)<=store;
store_reg(0)<=store_reg(1);
if iterator<2 then --control the output of the first block
iterator<=iterator+1;
else
sum:=store_reg(0)+store_reg(1)+store;
if sum>=PIXEL_COUNT then
result<='1';
else
result<='0';
end if;
result_rdy<='1';
end if;
end if;
end if;
end process;


    -- STUDENT CODE until HERE

end rtl;