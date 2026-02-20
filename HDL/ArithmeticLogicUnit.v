module FA(
    input A,
    input B,
    input cin,
    output out,
    output cout
);

assign out = A ^ B ^ cin; //output of the full adder
assign cout = (A & B) | (A & cin) | (B & cin); //cout of the full adder

endmodule

module ALU_1 (
    input A, //input one
    input B, //input two
    input cin, //carry in from potential other ALU unit
    input [3:0] select, // function control
    input EN, // ALU enable
    input control_first_in_series_flag, //flag to ensure that current alu is the first in the series of ALU units, regularly we would connect cout of unit n-1 to unit n and have a decoder on the first unit
    output reg cout, //carry out for potential future units
    output reg out //output of the ALU unit
);

wire result; //potential output of addition and substractioj
wire ccout; //cout to be assigned
wire default_control_flag = (control_first_in_series_flag === 1'bz) ? 1'b1 : control_first_in_series_flag; //setting control flag to zero if not given
wire ccin = (default_control_flag) ? ((select==4'b0010) ? 1'b1 : 1'b0) : cin; // if first act based on add or sub directives, else prev unit cout=cin
FA adder(.A(A), .B((select==4'b0010) ? ~B : B), .cin(ccin), .out(result), .cout(ccout)); // full adder unit inside the ALU, if sub (0010) then use ~B and CIN is 1 if first unit

always @(*) begin
    out = 0;
    cout = 0;
    if (EN) begin
        case (select) 
        4'b0001: begin 
            out = result;
            cout = ccout;
        end
        4'b0010: begin 
            out = result;
            cout = ccout;
        end
        4'b0011: begin 
            out = A&B;
            cout = 0;
        end
        4'b0100: begin
            out = A|B;
            cout = 0;
        end
        4'b0101: begin
            out = A^B;
            cout = 0;
        end
        4'b0110: begin
            out = ~A;
            cout = 0;
        end
        default: begin end
        endcase
    end
end

endmodule

module ALU_8 (
    input [7:0] A, //word one
    input [7:0] B, //word two
    input [3:0] select,
    input EN, //unit enable
    output wire [7:0] out,
    output reg [0:0] cout
);

wire [7:0] ccout;
initial cout = 0;

genvar i;
generate
    for (i=0; i<8; i=i+1) begin // enter B and A as given, the individual units will deal with the logistics. leave the first cin to be handeled by the first unit. pass the others from the previous units
        ALU_1 alu_i(.A(A[i]), .B(B[i]), .cin((i==0) ? 1'b0 : ccout[i-1]) ,.select(select), .EN(EN), .out(out[i]), .cout(ccout[i]), .control_first_in_series_flag(i==0));
    end
endgenerate

always @(*) cout = ccout[7]; //cout of the unit is the cout of the last ALU unit

endmodule