module minSecTimer
	
	(
	  input wire clk,
	  input wire go, stop, clr, 
	  output wire [3:0] d3, d2, d1, d0
	);
	
	// declarations for counter circuit
	localparam divisor = 50000000;                  // number of clock cycles in 1 s, for mod-50M counter
	reg [26:0] sec_reg;                             // register for second counter
	wire [26:0] sec_next;                           // next state connection for second counter
	reg [3:0] d3_reg, d2_reg, d1_reg, d0_reg;       // registers for decimal values displayed on 4 digit displays
	wire [3:0] d3_next, d2_next, d1_next, d0_next;  // next state wiring for 4 digit displays
	wire d3_en, d2_en, d1_en, d0_en;                // enable signals for display multiplexing 
	wire sec_tick, d0_tick, d1_tick, d2_tick;       // signals to enable next stage of counting
	
	
	// declarations for FSM circuit
	reg state_reg, state_next;           // register for current state and next state     
	
	localparam off = 1'b0,               // states 
	           on = 1'b1;
   
	// state register
	always @(posedge clk, posedge clr)
	   if(clr)
		  state_reg <= 0;
		else 
		  state_reg <= state_next;

   // FSM next state logic
   always @*
       case(state_reg)
         off:begin
			    if(go)
               state_next = on;
				 else 
				   state_next = off;
				 end
			
			on: begin
			    if(stop)
               state_next = off;
				 else 
				   state_next = on;
             end
        endcase		  
		  
   // counter register 
	always @(posedge clk)
	    begin
		 sec_reg <= sec_next;
		 d0_reg  <= d0_next;
		 d1_reg  <= d1_next;
		 d2_reg  <= d2_next; 
		 d3_reg  <= d3_next;
		 end
	
	// next state logic 
	// 1 second tick generator : mod-50M
	assign sec_next = (clr || sec_reg == divisor && (state_reg == on)) ? 4'b0 : 
	                  (state_reg == on) ? sec_reg + 1 : sec_reg;
	
	assign sec_tick = (sec_reg == divisor) ? 1'b1 : 1'b0;
	
	// second ones counter 
	assign d0_en   = sec_tick; 
	
	assign d0_next = (clr || (d0_en && d0_reg == 9)) ? 4'b0 : 
	                  d0_en ? d0_reg + 1 : d0_reg; 
	
	assign d0_tick = (d0_reg == 9) ? 1'b1 : 1'b0;
							
	// second tenths counter 
	assign d1_en = sec_tick & d0_tick; 
	
	assign d1_next = (clr || (d1_en && d1_reg == 5)) ? 4'b0 : 
	                  d1_en ? d1_reg + 1 : d1_reg; 	
							
	assign d1_tick = (d1_reg == 5) ? 1'b1 : 1'b0;
	
	// minute ones counter 
	assign d2_en = sec_tick & d0_tick & d1_tick; 
	
	assign d2_next = (clr || (d2_en && d2_reg == 9)) ? 4'b0 : 
	                  d2_en ? d2_reg + 1 : d2_reg;
	
   assign d2_tick = (d2_reg == 9) ? 1'b1 : 1'b0;	
	
	// minute tenths counter 
	assign d3_en = sec_tick & d0_tick & d1_tick & d2_tick; 
	
	assign d3_next = (clr || (d3_en && d3_reg == 9)) ? 4'b0 : 
	                  d3_en ? d3_reg + 1 : d3_reg;
							
	// output logic 
   assign d0 = d0_reg; 
   assign d1 = d1_reg; 
   assign d2 = d2_reg;
	assign d3 = d3_reg;

endmodule 