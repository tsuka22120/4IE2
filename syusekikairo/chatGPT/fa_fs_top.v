// fa_fs_top.v
// Gowin GW1NR-9 target
// 入力ピン: SW1(69)=iA, SW2(68)=iB, SW3(57)=iCy/iBr, SW4(56)=mode
// 出力ピン: LD1(10)=sum/diff (表示反転), LD2(11)=carry/borrow (表示反転)
// SW4 = 0 -> 全加算器 (FA)
// SW4 = 1 -> 全減算器 (FS)
// 表示LEDは反転表示されるため、出力を反転している。

`timescale 1ns/1ps

module ha(
    input  wire A,
    input  wire B,
    output wire S,
    output wire C
);
    // Half-adder: S = A xor B, C = A & B
    assign S = A ^ B;
    assign C = A & B;
endmodule

module fa(
    input  wire A,
    input  wire B,
    input  wire Cin,
    output wire S,
    output wire Cout
);
    // FA implemented by two HAs
    wire s1, c1, c2;
    ha ha1(.A(A), .B(B), .S(s1), .C(c1));
    ha ha2(.A(s1), .B(Cin), .S(S), .C(c2));
    assign Cout = c1 | c2;
endmodule

module hs(
    input  wire A,
    input  wire B,
    output wire D,   // difference
    output wire Br   // borrow
);
    // Half-subtractor: D = A xor B, Br = (~A) & B
    assign D  = A ^ B;
    assign Br = (~A) & B;
endmodule

module fs(
    input  wire A,
    input  wire B,
    input  wire Bin,
    output wire D,
    output wire Bout
);
    // Full subtractor implemented by two HS
    wire d1, b1, b2;
    hs hs1(.A(A), .B(B), .D(d1), .Br(b1));
    hs hs2(.A(d1), .B(Bin), .D(D),  .Br(b2)); // note: second HS subtracts Bin from d1
    assign Bout = b1 | b2;
endmodule

module fa_fs_top(
    input  wire iA,    // SW1 (pin 69)
    input  wire iB,    // SW2 (pin 68)
    input  wire iC,    // SW3 (pin 57) : carry-in or borrow-in
    input  wire mode,  // SW4 (pin 56) : 0=FA, 1=FS
    output wire LD1,   // LD1 (pin 10) : sum/diff (display inverted)
    output wire LD2    // LD2 (pin 11) : carry/borrow (display inverted)
);
    wire s_sum, c_cout;
    wire s_diff, b_bout;
    // instantiate FA and FS
    fa fa_inst(.A(iA), .B(iB), .Cin(iC), .S(s_sum), .Cout(c_cout));
    fs fs_inst(.A(iA), .B(iB), .Bin(iC), .D(s_diff), .Bout(b_bout));

    // multiplex by mode: mode==0 -> FA, mode==1 -> FS
    wire out_bit, out_flag;
    assign out_bit  = (mode == 1'b0) ? s_sum : s_diff;
    assign out_flag = (mode == 1'b0) ? c_cout : b_bout;

    // LED displays are inverted => invert signals
    assign LD1 = ~out_bit;
    assign LD2 = ~out_flag;
endmodule
