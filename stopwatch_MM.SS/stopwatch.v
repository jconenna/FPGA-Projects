module stopwatch

	( 
	  input wire clk, go, stop, clr,              // clock and reset input lines
	  output wire [3:0] an,                        // enable for 4 displays
	  output wire [7:0] sseg                       // led segments
	);
	
	wire [3:0] d3, d2, d1, d0;
	
	minSecTimer timer (.clk(clk), .go(go), .stop(stop), .clr(clr), .d3(d3), .d2(d2), .d1(d1), .d0(d0));
	
	displayMuxBasys display_unit (.clk(clk), .hex3(d3), .hex2(d2), .hex1(d1), .hex0(d0), .dp_in(4'b1011), .an(an), .sseg(sseg));
	
endmodule 