----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Design units: ZERO_DETECTOR
-- Function: Zero equivalence block
-- Input:  A (32-bit)
-- Output: Y (1-bit)
-- Architecture: rtl
-- Library/package: ieee.std_logic_ll64
-- Date: 05/08/2020
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity ZERO_DETECTOR is
  generic (WIDTH: integer := 32);
  port (
    A              : in  std_logic_vector(WIDTH-1 downto 0);
    Y              : out std_logic
  );
end entity;

architecture RTL of ZERO_DETECTOR is
  -- Signal
  signal tmp: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
begin
  Y <= '1' when A = tmp else '0';
end architecture;