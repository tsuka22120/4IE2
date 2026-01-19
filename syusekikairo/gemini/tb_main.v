`timescale 1ns / 1ps

module tb_top;

    // Inputs
    reg sw1;
    reg sw2;
    reg sw3;
    reg sw4;

    // Outputs
    wire ld1;
    wire ld2;

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .sw1(sw1), 
        .sw2(sw2), 
        .sw3(sw3), 
        .sw4(sw4), 
        .ld1(ld1), 
        .ld2(ld2)
    );

    initial begin
        // Initialize Inputs
        sw1 = 0; sw2 = 0; sw3 = 0; sw4 = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // ------------------------------------------------
        // Case 1: Full Adder Test (SW4 = 0)
        // ------------------------------------------------
        $display("--- Start Full Adder Test (SW4=0) ---");
        sw4 = 0;
        // Truth Table Loop
        // A(sw1), B(sw2), Cin(sw3)
        {sw1, sw2, sw3} = 3'b000; #10;
        {sw1, sw2, sw3} = 3'b001; #10;
        {sw1, sw2, sw3} = 3'b010; #10;
        {sw1, sw2, sw3} = 3'b011; #10;
        {sw1, sw2, sw3} = 3'b100; #10;
        {sw1, sw2, sw3} = 3'b101; #10;
        {sw1, sw2, sw3} = 3'b110; #10;
        {sw1, sw2, sw3} = 3'b111; #10;

        // ------------------------------------------------
        // Case 2: Full Subtractor Test (SW4 = 1)
        // ------------------------------------------------
        $display("--- Start Full Subtractor Test (SW4=1) ---");
        sw4 = 1;
        // Truth Table Loop
        // A(sw1), B(sw2), Bin(sw3)
        {sw1, sw2, sw3} = 3'b000; #10;
        {sw1, sw2, sw3} = 3'b001; #10;
        {sw1, sw2, sw3} = 3'b010; #10;
        {sw1, sw2, sw3} = 3'b011; #10;
        {sw1, sw2, sw3} = 3'b100; #10;
        {sw1, sw2, sw3} = 3'b101; #10;
        {sw1, sw2, sw3} = 3'b110; #10;
        {sw1, sw2, sw3} = 3'b111; #10;

        $finish;
    end
      
endmodule
