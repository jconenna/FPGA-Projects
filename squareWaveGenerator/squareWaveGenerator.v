module squareWaveGenerator

	(
		input wire clk,         // input from clock source
		input wire [7:0] sw,    // input from dip switches
		output wire out,        // output to LED
		output wire scope       // output for oscilloscope
	);
	
	// constant declarations
	localparam cycles = 1200000;   // divisor of mod counter (number of clock cycles)
	localparam N = 26;             // width of register = ceiling( log(2, 1200000*15) )
	
	
	// internal signals 
	reg  [N-1:0] counter_reg;      // register for counter 
	wire [N-1:0] counter_next;     // next state output of counter

        wire [3:0] m , n;              // connections to input from dip switch
	assign m = ~sw[7:4];           // upper 4 switches assigned to decode ON interval multiplier
	assign n = ~sw[3:0];           // lower 4 switches assigned to decode OFF interval multiplier

	// counter register
	always @(posedge clk)               // on positive clock edge
            counter_reg <= counter_next;   // update register contents to next state logic

	// next state logic:  if counter register exceeds current reset value, reset to 0, else increment by 1
	assign counter_next = (counter_reg >= (cycles * (m + n)) - 1) ? 26'b0 : counter_reg + 1;
							 
        // assign output logic
	// when counter register is counting up in ON interval, set output to 1, else: 
	// if counter register is counting up in OFF interval, set output to 0
        assign out = (counter_reg < (cycles * m)) ? 1'b1 : 1'b0;	
	
	// route LED output to oscilloscope output
	assign scope = out;

endmodule 
