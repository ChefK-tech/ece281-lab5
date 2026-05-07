--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component button_debounce is
        Port(	clk: in  STD_LOGIC;
                reset : in  STD_LOGIC;
                button: in STD_LOGIC;
                action: out STD_LOGIC);
    end component button_debounce;
    
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    signal btn_debounce : std_logic;
    signal alu_result : std_logic_vector (7 downto 0); -- In between vector
    signal w_clk : std_logic; 
    signal w_sign: std_logic;
    signal w_tdm_sign : std_logic_vector (3 downto 0) := "0000";
    signal w_hund: std_logic_vector(3 downto 0);
    signal w_tens: std_logic_vector(3 downto 0);
    signal w_ones: std_logic_vector(3 downto 0);
    signal w_tdm_data  : std_logic_vector(3 downto 0);
    signal w_tdm_sel   : std_logic_vector(3 downto 0);
    signal w_seg_int  : STD_LOGIC_VECTOR(6 downto 0);  -- internal signal
  
begin
	-- PORT MAPS ----------------------------------------
	debounce_inst: button_debounce
	   port map(
	       clk => clk,
	       reset => btnU,
	       button => btnC,
	       action => btn_debounce	   
	   );
	
	controller_inst : controller_fsm
        port map(
            i_reset => btnU,
            i_adv  => btn_debounce,
            o_cycle(3) => led(3),
            o_cycle(2) => led(2),
            o_cycle(1) => led(1),
            o_cycle(0) => led(0)
        );
        
    alu_inst : ALU 
        port map(
            i_A => sw(7 downto 0),
            i_B => sw(7 downto 0),
            i_op => sw(2 downto 0),
            o_result => alu_result,
            o_flags => led(15 downto 12)
        );
        
    clock_inst : clock_divider
        port map(
            i_clk => clk,
            i_reset => btnU,
            o_clk => w_clk
        );
        
    twoscomp_inst : twos_comp 
        port map(
           i_bin => alu_result,
           o_sign => w_sign,
           o_hund => w_hund,
           o_tens => w_tens,
           o_ones => w_ones
      );
        
    tdm4_inst : TDM4 
        port map(
           i_clk => w_clk,
           i_reset => btnU,
           i_D3 => w_tdm_sign,
           i_D2 => w_hund,
           i_D1 => w_tens,
           i_D0 => w_ones,
           o_data => w_tdm_data,
           o_sel => w_tdm_sel
        );
        
    uut: sevenseg_decoder port map (
        i_Hex   => w_tdm_data,
        o_seg_n => w_seg_int
       );
       
    w_seg_int <= "0000001" when w_sign = '1' else "0000000";
	
	-- CONCURRENT STATEMENTS ----------------------------
	led(11 downto 4) <= (others => '0');  -- LEDs 4-11 off
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	an <= "0000" when w_tdm_sel = "1110"
          else w_tdm_sel;
     -- Inverts each bit
    seg <= w_seg_int;
	
	
	
end top_basys3_arch;
