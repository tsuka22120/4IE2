module HalfAdder(iA, iB, oS, oC);
    input iA, iB;
    output oS, oC;
    assign oS = iA ^ iB;
    assign oC = iA & iB;
endmodule

module FullAdder(iA, iB, iCy, oS, oCy);
    input iA, iB, iCy;
    output oS, oCy;
    wire s1, c1, c2;
    HalfAdder HA1(.iA(iA), .iB(iB), .oS(s1), .oC(c1));
    HalfAdder HA2(.iA(s1), .iB(iCy), .oS(oS), .oC(c2));
    assign oCy = c1 | c2;
endmodule

module HalfSubtractor(iA, iB, oD, oB);
    input iA, iB;
    output oD, oB;
    assign oD = iA ^ iB;
    assign oB = ~iA & iB;
endmodule

module FullSubtractor(iA, iB, iBr, oD, oBr);
    input iA, iB, iBr;
    output oD, oBr;
    wire d1, b1, b2;
    HalfSubtractor HS1(.iA(iA), .iB(iB), .oD(d1), .oB(b1));
    HalfSubtractor HS2(.iA(d1), .iB(iBr), .oD(oD), .oB(b2));
    assign oBr = b1 | b2;
endmodule

module main(SW1, SW2, SW3, SW4, LD1, LD2);
    input SW1, SW2, SW3, SW4;
    output LD1, LD2;
    wire addS, addC;
    wire subD, subB;
    wire [1:0] addResult;
    wire [1:0] subResult;
    wire [1:0] muxResult;

    FullAdder FA(.iA(SW1), .iB(SW2), .iCy(SW3), .oS(addS), .oCy(addC));
    FullSubtractor FS(.iA(SW1), .iB(SW2), .iBr(SW3), .oD(subD), .oBr(subB));

    assign addResult = {addC, addS};
    assign subResult = {subB, subD};
    assign muxResult = SW4 ? subResult : addResult;
    assign {LD2, LD1} = ~muxResult;
endmodule