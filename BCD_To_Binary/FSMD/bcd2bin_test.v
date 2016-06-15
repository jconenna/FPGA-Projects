module bcd2bin_test

   (
    input wire clk, reset, 
    input wire start,
    input [7:0] bcd,
    output wire [3:0] an,
    output wire [7:0] sseg
    );
    
    // symbolic state declaration
    localparam  
    idle  = 1'b0,
    b2b   = 1'b1;   // bcd to binary conversion

    // internal signal declarations 
    wire [6:0] bin;
    reg b2b_start;
    wire b2b_done_tick;
    reg state_reg, state_next;
	 
    // instantiation of bcd to binary circuit, routing the bcd input in, and binary output out 
    bcd2bin bcd2bin_unit (.clk(clk), .reset(reset), .start(b2b_start), .bcd1(bcd[7:4]), .bcd0(bcd[3:0]), .ready(), .done_tick(b2b_done_tick), .bin(bin));
	 
    // instantiation of multiplexing 7-segment circuit, routing in binary output of converstion circuit to lower two displays
    displayMuxBasys disp_unit (.clk(clk), .hex3(4'b0000), .hex2(4'b0000), .hex1({1'b0, bin[6:4]}), .hex0(bin[3:0]), .dp_in(4'b1111), .an(an), .sseg(sseg));
 
    // state register
    always @(posedge clk, posedge reset)
        if (reset)
           state_reg <= idle;
       else
           state_reg <= state_next;
		  
    // FSM control
    always @*
        begin
        state_next = state_reg;
        b2b_start = 1'b0;
		
        case (state_reg)
            idle:
                 if (start)
                    begin
                    b2b_start = 1'b1;  // assert start line to bcd2bin circuit
                    state_next = b2b;  
		    end
            b2b:
                if (b2b_done_tick)       // once bcd2bin conversion done, go back to idle
                   state_next = idle;
        endcase
        end
endmodule 
