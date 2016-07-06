module uart_rx
	(
		input wire clk, reset,
		input wire rx, baud_tick,   // input rx line, and 16*baudrate tick 
		output reg rx_done_tick,    // receiver done tick
		output wire [7:0] rx_data   // received data
	);
	
	// symbolic state declarations for FSMD
	localparam [1:0]
		idle  = 2'b00,	// idle state, waiting for rx to go low (start bit)
		start = 2'b01,	// start state, count for 8 baud_ticks
		data  = 2'b10,  // data state, shift in 8 data bits
		stop  = 2'b11;  // stop state, count 16 baud_ticks, assert done_tick
		
	// internal signal declarations
	reg [1:0] state_reg, state_next;   // FSMD state register
	reg [4:0] baud_reg, baud_next;     // register to count baud_ticks
	reg [3:0] n_reg, n_next;           // register to count number of data bits shifted in
	reg [7:0] d_reg, d_next;           // register to hold received data
	
	// FSMD state, baud counter, data counter, and data registers
	always @(posedge clk, posedge reset)
		if (reset)
			begin
                        state_reg <= idle;
                        baud_reg  <= 0;
                        n_reg     <= 0;
                        d_reg     <= 0;
			end
		else
			begin
                        state_reg <= state_next;
                        baud_reg  <= baud_next;
                        n_reg     <= n_next;
                        d_reg     <= d_next;
			end
			
	// FSMD next state logic
	always @*
		begin
		
		// defaults
		state_next   = state_reg;
		rx_done_tick = 1'b0;
		baud_next    = baud_reg;
		n_next       = n_reg;
		d_next       = d_reg;
		
		case (state_reg)
			idle:                                       // idle, wait for rx to go low (start bit)
				if (~rx)                            // when rx goes low...
					begin
					state_next = start;         // go to start state
					baud_next  = 0;             // set baud_reg to 0
					end
					
			start:                                      // start, count 8 baud_ticks
				begin 
				if(baud_tick)
					baud_next = baud_reg + 1;   // increment baud_reg every tick 
					
				else if (baud_reg == 8)             // when baud_reg has counted to 8
					begin
					state_next = data;          // go to data state
					baud_next  = 0;             // set baud_reg and
					n_next     = 0;             // data bit count reg to 0
					end 
				end
				
			data:                                       // data, shift in 8 data bits to data reg
				begin
				if(baud_tick)
					baud_next = baud_reg + 1;   // increment baud_reg every tick  
					
				else if(baud_reg == 16)             // when baud_reg counted 16 ticks...
					begin
					d_next    = {rx, d_reg[7:1]};   // left shift in rx data to received data reg
					n_next    = n_reg + 1;          // increment data bit count
					baud_next = 0;                  // reset baud tick counter to 0
					end
					
				else if(n_reg == 8)                     // once 8 data bits have been shifted in...
					state_next = stop ;             // move to stop state
				end
				
			stop:                                           // stop, rx line is high for 16 baud_ticks (stop bit)
				begin
				if(baud_tick)
					baud_next = baud_reg + 1;       // increment baud_reg every tick 
					
				else if (baud_reg == 16)                // once 16 baud_ticks have been counted
					begin
					state_next   = idle;            // go to idle state
					rx_done_tick = 1'b1;            // assert receive done tick
					end
				end        
		endcase
		end
	
	// output received data
 	assign rx_data = d_reg; 
endmodule
