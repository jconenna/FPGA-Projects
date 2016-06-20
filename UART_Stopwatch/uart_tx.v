module uart_tx
	(
		input wire clk, reset,
		input wire tx_start, baud_tick,   // input to start transmitter, and 16*baudrate tick
		input wire [7:0] tx_data,         // data to transmit
		output reg tx_done_tick,          // transmit done tick
		output wire tx                    // output tx line
	);
	
	// symbolic state declarations
	localparam [1:0]
		idle  = 2'b00,	// idle state, waiting for tx_start to be asserted, load tx_data to output shift register
		start = 2'b01,	// start state, hold tx low for 16 baud ticks
		data  = 2'b10,	// transmit 8 data bits 
		stop  = 2'b11;    // stop bit, hold line high for 16 baud ticks
		
	// internal signal declarations
	reg [1:0] state_reg, state_next; // FSMD state register
	reg [4:0] baud_reg, baud_next;   // register to count baud_ticks
	reg [4:0] n_reg, n_next;         // register to count number of data bits shifted out
	reg [7:0] d_reg, d_next;         // register holds data to transmit
	reg tx_reg, tx_next;             // register to hold current state of tx line
	
	// FSMD state, baud counter, data counter, and data registers
	always @(posedge clk, posedge reset)
		if (reset)
			begin
			state_reg <= idle;
                        baud_reg  <= 0;
                        n_reg     <= 0;
                        d_reg     <= 0;
                        tx_reg    <= 1'b1;
			end
		else
			begin
                        state_reg <= state_next;
                        baud_reg  <= baud_next;
                        n_reg     <= n_next;
                        d_reg     <= d_next;
                        tx_reg    <= tx_next;
			end
	
	// FSMD next state logic
	always @*
		begin
		
		// defaults
		state_next   = state_reg;
		tx_done_tick = 1'b0;
		baud_next    = baud_reg;
		n_next       = n_reg;
		d_next       = d_reg;
		tx_next      = tx_reg;
		
		case (state_reg)
		
			idle:                                     // idle, hold tx line high, until tx_start asserted...
				begin
				tx_next = 1'b1;
				if (tx_start)                      // when tx_start input asserted
					begin
					state_next = start;        // go to start state
					baud_next  = 0;            // reset baud reg to 0
					d_next     = tx_data;      // load data to transit to data register
				        end
                                end
			
			start:                                     // start, hold line low for 16 baud_ticks 
				begin
				tx_next = 1'b0;                    // hold tx low
				
				if(baud_tick)
					baud_next = baud_reg + 1;  // increment baud_reg every tick  
					
				else if(baud_reg == 16)            // once 16 baud_ticks counted...
					begin
					state_next = data;         // go to data state
					baud_next  = 0;            // reset baud counter 
					n_next     = 0;            // and data bit counter to 0
					end
				end
			
			data:
				begin
				tx_next = d_reg[0];                // transmit LSB of data reg
				
				if(baud_tick)
					baud_next = baud_reg + 1;  // increment baud_reg every tick 
				
				else if(baud_reg == 16)            // once 16 baud_ticks counted...
					begin
					d_next    = d_reg >> 1;    // right shift data reg by 1, LSB is next bit to transfer out
					baud_next = 0;             // reset baud_tick counter
					n_next    = n_reg + 1;     // increment data bit counter
					end
				
				else if(n_reg == 8)                // once 8 data bits have been shifted out and transfered...
					state_next = stop ;        // move to stop state
				end
				
			stop:                                      // stop, hold line high for 16 baud_ticks
				begin
				tx_next = 1'b1;                    // hold tx high
				
				if(baud_tick)
					baud_next = baud_reg + 1;  // increment baud_reg every tick
					
				else if(baud_reg == 16)            // once 16 baud_ticks counted
					begin
					state_next = idle;         // go to idle state
					tx_done_tick = 1'b1;       // assert transfer done tick
					end
				end
		endcase
		end
	
	// output
	assign tx = tx_reg;
endmodule
