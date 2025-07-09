library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std.unsigned;

entity div16_8_8 is
	port (
		clk        : in  STD_LOGIC;
		en         : in  STD_LOGIC;
		rstn       : in  STD_LOGIC;
		a          : in  STD_LOGIC_VECTOR( 17-1 downto 0);
		b          : in  STD_LOGIC_VECTOR( 8-1 downto 0);
		result     : out STD_LOGIC_VECTOR( 9-1 downto 0)		
	);
end entity div16_8_8;

architecture rtl of div16_8_8 is

    type unsigned_8_array  is array(natural range <>) of UNSIGNED(8-1 downto 0);
	type unsigned_16_array is array(natural range <>) of UNSIGNED(17-2 downto 0);

	signal r_remainder 		: unsigned_16_array(1 to 9);
	signal r_shifted_b 		: unsigned_16_array(1 to 9);
	signal r_result    		: unsigned_8_array (1 to 9);
	signal r_result_signed 	: SIGNED(9-1 downto 0);
	signal r_sign      		: STD_LOGIC_VECTOR(1 to 9);
	signal r_en		     	: STD_LOGIC_VECTOR(1 to 9);
begin

	process(clk, rstn, en)
		variable v_result 	: UNSIGNED(9-1 downto 1);
        variable a_signed 	: SIGNED(17-1 downto 0);
        variable a_unsigned : UNSIGNED(17-2 downto 0);
begin
		if rstn = '0' then
	
-- STUDENT CODE HERE

        v_result := (others => '0');
        r_result_signed <= (others => '0');
        for i in 1 to 9 loop
            r_remainder(i)  <= (others => '0');
            r_shifted_b(i)  <= (others => '0');
            r_result(i)  <= (others => '0');
            r_sign(i)       <= '0';
            r_en(i)         <= '0';
        end loop;


-- STUDENT CODE until HERE

    elsif rising_edge(clk) then


-- STUDENT CODE HERE
if en =  '1' then

-- initial allocation
r_en(1) <= en;
r_sign(1) <= a(17-1);

a_signed := signed(a(17-1 downto 0));
a_unsigned := unsigned(a(17-2 downto 0));


r_shifted_b(1) <= '0' & unsigned(b) & (17-2 - 8-1 downto 0 => '0');


if a_signed(17-1) ='1'then 
r_remainder(1) <= (not a_unsigned) +1;

else

r_remainder(1) <= a_unsigned;

end if;


for i in 1 to (9-1) loop 
r_en(i+1) <= r_en(i);
r_sign(i+1) <= r_sign(i);




r_shifted_b(i+1) <= SHIFT_RIGHT(r_shifted_b(i),1);

r_result(i+1) <= shift_left(r_result(i), 1);


if r_remainder(i) >= r_shifted_b(i)then 


r_remainder(i+1) <= r_remainder(i)-r_shifted_b(i);

r_result(i+1)(0) <= '1';

v_result := v_result or shift_left(to_unsigned(1, 9-1), i-1);

else

r_remainder(i+1) <= r_remainder(i);
r_result(i+1)(0) <= '0';

end if;
end loop;
--



if r_en(9) = '1' then
if r_sign(9) = '1' then
r_result_signed <= SIGNED(((r_sign(9)) & (not UNSIGNED(r_result(9))))+ 1);

else

r_result_signed <= r_sign(9) & SIGNED(r_result(9));

end if;
end if;
end if;
end if;
end process;
	
result <= STD_LOGIC_VECTOR(r_result_signed);

end architecture rtl;