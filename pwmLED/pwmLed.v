module pwnLed

	(
		input wire clk,         // input from clock source
		input wire [3:0] sw,    // input from dip switches
		output wire out,        // output to LED
		output wire scope       // output for oscilloscope
	);
	
	// constant declarations
	localparam totalCycles = 12000;     // divisor of mod counter (number of clock cycles before reset to 0) f = 1000 Hz
	localparam multiplier  = 800;       // 12000 / 15 = 800 cycles to multiply by 4 bit duty cycle input to get total time ON
	localparam N = 14;                  // width of register = ceiling( log(2, 1200000*15) )
	 
	// internal signals 
	reg  [N-1:0] counter_reg;      // register for counter 
	wire [N-1:0] counter_next;     // next state output of counter

        wire [3:0] dutyCycle;                  // connections to input from dip switch
	assign dutyCycle = ~sw[3:0];           // lower 4 switches assigned decode duty cycle = dc / 16

	// counter register
	always @(posedge clk)               // on positive clock edge
            counter_reg <= counter_next;   // update register contents to next state logic

	// next state logic:  if counter register exceeds reset value, reset to 0, else increment by 1
	assign counter_next = (counter_reg >= totalCycles) ? 14'b0 : counter_reg + 1;
							 
        // assign output logic
	// output is 1 when counter is less than input duty cycle * multiplier : else 
	// output is 0 for the remaining of the total cycles before the counter resets to 0
        assign out = (counter_reg < (dutyCycle * multiplier)) ? 1'b1 : 1'b0;
	
	// route LED output to oscilloscope output
	assign scope = out;

endmodule 
