// uart controlled stopwatch
module uart_stopwatch

	( 
	  input  wire clk, reset,        // clock reset input lines
	  input  wire rx,		 // receive
	  output wire tx,		 // transmit
	  output wire [3:0] an,          // enable for 4 displays
	  output wire [7:0] sseg         // led segments

	);
	
	// internal signal declarations
	wire [3:0] d3, d2, d1, d0;              // routing connections from BCD values of minSecTimer to display and for tx to PC
	reg  [7:0] r_reg;                       // baud rate generator register
	wire [7:0] r_next;                      // baud rate generator next state logic
	wire tick;                              // baud tick for uart_rx & uart_tx
	wire [7:0] rx_data_out;                 // routing path for received ascii data 
	reg tx_start, go_sw, stop_sw, clear_sw; // registers to control minSecTimer and start tx to PC
	reg [2:0] state_reg, state_next;        // FSM state register and next state logic
	wire rx_done_tick, tx_done_tick;        // done ticks for rx and tx circuits
	reg [7:0] tx_d_next, tx_d_reg;          // register for tx output to PC

	// tx_d register for tx data to PC
	always @(posedge reset, posedge clk)
		if(reset)
			tx_d_reg <= 8'b00000000;
		else 
			tx_d_reg <= tx_d_next;
	
	// FSM states
	localparam [2:0] idle         = 3'b000,
			 transmit_d3  = 3'b001,
	                 transmit_d2  = 3'b010,
                         transmit_dot = 3'b011,
			 transmit_d1  = 3'b100,
			 transmit_d0  = 3'b101;
					 
	// FSM register
	always @(posedge reset, posedge clk)
		if(reset)
			state_reg <= idle;
		else 
			state_reg <= state_next;
	
	// FSM next state logic
	always @*
		begin
		
		// defaults
		state_next = state_reg;
		tx_d_next  = 8'b00000000;
		tx_start   = 1'b0;
		clear_sw   = 1'b0;
		go_sw      = 1'b0;
		stop_sw    = 1'b0;
		
		case(state_reg)
			idle: 
				begin
				if(rx_done_tick)  // when rx data received and ready, check value
					begin
					if(rx_data_out == 8'b01000011 || rx_data_out == 8'b01100011)       // if 'c' or 'C', enable clear_sw register to minSecTimer
						clear_sw = 1'b1;
					else if(rx_data_out == 8'b01000111 || rx_data_out == 8'b01100111)  // if 'g' or 'G', enable go_sw register to minSecTimer
						go_sw = 1'b1;
					else if(rx_data_out == 8'b01010011 || rx_data_out == 8'b01110011)  // if 's' or 'S', enable stop_sw register to minSecTimer
						stop_sw = 1'b1;
					else if(rx_data_out == 8'b01010010 || rx_data_out == 8'b01110010)  // if 'r' or 'R', load tx_d next state, go to next FSM state
						begin
						tx_d_next  = {4'b0011, d3};
						state_next = transmit_d3;
						end
				        end
				end
				
			transmit_d3:
				begin
				tx_start = 1'b1;                    // begin sending data across tx
				if(tx_done_tick)                    // when done
					begin
					tx_d_next  = {4'b0011, d2}; // load next data
					state_next = transmit_d2;   // go to next state
					end
				end
				
			transmit_d2:
				begin
				tx_start = 1'b1;
				if(tx_done_tick)
					begin
					tx_d_next  = 8'b00101110;
					state_next = transmit_dot;
					end
				end
			
			transmit_dot:
				begin
				tx_start = 1'b1;
				if(tx_done_tick)
					begin
					tx_d_next  = {4'b0011, d1};
					state_next = transmit_d1;
					end
				end
				
			transmit_d1:
				begin
				tx_start = 1'b1;
				if(tx_done_tick)
					begin
					tx_d_next  = {4'b0011, d0};
					state_next = transmit_d0;
					end
				end
				
			transmit_d0:
				begin
				tx_start = 1'b1;       
				if(tx_done_tick)           // when final tx data is sent
					state_next = idle;     // go back to idle
				end
			endcase
			end					
	
	// register for oversampling baud rate generator
	always @(posedge clk, posedge reset)
		if(reset)
			r_reg <= 0;
		else
			r_reg <= r_next;
	
	// next state logic, mod 163 counter
	assign r_next = r_reg == 163 ? 0 : r_reg + 1;
	
	// tick high once every 163 clock cycles, for 19200 baud
	assign tick = r_reg == 163 ? 1 : 0;
	
	
	// instantiate uart rx ciruit
	uart_rx uart_rx_unit (.clk(clk), .reset(reset), .rx(rx), .baud_tick(tick), .rx_done_tick(rx_done_tick), .rx_data(rx_data_out));
	
	// instantiate uart tx circuit
	uart_tx uart_tx_unit (.clk(clk), .reset(reset), .tx_start(tx_start), .baud_tick(tick), .tx_data(tx_d_reg), .tx_done_tick(tx_done_tick), .tx(tx));
	
	// instantiate stopwatch timer circuit
	minSecTimer timer (.clk(clk), .go(go_sw), .stop(stop_sw), .clr(clear_sw), .d3(d3), .d2(d2), .d1(d1), .d0(d0));
	
	// instantiate seven segment display circuit
	displayMuxBasys display_unit (.clk(clk), .hex3(d3), .hex2(d2), .hex1(d1), .hex0(d0), .dp_in(4'b1011), .an(an), .sseg(sseg));
	
endmodule 
