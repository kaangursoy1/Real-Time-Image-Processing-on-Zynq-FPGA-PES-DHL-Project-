library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! This component buffers the pixels of one line in the input image

--! The component implements a FIFO buffer with a depth of #LINE_LENGTH.
--! If #data_rdy is '1' the first element in the FIFO queue will be removed
--! and the input from #data_in is pushed to the end of the queue.
entity line_buffer is
    Generic (
        LINE_LENGTH : positive;   --! Length of the lines in the image
        ADDR_WIDTH  : positive;   --! Address width for the ram_dp subcomponent
        DATA_WIDTH  : positive    --! Data width for the ram_dp subcomponent
    );
  Port (
        clk             : in std_logic;     --! Clock input
        rstn            : in std_logic;     --! Negated asynchronous reset
        data_in         : in std_logic;  --! Input to be pushed to the FIFO
        data_rdy        : in std_logic;   --! Input bit indicating if the current input data (#data_in) should be pushed to the back of the FIFO queue
        result          : out std_logic;  --! Outputs the element at the front of the FIFO queue
        result_rdy      : out std_logic --! If #result_rdy is '1', the front element (accessible through #result) will be removed from the FIFO queue until the next clock cycle
    );
end line_buffer;

architecture rtl of line_buffer is

    component ram_dp is
    Generic (
        ADDR_WIDTH : positive;
        DATA_WIDTH : positive;
        USE_OUTPUT_REG : std_logic  := '0'
    );
    Port(
        clk     : in std_logic;
        wena    : in std_logic;
        wenb    : in std_logic;
        addra   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        addrb   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        dina    : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dinb    : in std_logic_vector(DATA_WIDTH-1 downto 0);
        douta   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        doutb   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
    end component;

-- STUDENT CODE HERE
 ------------------------------------------------------------------
    --  Dahili sabitler ve sinyaller
    ------------------------------------------------------------------
    constant ADDR_MAX : integer := LINE_LENGTH-1;         -- 0 ? LINE_LENGTH-1

    -- Adres sayaçlar?
    signal write_addr : integer range 0 to ADDR_MAX := 0;
    signal read_addr  : integer range 0 to ADDR_MAX := 1;

    -- ?lk sat?r tamamland???nda ?1? olur
    signal read_rdy   : std_logic := '0';

    -- BRAM port sinyalleri
    signal wena, wenb : std_logic := '0';
    signal addra, addrb : std_logic_vector(ADDR_WIDTH-1 downto 0)
                          := (others => '0');
    signal dina          : std_logic_vector(DATA_WIDTH-1 downto 0)
                          := (others => '0');
    signal doutb         : std_logic_vector(DATA_WIDTH-1 downto 0);
    -- STUDENT CODE until HERE

begin

-- STUDENT CODE HERE
   ------------------------------------------------------------------
    -- Dual-port BRAM instansiyonu
    ------------------------------------------------------------------
    buf : ram_dp
        generic map (
            ADDR_WIDTH      => ADDR_WIDTH,
            DATA_WIDTH      => DATA_WIDTH,
            USE_OUTPUT_REG  => '0')
        port map (
            clk   => clk,
            -- Port-A : write
            wena  => wena,
            addra => addra,
            dina  => dina,
            douta => open,
            -- Port-B : read
            wenb  => wenb,
            addrb => addrb,
            dinb  => (others => '0'),
            doutb => doutb
        );

    ------------------------------------------------------------------
    -- Ana kontrol süreci  (verdi?iniz ?do?ru? kod aynen yerle?tirildi)
    ------------------------------------------------------------------
    process(clk, rstn)
    begin
        if (rstn = '0') then
            write_addr <= 0;          -- set start write address as 0
            read_addr  <= 1;          -- set start read address as 1
            read_rdy   <= '0';
            result_rdy <= '0';
            wena       <= '0';
            wenb       <= '0';
        elsif rising_edge(clk) then
            if (data_rdy = '1') then
                dina(0) <= data_in;                   -- data for write
                wena    <= '1';                       -- write enable
                wenb    <= '0';                       -- read (no write on B)
                addra   <= std_logic_vector(to_unsigned(write_addr,
                                                        ADDR_WIDTH));
                addrb   <= std_logic_vector(to_unsigned(read_addr,
                                                        ADDR_WIDTH));

                -- write pointer
                if (write_addr < LINE_LENGTH-1) then
                    write_addr <= write_addr + 1;
                else
                    write_addr <= 0;
                    read_rdy   <= '1';                -- first line complete
                end if;

                -- read pointer (sürekli döner)
                if (read_addr < LINE_LENGTH-1) then
                    read_addr <= read_addr + 1;
                else
                    read_addr <= 0;
                end if;

                -- result valid after first line
                if (read_rdy = '1') then
                    result_rdy <= '1';
                end if;
            else
                result_rdy <= '0';
                wena       <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- BRAM?den okunani sonuca ba?la
    ------------------------------------------------------------------
    process(doutb, read_rdy)
    begin
        if (read_rdy = '1') then
            result <= doutb(0);
        else
            result <= '0';
        end if;
    end process;
    -- STUDENT CODE until HERE

end rtl;

