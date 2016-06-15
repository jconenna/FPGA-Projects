module reactionTimer

    (
      input wire clk,
      input wire clear, start, stop,
      output wire led,
      output wire [3:0] an,
      output wire [7:0] sseg
    );
	 

    // internal signals
    reg [5:0] random_counter_reg;       // register counts from 15 to 50
    wire [5:0] random_counter_next; 
    reg [15:0] ms_counter_reg;          // register ticks and overflows at 1 ms
    wire [15:0] ms_counter_next;
    reg [13:0] reaction_timer_reg;      // register counts number of elapsed ms up to 9999
    wire [13:0] reaction_timer_next;
    reg [28:0] countdown_timer_reg;     // register counts down from random number of seconds
    wire [28:0] countdown_timer_next;
    wire ms_tick;                       // tick from ms_counter register to reaction_timer register to increment every 1 ms
    reg ms_go;                          // register to start/stop ms_counter
    wire countdown_done;                // register with countdown done status
    reg countdown_go;                   // register to start/stop countdown_timer
    reg [1:0] state_reg, state_next;    // FSM register and next state logic
    reg bin2bcd_start;                  // start signal for binary to bcd conversion
    wire [3:0] bcd3, bcd2, bcd1, bcd0;  // signals to route from bin2bcd outputs to displaymux inputs
    reg led_state;                      // output state for reflex led
	
    // register for timers / counters
    always @(posedge clk, posedge clear)
	if(clear) // reset to 0
	  begin
	  random_counter_reg   <= 7'b0;
	  ms_counter_reg       <= 16'b0;
	  reaction_timer_reg   <= 14'b0;
	  countdown_timer_reg  <= 30'b0;
          end
        else
	  begin
	  random_counter_reg  <= random_counter_next;
	  ms_counter_reg      <= ms_counter_next;
	  reaction_timer_reg  <= reaction_timer_next; 
	  countdown_timer_reg <= countdown_timer_next;
	  end
	
    // random counter next state logic 
    // count from 15 to 50
    assign random_counter_next = (random_counter_reg < 7'b0110010) ? random_counter_reg + 1 : 7'b0001111; 
	 
    // ms counter next state logic 
    // when ms_go asserted, increment until 50000, then reset.
    assign ms_counter_next = (ms_go && ms_counter_reg < 50000) ? ms_counter_reg + 1 :  
	                     (ms_counter_reg == 50000) ? 16'b0 : ms_counter_reg;
	 
    // ms_tick upticks to reaction_timer at 50000 clock cycles, or 1 ms
    assign ms_tick = (ms_counter_reg == 50000) ? 1'b1 : 1'b0; 
	 
    // reaction timer next state logic
    // count up for every 1 ms until 9999
    assign reaction_timer_next = (ms_tick && reaction_timer_reg < 9999) ? reaction_timer_reg + 1 : reaction_timer_reg; 
	
    // countdown timer next state logic
    // when countdown_go asserted and reg not 0, decrement 1 every clock cycle,
    // if start asserted, load random number to countdown from (1.5E8 to 5E8 clock cycles, or 3s to 10s of elapsed time)	 
	 assign countdown_timer_next = (countdown_go && countdown_timer_reg > 0) ? countdown_timer_reg - 1 :
	                               start ? random_counter_reg * 10000000 : countdown_timer_reg;
	 
    // when countdown_timer is 0, assert countdown done
    assign countdown_done = (countdown_timer_reg == 0) ? 1'b1 : 1'b0;
	 
    // FSM states 
    localparam [1:0] idle   = 2'b00,  // ready to go
	             load   = 2'b01,  // load random time to countdown_reg and countdown
	             timing = 2'b10,  // turn on led, and start timing reaction
	             w2c    = 2'b11;  // led now off, reaction time stored and displayed, waiting to clear

    // FSM state register
    always @(posedge clk, posedge clear)
        if (clear)
           state_reg <= idle;
        else
           state_reg <= state_next;
	 
    // FSM control
    always @*
        begin
	// defaults
        state_next = state_reg;
        ms_go = 1'b0;
        countdown_go = 1'b0;
        bin2bcd_start = 1'b0;
        led_state = 1'b0;
		
        case (state_reg)
             idle:
		  begin 
		  if (start)                    // if start input asserted
		  state_next = load;        // transition to load state
		  end
			
	     load:
	          begin
	          countdown_go = 1'b1;           // start countdown_timer counting down
	          if (countdown_done)            // once countdown done,
	          state_next = timing;    // transition to timing state
                  end
 
            timing:
                  begin 
                  ms_go = 1'b1;               // start ms_counter counting up
		  led_state = 1'b1;           // turn on reflex led
                  if (stop)                   // if stop input asserted
		     begin
		     state_next = w2c;     // transition to w2c state
		     bin2bcd_start = 1'b1; // begin binary to bcd conversion
		     end
	          end
			
	     w2c:      // state does nothing but wait for clear input to be asserted, which in the FSM register sets state to idle
	         begin 
	         end
	endcase
	end      

    // instantiation of binary to bcd circuit, with binary output from reaction_timer register holding number of ms elapsed during reaction timer
    bin2bcd b2b_unit (.clk(clk), .reset(clear), .start(bin2bcd_start), .bin(reaction_timer_reg), .ready(), .done_tick(), .bcd3(bcd3), .bcd2(bcd2), .bcd1(bcd1), .bcd0(bcd0));
    
    // instantiation of display multiplexer circuit, routing in bcd output from bin2bcd circuit and displaying on 4 7-seg displays
    displayMuxBasys disp_unit (.clk(clk), .hex3(bcd3), .hex2(bcd2), .hex1(bcd1), .hex0(bcd0), .dp_in(4'b0111), .an(an), .sseg(sseg));	 

    assign led = led_state; // assign output state of led
	  
endmodule 
