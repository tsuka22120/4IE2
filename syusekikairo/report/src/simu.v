`timescale 1ns/1ps

module main_tb;
    reg SW1, SW2, SW3, SW4;
    wire LD1, LD2;
    
    // Instantiate the main module
    main uut (
        .SW1(SW1),
        .SW2(SW2),
        .SW3(SW3),
        .SW4(SW4),
        .LD1(LD1),
        .LD2(LD2)
    );
    
    initial begin
        $dumpfile("t_main.vcd");
        $dumpvars(0, main_tb);
        
        // Test Full Adder (SW4 = 0)
        $display("Testing Full Adder (SW4=0)");
        SW4 = 0;
        
        // Test case 1: 0 + 0 + 0 = 00
        SW1 = 0; SW2 = 0; SW3 = 0;
        #10 $display("FA: %b + %b + %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 2: 1 + 0 + 0 = 01
        SW1 = 1; SW2 = 0; SW3 = 0;
        #10 $display("FA: %b + %b + %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 3: 1 + 1 + 0 = 10
        SW1 = 1; SW2 = 1; SW3 = 0;
        #10 $display("FA: %b + %b + %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 4: 1 + 1 + 1 = 11
        SW1 = 1; SW2 = 1; SW3 = 1;
        #10 $display("FA: %b + %b + %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test Full Subtractor (SW4 = 1)
        $display("\nTesting Full Subtractor (SW4=1)");
        SW4 = 1;
        // Test case 5: 0 - 0 - 0 = 00
        SW1 = 0; SW2 = 0; SW3 = 0;
        #10 $display("FS: %b - %b - %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 6: 1 - 0 - 0 = 01
        SW1 = 1; SW2 = 0; SW3 = 0;
        #10 $display("FS: %b - %b - %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 7: 1 - 1 - 0 = 00
        SW1 = 1; SW2 = 1; SW3 = 0;
        #10 $display("FS: %b - %b - %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        // Test case 8: 0 - 1 - 0 = 11 (borrow)
        SW1 = 0; SW2 = 1; SW3 = 0;
        #10 $display("FS: %b - %b - %b = %b%b (LEDs: LD2=%b LD1=%b)", 
                     SW1, SW2, SW3, ~LD2, ~LD1, LD2, LD1);
        
        #10 $finish;
    end
endmodule