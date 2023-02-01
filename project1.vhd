LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.clk_div_pkg.ALL;
--use work.gate_pkg.all;

ENTITY project1 IS
    PORT (
        clk : IN STD_LOGIC; -- clock 50 MHz
        rst_n : IN STD_LOGIC;
		  
		  -- Values for reset
        H_in1 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        H_in0 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        M_in1 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        M_in0 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        S_in1 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        S_in0 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
		  
		  -- 7-segment outputs
        H_out1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        H_out0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        M_out1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        M_out0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        S_out1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        S_out0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);

        sensor : IN STD_LOGIC;
        buzzer : BUFFER STD_LOGIC;
        servo : BUFFER STD_LOGIC

    );
END project1;

ARCHITECTURE Behavioral OF project1 IS
    COMPONENT bin2hex
        PORT (
            Bin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Hout : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT clk_div
        PORT (
            CLK50MHZ : IN STD_LOGIC;
            --    CPU_RESETN: in std_logic;
            --    reset: in std_logic;
            clk_stb : BUFFER STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clk_1s : STD_LOGIC; -- 1-s clock
    SIGNAL counter_hour, counter_minute, counter_second : INTEGER;

    -- counter using for create time
    SIGNAL H_out1_bin : STD_LOGIC_VECTOR(3 DOWNTO 0); --The most significant digit of the hour
    SIGNAL H_out0_bin : STD_LOGIC_VECTOR(3 DOWNTO 0);--The least significant digit of the hour
    SIGNAL M_out1_bin : STD_LOGIC_VECTOR(3 DOWNTO 0);--The most significant digit of the minute
    SIGNAL M_out0_bin : STD_LOGIC_VECTOR(3 DOWNTO 0);--The least significant digit of the minute
    SIGNAL S_out1_bin : STD_LOGIC_VECTOR(3 DOWNTO 0);--The most significant digit of the second
    SIGNAL S_out0_bin : STD_LOGIC_VECTOR(3 DOWNTO 0);--The least significant digit of the second

    SIGNAL buzzCounter : INTEGER RANGE 0 TO 10;

BEGIN

    -- DEFAULT VALUES ---
    H_in1 <= x"1";
    H_in0 <= x"2";
    M_in1 <= x"4";
    M_in0 <= x"9";
    S_in1 <= x"5";
    S_in0 <= x"8";

    ---SENSOR AND BUZZER---

    -- PROCESS (sensor)
    -- BEGIN
    -- END PROCESS;

    --	servoAssign:  entity work.gate(main) port map(clk, sensor, servo);

    -- create 1-s clock --|
    create_1s_clock : clk_div PORT MAP(clk, clk_1s);

    -- clock operation ---|
    PROCESS (clk_1s, rst_n) BEGIN

        IF (rst_n = '0') THEN
            counter_hour <= to_integer(unsigned(H_in1)) * 10 + to_integer(unsigned(H_in0));
            counter_minute <= to_integer(unsigned(M_in1)) * 10 + to_integer(unsigned(M_in0));
            counter_second <= to_integer(unsigned(S_in1)) * 10 + to_integer(unsigned(S_in0));
        ELSIF (rising_edge(clk_1s)) THEN

            ---- SENSOR CHECK --------
            IF sensor = '0' AND buzzer = '1' THEN
                servo <= '1';
                buzzer <= '0';
                buzzCounter <= 0;
            END IF;

            counter_second <= counter_second + 1;
            IF (servo = '1') THEN
                buzzCounter <= buzzCounter + 1;
            END IF;

            IF (buzzCounter >= 1) THEN
                servo <= '0';
                buzzCounter <= 0;
            END IF;

            IF (counter_hour = 12 AND counter_minute = 50 AND counter_second = 20) THEN
                buzzer <= '1';
            END IF;

            IF (counter_second >= 59) THEN -- second > 59 then minute increases
                counter_minute <= counter_minute + 1;
                counter_second <= 0;
                IF (counter_minute >= 59) THEN -- minute > 59 then hour increases
                    counter_minute <= 0;
                    counter_hour <= counter_hour + 1;
                    IF (counter_hour >= 24) THEN -- hour > 24 then set hour to 0
                        counter_hour <= 0;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    ----------------------|
    -- Conversion time ---|
    ----------------------|
    -- H_out1 binary value
    H_out1_bin <= x"2" WHEN counter_hour >= 20 ELSE
        x"1" WHEN counter_hour >= 10 ELSE
        x"0";
    -- 7-Segment LED display of H_out1
    convert_hex_H_out1 : bin2hex PORT MAP(Bin => H_out1_bin, Hout => H_out1);
    -- H_out0 binary value
    H_out0_bin <= STD_LOGIC_VECTOR(to_unsigned((counter_hour - to_integer(unsigned(H_out1_bin)) * 10), 4));
    -- 7-Segment LED display of H_out0
    convert_hex_H_out0 : bin2hex PORT MAP(Bin => H_out0_bin, Hout => H_out0);
    -- M_out1 binary value
    M_out1_bin <= x"5" WHEN counter_minute >= 50 ELSE
        x"4" WHEN counter_minute >= 40 ELSE
        x"3" WHEN counter_minute >= 30 ELSE
        x"2" WHEN counter_minute >= 20 ELSE
        x"1" WHEN counter_minute >= 10 ELSE
        x"0";
    -- 7-Segment LED display of M_out1
    convert_hex_M_out1 : bin2hex PORT MAP(Bin => M_out1_bin, Hout => M_out1);
    -- M_out0 binary value
    M_out0_bin <= STD_LOGIC_VECTOR(to_unsigned((counter_minute - to_integer(unsigned(M_out1_bin)) * 10), 4));
    -- 7-Segment LED display of M_out0
    convert_hex_M_out0 : bin2hex PORT MAP(Bin => M_out0_bin, Hout => M_out0);
    -- S_out1 binary value
    S_out1_bin <= x"5" WHEN counter_second >= 50 ELSE
        x"4" WHEN counter_second >= 40 ELSE
        x"3" WHEN counter_second >= 30 ELSE
        x"2" WHEN counter_second >= 20 ELSE
        x"1" WHEN counter_second >= 10 ELSE
        x"0";
    -- 7-Segment LED display of S_out1
    convert_hex_S_out1 : bin2hex PORT MAP(Bin => S_out1_bin, Hout => S_out1);
    -- S_out0 binary value
    S_out0_bin <= STD_LOGIC_VECTOR(to_unsigned((counter_second - to_integer(unsigned(S_out1_bin)) * 10), 4));
    -- 7-Segment LED display of S_out0
    convert_hex_S_out0 : bin2hex PORT MAP(Bin => S_out0_bin, Hout => S_out0);
END Behavioral;



-- BCD to HEX For 7-segment LEDs display 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY bin2hex IS
    PORT (
        Bin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        Hout : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END bin2hex;
ARCHITECTURE Behavioral OF bin2hex IS
BEGIN
    PROCESS (Bin)
    BEGIN
        CASE(Bin) IS
            WHEN "0000" => Hout <= "1000000"; --0--
            WHEN "0001" => Hout <= "1111001"; --1--
            WHEN "0010" => Hout <= "0100100"; --2--
            WHEN "0011" => Hout <= "0110000"; --3--
            WHEN "0100" => Hout <= "0011001"; --4-- 
            WHEN "0101" => Hout <= "0010010"; --5--    
            WHEN "0110" => Hout <= "0000010"; --6--
            WHEN "0111" => Hout <= "1111000"; --7--   
            WHEN "1000" => Hout <= "0000000"; --8--
            WHEN "1001" => Hout <= "0010000"; --9--
            WHEN "1010" => Hout <= "0001000"; --a--
            WHEN "1011" => Hout <= "0000011"; --b--
            WHEN "1100" => Hout <= "1000110"; --c--
            WHEN "1101" => Hout <= "0100001"; --d--
            WHEN "1110" => Hout <= "0000110"; --e--
            WHEN OTHERS => Hout <= "0001110";
        END CASE;
    END PROCESS;
END Behavioral;