/*
 * Module: Top Module (Full Adder / Full Subtractor Switchable)
 * Device: Gowin GW1NR-9
 * Board: Tang Nano 9K (Assuming)
 */

// Half Adder
module half_adder(
    input a,
    input b,
    output s,
    output c
);
    assign s = a ^ b;
    assign c = a & b;
endmodule

// Full Adder (using 2 Half Adders)
module full_adder(
    input a,
    input b,
    input ci,
    output s,
    output co
);
    wire s1, c1, c2;
    
    half_adder HA1 (.a(a), .b(b), .s(s1), .c(c1));
    half_adder HA2 (.a(s1), .b(ci), .s(s), .c(c2));
    
    assign co = c1 | c2;
endmodule

// Half Subtractor
module half_subtractor(
    input a,
    input b,
    output d,
    output br
);
    assign d = a ^ b;
    assign br = ~a & b;
endmodule

// Full Subtractor (using 2 Half Subtractors)
module full_subtractor(
    input a,
    input b,
    input bri, // Borrow In
    output d,
    output bro // Borrow Out
);
    wire d1, br1, br2;
    
    half_subtractor HS1 (.a(a), .b(b), .d(d1), .br(br1));
    half_subtractor HS2 (.a(d1), .b(bri), .d(d), .br(br2));
    
    assign bro = br1 | br2;
endmodule

// Top Module
module top(
    input sw1, // A
    input sw2, // B
    input sw3, // Carry In / Borrow In
    input sw4, // Mode Select (0: Adder, 1: Subtractor)
    output ld1, // Sum / Diff (Active Low LED)
    output ld2  // Carry Out / Borrow Out (Active Low LED)
);
    wire fa_s, fa_c;
    wire fs_d, fs_br;
    wire result_val, result_c_br;

    // Instance of Full Adder
    full_adder FA (
        .a(sw1), .b(sw2), .ci(sw3),
        .s(fa_s), .co(fa_c)
    );

    // Instance of Full Subtractor
    full_subtractor FS (
        .a(sw1), .b(sw2), .bri(sw3),
        .d(fs_d), .bro(fs_br)
    );

    // Multiplexer based on SW4
    assign result_val = (sw4 == 1'b0) ? fa_s : fs_d;
    assign result_c_br = (sw4 == 1'b0) ? fa_c : fs_br;

    // LED Output Logic (Inverted because LED implies Active Low/Opposite display)
    assign ld1 = ~result_val;
    assign ld2 = ~result_c_br;

endmodule
