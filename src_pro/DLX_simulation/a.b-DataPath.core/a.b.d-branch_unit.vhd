----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Design units: BRANCH_UNIT
-- Function: Static branch predictor always taken
-- Input:
-- Output:
-- Architecture: behavioral
-- Library/package: ieee.std_logic_ll64, work.globals
-- Date: 12/08/2020
----------------------------------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use work.globals.all;

entity BRANCH_UNIT is
  port(Z         : in std_logic; -- Zero? Block Result
       JUMP_EN   : in std_logic; -- 1 J, 0 otherwise
       JUMP_EQ   : in std_logic; -- 1 BEQZ, 0 BNEZ
       JUMP_REG  : in std_logic; -- 1 JR and JALR, 0 otherwise
       JUMP_LINK : in std_logic; -- 1 JAL and JALR, 0 otherwise
       BRANCH    : out std_logic);
end entity;

architecture RTL of BRANCH_UNIT is
  signal BEQ   : std_logic;
  signal JUMP  : std_logic;
begin
  
  BEQ    <= (Z xnor JUMP_EQ);
  JUMP   <= BEQ or JUMP_REG or JUMP_LINK;
  BRANCH <= JUMP_EN and JUMP;

end architecture;
