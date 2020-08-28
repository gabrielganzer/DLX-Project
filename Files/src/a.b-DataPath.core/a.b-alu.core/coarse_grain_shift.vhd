----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Design units: COARSE_SHIFT
-- Function: T2 shifter 2nd level coarse grain shift, mask select
-- Input: sel (2-bit), mask00, mask08, mask16 (39-bit)
-- Output: y (39-bit)
-- Architecture: behavioral
-- Library/package: ieee.std_logic_ll64
-- Date: 14/04/2020
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity COARSE_SHIFT is
  port (
    -- Inputs
    sel    : in std_logic_vector(1 downto 0);
    mask00 : in std_logic_vector(38 downto 0);
    mask08 : in std_logic_vector(38 downto 0);
    mask16 : in std_logic_vector(38 downto 0);
    -- Output
    y      : out std_logic_vector(38 downto 0)
  );
end entity;

architecture BEHAVIORAL of COARSE_SHIFT is
begin 

  MASK_SELECTION: process(sel, mask00, mask08, mask16)
	begin		
		case sel is
			when "00" =>
				y <= mask00;
			when "01" =>
				y <= mask08;
			when "10" =>
				y <= mask16;
			when others => 
			  y <= x"000000000" & "000";
		end case;
	end process;
	
end architecture;