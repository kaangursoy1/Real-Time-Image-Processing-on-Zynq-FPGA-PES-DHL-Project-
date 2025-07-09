library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

entity rgb2hsv is
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
end entity rgb2hsv;

architecture rtl of rgb2hsv is

    -- Returns the maximum value of three parameters
    function max3(a : unsigned; b : unsigned; c : unsigned) return unsigned is
        variable result : unsigned(7 downto 0) := (others => '0');
    begin
        if a > b then
            result := a;
        else
            result := b;
        end if;
        if c > result then
            result := c;
        end if;
        return result;
    end function max3;

    -- Returns the minimum value of three parameters
    function min3(a : unsigned; b : unsigned; c : unsigned) return unsigned is
        variable result : unsigned(7 downto 0) := (others => '1');
    begin
        if a > b then
            result := b;
        else
            result := a;
        end if;
        if c < result then
            result := c;
        end if;
        return result;
    end function min3;

    -- Your original type definitions:
    type u8_array_t is array(natural range <>) of unsigned(7 downto 0);
    type u16_array_t is array(natural range <>) of signed(15 downto 0);

    component div16_8_8 is
        port (
            clk    : in  std_logic;
            en     : in  std_logic;
            rstn   : in  std_logic;
            a      : in  std_logic_vector(16 downto 0);
            b      : in  std_logic_vector(7 downto 0);
            result : out std_logic_vector(8 downto 0)
        );
    end component;

    -- STUDENT CODE HERE 

    signal s_div_q : std_logic_vector(8 downto 0) := (others=>'0');
    signal h_div_q : std_logic_vector(8 downto 0) := (others=>'0');

    signal h_out_reg : std_logic_vector(8 downto 0) := (others=>'0');
    signal s_out_reg : unsigned(7 downto 0) := (others=>'0');
    signal v_out_reg : unsigned(7 downto 0) := (others=>'0');
    
    signal s_num_reg : unsigned(16 downto 0) := (others=>'0');
    signal s_den_reg : unsigned(7 downto 0) := (others=>'0');
    signal h_num_reg : signed(16 downto 0) := (others=>'0');
    signal h_den_reg : unsigned(7 downto 0) := (others=>'0');
    signal channel_reg : std_logic_vector(1 downto 0) := (others=>'0');
    
    signal div_en : std_logic := '0';
    signal result_final: std_logic := '0';
    --pipeline alignment
    signal max_pipe:u8_array_t(0 to 10) :=(others =>(others=>'0'));
    signal diff_pipe:u8_array_t(0 to 10) :=(others =>(others=>'0'));
    signal data_rdy_pipe:std_logic_vector(0 to 10) :=(others =>'0');
    type channel_array_t is array(natural range <>) of std_logic_vector(1 downto 0);
signal channel_pipe_arr : channel_array_t(0 to 10) := (others=>(others=>'0'));



    -- STUDENT CODE until HERE

begin

    -- STUDENT CODE HERE
    
      -- Divider instantiation
    sat_div_inst: div16_8_8
        port map (
            clk => clk,
            en => div_en,
            rstn => rstn,
            a => std_logic_vector(s_num_reg),
            b => std_logic_vector(s_den_reg),
            result => s_div_q
        );
    hue_div_inst: div16_8_8
        port map (
            clk => clk,
            en => div_en,
            rstn => rstn,
            a => std_logic_vector(h_num_reg),
            b => std_logic_vector(h_den_reg),
            result => h_div_q
        );
    
    process(clk,rstn)
        variable g_b, b_r, r_g : signed(8 downto 0):=(others=>'0');
        variable ch : std_logic_vector(1 downto 0);
        variable max_u, min_u, diff_u : unsigned(7 downto 0):=(others=>'0');
        variable sat_num : unsigned(16 downto 0);
        variable h_num : signed(16 downto 0):=(others=>'0');
        variable h_q : signed(8 downto 0) :=(others=>'0');
        variable h_temp : signed(17 downto 0) :=(others=>'0');
        variable h_final : signed(8 downto 0) :=(others=>'0');
        
        
      
      begin
        if rstn='0' then
          h_out_reg <= (others=>'0'); 
          s_out_reg <= (others=>'0'); 
          v_out_reg <= (others=>'0');
          s_num_reg <= (others=>'0');
          s_den_reg <= (others=>'0');
          h_num_reg <= (others=>'0');
          h_den_reg <= (others=>'0');
          max_pipe  <= (others=>(others=>'0'));
          diff_pipe <= (others=>(others=>'0'));
          data_rdy_pipe<=(others=>'0');
          channel_reg <= (others=>'0');
          div_en <='0';
          
          
          
        elsif rising_edge(clk) then
          
            
            --pipeline control signals
            data_rdy_pipe(0) <= data_rdy;
            for i in 1 to 10 loop
              data_rdy_pipe(i) <= data_rdy_pipe(i-1);
            end loop;
            
            for i in 1 to 10 loop
              max_pipe(i) <= max_pipe(i-1);
              diff_pipe(i)<= diff_pipe(i-1);
              channel_pipe_arr(i) <= channel_pipe_arr(i-1);
            end loop;
            
            if (data_rdy='0') and (data_rdy_pipe(9)='0') then
              div_en<='0';
            else
              div_en<='1';
            end if;
            
            
            if (data_rdy = '1' or data_rdy_pipe(0)='1') then
            --Pipeline data signals for output alignment
           
                 
            max_u := max3(unsigned(r), unsigned(g), unsigned(b));
            min_u := min3(unsigned(r), unsigned(g), unsigned(b));
            diff_u := max_u - min_u;
          
           
           
            max_pipe(0) <= max_u;
            diff_pipe(0)<= diff_u;
            channel_pipe_arr(0)  <= channel_reg;
            


          end if;
          
          
      
          
          if (max_u = min_u) then
                ch := "00";
          elsif (max_u = unsigned(r)) then
                ch := "01";
                
          elsif (max_u = unsigned(g)) then
                ch := "10";
                
          else  
                ch := "11";
                
          end if;
          

          
          
          channel_reg <= ch;

          
          sat_num := resize(diff_u*255,17) ;
          s_num_reg <= sat_num;
          s_den_reg <= max_u;
          g_b := signed('0'& g) - signed('0'& b);
          b_r := signed('0'& b) - signed('0'& r);
          r_g := signed('0'& r) - signed('0'& g);
          
    
          --S
           if ch="01" then
             h_num := resize(g_b*60,17) ;
           elsif ch="10" then
             h_num := resize(b_r*60,17) ;
           elsif ch="11" then
              h_num := resize(r_g*60,17) ;
           end if;
          h_num_reg <= h_num;
          h_den_reg <= diff_u;
          
          
           if (data_rdy_pipe(9) = '1' or data_rdy_pipe(10) = '1') then
          
          if max_pipe(8) = "00000000" then 
            s_out_reg <= (others=>'0');
          else
            s_out_reg <=unsigned(s_div_q(7 downto 0));
          end if;
          
          
          --H

          h_q := signed(h_div_q);
          h_temp := resize (h_q,18);
          
          
          if channel_pipe_arr(9) = "00" then
            h_out_reg <= (others=>'0');
          elsif channel_pipe_arr(9) = "01" then
            
            h_temp:= resize(h_temp,18);
          elsif channel_pipe_arr(9) = "10" then
            
            h_temp:= resize(h_temp,18)+ to_signed(2*60,18);
          elsif channel_pipe_arr(9) = "11" then
            
            h_temp:= resize(h_temp,18)+ to_signed(4*60,18);
          end if;
          
          

          

          if h_temp < to_signed(0,18) then
            h_temp := h_temp + to_signed(360,18);
          end if;
          
          
          h_out_reg <= std_logic_vector( h_temp(8 downto 0) );
          
          --V
         
          v_out_reg <= max_pipe(10); 
          
        
        end if;
      result_rdy <= data_rdy_pipe(10);
      end if;
      end process;
      
      
       
      h <= std_logic_vector(h_out_reg);
      s <= std_logic_vector(s_out_reg);
      v <= std_logic_vector(v_out_reg);

---updated
      

    -- STUDENT CODE until HERE

end architecture rtl;
