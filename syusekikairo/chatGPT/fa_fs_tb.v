// fa_fs_tb.v
`timescale 1ns/1ps
module fa_fs_tb;
    reg A, B, C, mode;
    wire LD1, LD2;
    // Instantiate DUT
    fa_fs_top dut(.iA(A), .iB(B), .iC(C), .mode(mode), .LD1(LD1), .LD2(LD2));

    integer i;
    reg [2:0] vec;
    initial begin
        $dumpfile("fa_fs_tb.vcd");
        $dumpvars(0, fa_fs_tb);
        $display("time\t mode A B C | LD1(sum/diff_inv) LD2(carry/borrow_inv) | real_out sum/diff carry/borrow");
        $display("--------------------------------------------------------------------------");
        for (mode = 0; mode <= 1; mode = mode + 1) begin
            for (i = 0; i < 8; i = i + 1) begin
                vec = i;
                A = vec[2];
                B = vec[1];
                C = vec[0];
                #5;
                // LD outputs are inverted on hardware, so real outputs are inverted-back:
                $display("%g\t  %b   %b %b %b |  %b                %b            |  %b",
                         $time, mode, A, B, C, LD1, LD2, 1'b0);
                // For clarity, also print computed expected values:
                if (mode == 0) begin
                    // FA expected
                    $display("  (FA) A=%b B=%b Cin=%b => Sum=%b Cout=%b (LD shows inverted).",
                        A,B,C, (A ^ B) ^ C, ((A & B) | ((A ^ B) & C)));
                end else begin
                    // FS expected: Difference = A ^ B ^ Bin ; Borrow = ((~A)&B) | (((~(A ^ B)) & C))
                    reg diff;
                    reg bout;
                    diff = (A ^ B) ^ C;
                    bout = ((~A) & B) | (((~(A ^ B)) & C));
                    $display("  (FS) A=%b B=%b Bin=%b => Diff=%b Bout=%b (LD shows inverted).",
                        A,B,C, diff, bout);
                end
            end
        end
        #10;
        $finish;
    end
endmodule
