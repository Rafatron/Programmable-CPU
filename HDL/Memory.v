`include "MemoryCell.v"

module Word #(parameter N=8) ( //line of cells to form a word
    input clk,
    input [N-1:0] in_word,
    input select,
    input rw,
    output wire [N-1:0] out_word
);

genvar i;
generate
    for (i=0; i<N; i = i+1) begin
        MemoryCell memcell_i(.clk(clk), .in(in_word[i]), .select(select), .rw(rw), .out(out_word[i]));
    end
endgenerate
endmodule

module Decoder4_16(
    input EN,
    input [3:0] select,
    output reg [15:0] out
);

always @(*) begin
    if (EN) begin
        out = 16'h0000;
        out[select] = 1'b1;
    end
    else begin
        out = 16'h0000;
    end
end
endmodule

module Decoder10_1024(
    input EN,
    input [9:0] select,
    output reg [1023:0] out
);

always @(*) begin
    if (EN) begin
        out = {1024{1'b0}};
        out[select] = 1'b1;
    end
    else begin
        out = {1024{1'b0}};
    end
end
endmodule

module RAM_REGISTER #(parameter N=8) (
    input clk,
    input [3:0] adress,
    input memoryEN,
    input rw,
    input [N-1:0] in_word,
    output reg [N-1:0] out_word
);

wire [15:0] wordSelect; //select
Decoder4_16 dec(.EN(memoryEN), .select(adress), .out(wordSelect));

wire [N-1:0] words[0:15]; // array of 16 elements 8 bits wide

genvar i;
generate
    for (i=0; i<16; i = i+1) begin
        Word #(N) word_i(.clk(clk), .in_word(in_word), .select(wordSelect[i]), .rw(rw), .out_word(words[i])); //all words in memory they are all active at the same time. select defines the one being outputted
    end
endgenerate

always @(posedge clk) begin : finalization //adding all the words together. assumes rw is 1. the sum is the one that is selected
    integer j;
    if (memoryEN) begin
        out_word = {N{1'b0}};
        for (j=0; j<16; j = j + 1) begin
            out_word = out_word|words[j];
        end
    end else begin
            out_word = {N{1'b0}}; 
    end
end
endmodule

module COMMAND_REGISTER #(parameter N=20) (
    input clk,
    input [9:0] adress,
    input memoryEN,
    input rw,
    input [N-1:0] in_word,
    output reg [N-1:0] out_word
);

wire [1023:0] wordSelect;
Decoder10_1024 dec(.EN(memoryEN), .select(adress), .out(wordSelect));

wire [N-1:0] words[0:1023]; // array of 16 elements 8 bits wide

genvar i;
generate
    for (i=0; i<1024; i = i+1) begin
        Word #(N) word_i(.clk(clk), .in_word(in_word), .select(wordSelect[i]), .rw(rw), .out_word(words[i]));
    end
endgenerate

always @(posedge clk) begin : finalization
    if (memoryEN) begin
        out_word = {N{1'b0}};  // Clear the output at the start (synchronous reset).
        
        // Loop through all the words to combine them
        for (integer j = 0; j < 1024; j = j + 1) begin
            out_word = out_word | words[j];  // Combine words
        end
    end else begin
        out_word = {N{1'b0}};  // Reset output to zero if not enabled
    end
end
endmodule

module MUX8 (
    input [7:0] A,
    input select,
    output reg [7:0] outA,
    output reg [7:0] outB
);

always @(*) begin
    case(select)
    1'b0: begin
        outA = A;
        outB = 0;
    end
    1'b1: begin
        outA = 0;
        outB = A;
    end
    default : begin end
    endcase
end
endmodule