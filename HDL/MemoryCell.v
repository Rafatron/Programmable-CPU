module SRFF (
    input EN,
    input clk,
    input S,
    input R,
    output reg out,
    output reg out_prime
);

initial begin
    out = 0;
    out_prime = 1;
end

always @(posedge clk) begin
    if (EN) begin
        case ({S,R}) 
            2'b01:  begin 
                    out = 0;
                    out_prime = 1;
            end
            2'b10:  begin
                    out = 1;
                    out_prime = 0;
            end
        endcase
    end
end
endmodule

module MemoryCell(
    input clk,
    input in,
    input select,
    input rw, //read/write 0 write 1 read
    output reg out
);

wire SR_out;
SRFF SR_unit(.EN(select), .clk(clk), .S(select & (~rw) & in), .R(select & (~rw) & (~in)), .out(SR_out));
initial out = 0;

always @(posedge clk) begin //out is read*if selected*srout
    out <= rw & select & SR_out;
end
endmodule 