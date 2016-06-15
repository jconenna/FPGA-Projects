module bcd2bin_direct
   (
    input wire [3:0] bcd1, bcd0,
    output wire [6:0] bin
   );

   assign bin = (bcd1 * 4'b1010) + {3'b0, bcd0};

endmodule