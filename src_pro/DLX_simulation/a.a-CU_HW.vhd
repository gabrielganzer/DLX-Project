----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Design units: DLX_CU
-- Function: DLX control unit
-- Input:
-- Output:
-- Architecture: structural
-- Library/package: ieee.std_logic_ll64, work.globals
-- Date: 12/08/2020
----------------------------------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity DLX_CU is
  generic (WIDTH  : integer := word_size;
           LENGTH : integer := addr_size);
  port (
    CLK              : in  std_logic;  -- Clock
    RST              : in  std_logic;  -- Synchronous reset, active-low
    IR_IN            : in std_logic_vector(WIDTH-1 downto 0);
    -- Control
    -- Stage 1: Instruction Fetch (IF)
    IF_EN            : out std_logic;
    -- Stage 2: Instruction Decode (ID)
    RegNPC1_LATCH_EN : out std_logic;
    RF_LATCH_EN      : out std_logic;
    RegImm_LATCH_EN  : out std_logic;
    RegRD1_LATCH_EN  : out std_logic;
    RF_RD1           : out std_logic;
    RF_RD2           : out std_logic;
    IMM_SEL          : out std_logic_vector(2 downto 0);
    -- Stage 3: Execution (EX)
    RegNPC2_LATCH_EN : out std_logic;
    RegALU1_LATCH_EN : out std_logic;
    RegME_LATCH_EN   : out std_logic;
    RegRD2_LATCH_EN  : out std_logic;
    MuxA_SEL         : out std_logic;
    MuxB_SEL         : out std_logic;
    EQ_COND          : out std_logic;
    JUMP_EN          : out std_logic;
    RF_WE_EX         : out std_logic;
    ALU_OPCODE       : out aluOp;
    -- Stage 4: Memory Access (MEM)
    RegNPC3_LATCH_EN : out std_logic;
    RegALU2_LATCH_EN : out std_logic;
    DRAM_LATCH_EN    : out std_logic;
    RegLMD_LATCH_EN  : out std_logic;
    RegRD3_LATCH_EN  : out std_logic;
    RF_WE_MEM        : out std_logic;
    DRAM_WE          : out std_logic;
    MMU_CTRL         : out mmuOp;
    -- Stage 5: Write-Back (WB)
    MuxWB_SEL        : out std_logic;
    RF_WE            : out std_logic;
    JUMP_LINK        : out std_logic
  ); 
end entity;

architecture HARDWIRED of DLX_CU is

  -- Instruction Register Fields
  signal IR_opcode : std_logic_vector(op_size-1 downto 0);              -- OpCode part of IR
  signal IR_func   : std_logic_vector(function_size -1 downto 0);       -- Func part of IR when Rtype
  -- Shifted Control Word
  signal cwi : std_logic_vector(control_word_size-1 downto 0);  -- Full Control Word
  signal cw1 : std_logic_vector(control_word_size-1 downto 0);    -- 1st stage
  signal cw2 : std_logic_vector(control_word_size-2 downto 0);    -- 2nd stage
  signal cw3 : std_logic_vector(control_word_size-11 downto 0);   -- 3rd stage
  signal cw4 : std_logic_vector(control_word_size-19 downto 0);   -- 4th stage
  signal cw5 : std_logic_vector(control_word_size-25 downto 0);   -- 5th stage
  -- Shifted ALU Opcode
  signal aluOpcodei : aluOp := nopOp; -- ALUOP defined in package
  signal aluOpcode1 : aluOp := nopOp; -- 1st stage
  signal aluOpcode2 : aluOp := nopOp; -- 2nd stage
  signal aluOpcode3 : aluOp := nopOp; -- 3rd stage
  -- Shifted MMU Opcode
  signal mmuOpcodei : mmuOp := IDLE; -- MMUOP defined in package
  signal mmuOpcode1 : mmuOp := IDLE; -- 1st stage
  signal mmuOpcode2 : mmuOp := IDLE; -- 2nd stage
  signal mmuOpcode3 : mmuOp := IDLE; -- 3rd stage
  signal mmuOpcode4 : mmuOp := IDLE; -- 4th stage

begin

  -- OpCode and Func extraction
  IR_opcode        <= IR_IN(opcode_up downto opcode_down);
  IR_func          <= IR_IN(func_up downto func_down);
  -- Stage 1: Instruction Fetch (IF)
  IF_EN            <= cw1(control_word_size-1);
  -- Stage 2: Instruction Decode (ID)
  RegNPC1_LATCH_EN <= cw2(control_word_size-2);
  RF_LATCH_EN      <= cw2(control_word_size-3);
  RegImm_LATCH_EN  <= cw2(control_word_size-4);
  RegRD1_LATCH_EN  <= cw2(control_word_size-5);
  RF_RD1           <= cw2(control_word_size-6);
  RF_RD2           <= cw2(control_word_size-7);
  IMM_SEL          <= cw2(control_word_size-8 downto control_word_size-10);
  -- Stage 3: Execution (EX)
  RegNPC2_LATCH_EN <= cw3(control_word_size-11);
  RegALU1_LATCH_EN <= cw3(control_word_size-12);
  RegME_LATCH_EN   <= cw3(control_word_size-13);
  RegRD2_LATCH_EN  <= cw3(control_word_size-14);
  MuxA_SEL         <= cw3(control_word_size-15);
  MuxB_SEL         <= cw3(control_word_size-16);
  EQ_COND          <= cw3(control_word_size-17);
  JUMP_EN          <= cw3(control_word_size-18);
  RF_WE_EX         <= cw3(control_word_size-26);
  ALU_OPCODE       <= aluOpcode3;
  -- Stage 4: Memory Access (MEM)
  RegNPC3_LATCH_EN <= cw4(control_word_size-19);
  RegALU2_LATCH_EN <= cw4(control_word_size-20);
  DRAM_LATCH_EN    <= cw4(control_word_size-21);
  RegLMD_LATCH_EN  <= cw4(control_word_size-22);
  RegRD3_LATCH_EN  <= cw4(control_word_size-23);
  RF_WE_MEM        <= cw4(control_word_size-26);
  DRAM_WE          <= cw4(control_word_size-24);
  MMU_CTRL         <= mmuOpcode4;
  -- Stage 5: Write-Back (WB)
  MuxWB_SEL        <= cw5(control_word_size-25);
  RF_WE            <= cw5(control_word_size-26);
  JUMP_LINK        <= cw5(control_word_size-27);

  -- Pipeline control words
  PIPE: process (CLK, RST)
  begin
      if (RST = '0') then
        cw1 <= (others => '0');
        cw2 <= (others => '0');
        cw3 <= (others => '0');
        cw4 <= (others => '0');
        cw5 <= (others => '0');
        aluOpcode1 <= nopOp; 
        aluOpcode2 <= nopOp; 
        aluOpcode3 <= nopOp;
        mmuOpcode1 <= IDLE;
        mmuOpcode2 <= IDLE;
        mmuOpcode3 <= IDLE;
        mmuOpcode4 <= IDLE;
      elsif (CLK = '1' and CLK'event) then
        cw1 <= cwi;
        cw2 <= cw1(control_word_size-2 downto 0);
        cw3 <= cw2(control_word_size-11 downto 0);
        cw4 <= cw3(control_word_size-19 downto 0);
        cw5 <= cw4(control_word_size-25 downto 0);
        aluOpcode1 <= aluOpcodei; 
        aluOpcode2 <= aluOpcode1; 
        aluOpcode3 <= aluOpcode2;
        mmuOpcode1 <= mmuOpcodei;
        mmuOpcode2 <= mmuOpcode1;
        mmuOpcode3 <= mmuOpcode2;
        mmuOpcode4 <= mmuOpcode3;
      end if;
  end process;

  CW_LUT: process(IR_opcode)
  begin
 	  case IR_opcode is
 	    when RTYPE      => cwi <= "11110010100100001001010";
  		  when NOP        => cwi <= "10000000000000001001000";
      when J          => cwi <= "11000011001100001001000";
      when J_JAL      => cwi <= "11000011001100001001011";
      when J_BEQZ     => cwi <= "11101111011100001001000";
      when J_BNEZ     => cwi <= "11101111001100001001000";
      when J_JR       => cwi <= "11101010001100001001000";
      when J_JALR     => cwi <= "11101010001100001001011";
      when I_ADDI     => cwi <= "11101110000100001001010";
      when I_ADDUI    => cwi <= "11101010000100001001010";
      when I_SUBI     => cwi <= "11101110000100001001010";
      when I_SUBUI    => cwi <= "11101010000100001001010";
      when I_ANDI     => cwi <= "11101110000100001001010";
      when I_ORI      => cwi <= "11101110000100001001010";
      when I_XORI     => cwi <= "11101110000100001001010";
      when I_LHI      => cwi <= "11001110000100001001010";
      when I_SLLI     => cwi <= "11101110000100001001010";
      when I_SRLI     => cwi <= "11101110000100001001010";
      when I_SRAI     => cwi <= "11101110000100001001010";
      when I_SEQI     => cwi <= "11101110000100001001010";
      when I_SNEI     => cwi <= "11101110000100001001010";
      when I_SLTI     => cwi <= "11101110000100001001010";
      when I_SGTI     => cwi <= "11101110000100001001010";
      when I_SLEI     => cwi <= "11101110000100001001010";
      when I_SGEI     => cwi <= "11101110000100001001010";
      when I_LB       => cwi <= "11101110000101100001110";
      when I_LH       => cwi <= "11101110000101010001110";
      when I_LW       => cwi <= "11101110000100001001110";
      when I_SB       => cwi <= "11111110000110001100100";
      when I_SH       => cwi <= "11111110000110001010100";
      when I_SW       => cwi <= "11111110000110001001100";
      when I_LBU      => cwi <= "11101110000100100001110";
      when I_LHU      => cwi <= "11101110000100010001110";
      when I_SLTUI    => cwi <= "11101010000100001001010";
      when I_SGTUI    => cwi <= "11101010000100001001010";
      when I_SLEUI    => cwi <= "11101010000100001001010";
      when I_SGEUI    => cwi <= "11101010000100001001010";
  		  when others     => cwi <= "10000000000000000000000";
	 end case;
  end process;

  OPCODE_LUT: process (IR_opcode, IR_func)
  begin
	  case IR_opcode is
  		  when RTYPE =>
  		    case IR_func is
          when R_SLL  => aluOpcodei <= sllOp;
          when R_SRL  => aluOpcodei <= srlOp;
          when R_SRA  => aluOpcodei <= sraOp;
          when R_MULT => aluOpcodei <= multOp;
          when R_ADD  => aluOpcodei <= addOp;
          when R_ADDU => aluOpcodei <= addOp;
          when R_SUB  => aluOpcodei <= subOp;
          when R_SUBU => aluOpcodei <= subOp;
          when R_AND  => aluOpcodei <= andOp;
          when R_OR   => aluOpcodei <= orOp;
          when R_XOR  => aluOpcodei <= xorOp;
          when R_SEQ  => aluOpcodei <= eqOp;
          when R_SNE  => aluOpcodei <= neOp;
          when R_SLT  => aluOpcodei <= ltOp;
          when R_SGT  => aluOpcodei <= gtOp;
          when R_SLE  => aluOpcodei <= leOp;
          when R_SGE  => aluOpcodei <= geOp;
          when R_SLTU => aluOpcodei <= ltUOp;
          when R_SGTU => aluOpcodei <= gtUOp;
          when R_SLEU => aluOpcodei <= leUOp;
          when R_SGEU => aluOpcodei <= geUOp;
          when others => aluOpcodei <= nopOp;
        end case;
  		  when NOP        => aluOpcodei <= nopOp;
      when J          => aluOpcodei <= addOp;
      when J_JAL      => aluOpcodei <= addOp;
      when J_BEQZ     => aluOpcodei <= addOp;
      when J_BNEZ     => aluOpcodei <= addOp;
      when J_JR       => aluOpcodei <= addOp;
      when J_JALR     => aluOpcodei <= addOp;
      when I_ADDI     => aluOpcodei <= addOp;
      when I_ADDUI    => aluOpcodei <= addOp;
      when I_SUBI     => aluOpcodei <= subOp;
      when I_SUBUI    => aluOpcodei <= subOp;
      when I_ANDI     => aluOpcodei <= andOp;
      when I_ORI      => aluOpcodei <= orOp;
      when I_XORI     => aluOpcodei <= xorOp;
      when I_LHI      => aluOpcodei <= lhiOp;
      when I_SLLI     => aluOpcodei <= sllOp;
      when I_SRLI     => aluOpcodei <= srlOp;
      when I_SRAI     => aluOpcodei <= sraOp;
      when I_SEQI     => aluOpcodei <= eqOp;
      when I_SNEI     => aluOpcodei <= neOp;
      when I_SLTI     => aluOpcodei <= ltOp;
      when I_SGTI     => aluOpcodei <= gtOp;
      when I_SLEI     => aluOpcodei <= leOp;
      when I_SGEI     => aluOpcodei <= geOp;
      when I_LB       => aluOpcodei <= addOp;
      when	I_LH       => aluOpcodei <= addOp;
      when I_LW       => aluOpcodei <= addOp;
      when I_LBU      => aluOpcodei <= addOp;
      when I_LHU      => aluOpcodei <= addOp;
      when I_SB       => aluOpcodei <= addOp;
      when I_SH       => aluOpcodei <= addOp;
      when I_SW       => aluOpcodei <= addOp;
      when I_SLTUI    => aluOpcodei <= ltUOp;
      when I_SGTUI    => aluOpcodei <= gtUOp;
      when I_SLEUI    => aluOpcodei <= leUOp;
      when I_SGEUI    => aluOpcodei <= geUOp;
  		  when others     => aluOpcodei <= nopOp;
	 end case;
	end process;
	
	MEM_LUT: process(IR_opcode)
  begin
 	  case IR_opcode is
      when I_LB       => mmuOpcodei <= LB;
      when I_LH       => mmuOpcodei <= LH;
      when I_LW       => mmuOpcodei <= LW;
      when I_SB       => mmuOpcodei <= SB;
      when I_SH       => mmuOpcodei <= SH;
      when I_SW       => mmuOpcodei <= SW;
      when I_LBU      => mmuOpcodei <= LBU;
      when I_LHU      => mmuOpcodei <= LHU;
  		  when others     => mmuOpcodei <= IDLE;
	 end case;
  end process;

end architecture;
