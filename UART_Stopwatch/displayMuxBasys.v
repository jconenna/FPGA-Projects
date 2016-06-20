module displayMuxBasys

	( 
	  input wire clk,                             // clock
	  input wire [3:0] hex3, hex2, hex1, hex0,    // hex digits
	  input wire [3:0] dp_in,                     // 4 dec pts
	  output reg [3:0] an,                        // enable for 4 displays
	  output reg [7:0] sseg                       // led segments
	);

	// constant for refresh rate: 50 Mhz / 2^18 = 190 Hz
	// we will use 2 of the 2 MSB states to multiplex 3 displays
	localparam N = 18;
	
	// internal signals
	reg [N-1:0] q_reg;
	wire [N-1:0] q_next;
	reg [3:0] hex_in;
	reg dp;
	
	// counter register 
	always @(posedge clk)
         q_reg <= q_next; 
	
	// next state logic 
	assign q_next = q_reg + 1;
	
		// 2 MSBs control 3-to-1 multiplexing (active low)
	always @*
	   case (q_reg[N-1:N-2])
		    
			2'b00:
			   begin 
				an = 4'b1110;
            hex_in = hex0;
				dp = dp_in[0];
            end
				
			2'b01:
			   begin 
				an = 4'b1101;
            hex_in = hex1;
				dp = dp_in[1];
            end
				
			2'b10:
			   begin 
				an = 4'b1011;
            hex_in = hex2;
				dp = dp_in[2];
            end	

         2'b11:				
            begin 
				an = 4'b0111;
            hex_in = hex3;
				dp = dp_in[3];
            end	
				
         default:
            begin 
            an = 4'b1111;
				dp = 1'b1;
            end
      endcase 			
	
	// hex to seven-segment circuit 
	always @*
     begin 
     case(hex_in)
	       4'h0: sseg[6:0] = 7'b0000001;
			 4'h1: sseg[6:0] = 7'b1001111;
			 4'h2: sseg[6:0] = 7'b0010010;
			 4'h3: sseg[6:0] = 7'b0000110;
			 4'h4: sseg[6:0] = 7'b1001100;
			 4'h5: sseg[6:0] = 7'b0100100;
			 4'h6: sseg[6:0] = 7'b0100000;
			 4'h7: sseg[6:0] = 7'b0001111;
			 4'h8: sseg[6:0] = 7'b0000000;
			 4'h9: sseg[6:0] = 7'b0000100;
			 4'ha: sseg[6:0] = 7'b0001000;
			 4'hb: sseg[6:0] = 7'b1100000;
			 4'hc: sseg[6:0] = 7'b0110001;
			 4'hd: sseg[6:0] = 7'b1000010;
			 4'he: sseg[6:0] = 7'b0110000;
			 default: sseg[6:0] = 7'b0111000; // 4'hf
	  endcase 
	  sseg[7] = dp;
   end 

endmodule 