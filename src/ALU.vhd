----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

begin
    process (i_A, i_B, i_op)
    variable temp_value: unsigned (8 downto 0);
    begin 
        if i_op = "000" then -- add
            temp_value := ('0' & unsigned(i_A)) + ('0' & unsigned(i_B));
            o_flags(2) <= temp_value(8); -- carry
            o_result <= std_logic_vector(temp_value(7 downto 0));
            
            o_flags(1) <= (i_A(7) and i_B(7) and not temp_value(7)) or 
                          (not i_A(7) and not i_B(7) and temp_value(7));
            
        elsif i_op = "001" then -- subtract
            temp_value := ('0' & unsigned(i_A)) - ('0' & unsigned(i_B));
            o_flags(2) <= temp_value(8); -- carry
            o_result <= std_logic_vector(temp_value(7 downto 0));
            
            o_flags(1) <= (i_A(7) and not i_B(7) and not temp_value(7)) or 
                          (not i_A(7) and i_B(7) and temp_value(7));
            
            
        elsif i_op = "010" then -- and
            o_result <= i_A and i_B;
        elsif i_op = "011" then -- or
            o_result <= i_A or i_B;
        end if;
            
        o_flags(3) <= temp_value(7); -- negative
               
        if temp_value = "000000000" then
            o_flags(0) <= '1';
        end if;
    end process;


end Behavioral;
