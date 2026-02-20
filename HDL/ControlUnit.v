`include "Memory.v"
`include "ArithmeticLogicUnit.v"

module ControlUnit ();

reg [9:0] PC; initial PC = 10'b0;
reg COMMAND_EN = 0;
reg [19:0] in_word;
wire [19:0] directive;
reg RW_COMMAND_REGISTER;

reg [9:0] temporal_counter, temp_concat;

reg clk;
initial clk = 0;
always #10 clk = ~clk; //clock

integer file, status, i; //file reading shenanigans
integer jmp_flag, zero_flag; //flags
wire [0:0] overflow_flag = 1'b0; //more flags
reg [255:0] line;

always @(posedge clk) begin
     if (DONE_LOADING) begin
        temporal_counter <= PC;  // Always update temporal_counter to PC on every clock cycle after DONE_LOADING
    end
end

COMMAND_REGISTER ROM(.clk(clk), .adress(temporal_counter), .memoryEN(COMMAND_EN), .rw(RW_COMMAND_REGISTER), .in_word(in_word), .out_word(directive));
//MAIN ROM MEMORY

reg [19:0] LDA[0:1023];  // Array with 1024 entries (20 bits wide)
reg DONE_LOADING;

initial begin
  for (i = 0; i < 1024; i = i + 1) begin
    LDA[i] = 20'b00000000000000000000;  // Fill all entries with zero
  end
  
  // Read the file into the LDA array using $readmemb (binary format)
  $readmemb("program.lc", LDA);  // Read the binary file into LDA
end
                
initial begin
    DONE_LOADING = 0;
    RW_COMMAND_REGISTER = 0;
    COMMAND_EN = 1;
    
    for(i = 0; i < 1024 && LDA[i]!=20'b00000000000000000000; i = i + 1) begin // Assuming your ROM size is 1024
        temporal_counter = i;         // Address setup
        in_word = LDA[temporal_counter];  // Data setup
        #50;
    end
    RW_COMMAND_REGISTER = 1;
    
    DONE_LOADING = 1;
    $display("PROGRAM ROM SUCCESFULLY ATTACHED\nINITIATING PROGRAM EXECUTION");
end

//FILE HAS BEEN LOADED; TIME FOR COMMAND EXCECUTION

initial zero_flag = 0;
initial begin wait(DONE_LOADING); PC=10'b0; end
reg [7:0] ARG1, shift_register;
reg [3:0] ARG2, ARG3;

reg [3:0] address;
reg ENABLE_MEMORY, RAM_RW;
reg [7:0] MEMORY_IN;
wire [7:0] MEMORY_OUT;
RAM_REGISTER RAM(.clk(clk), .adress(address), .memoryEN(ENABLE_MEMORY), .rw(RAM_RW), .in_word(MEMORY_IN), .out_word(MEMORY_OUT));
//MAIN RAM REGISTER

reg MEMORY_SELECT;
reg [7:0] LOADED_WORD;
wire [7:0] LOADED_FOR_ALU_INPUT_A, LOADED_FOR_ALU_INPUT_B;
MUX8 dichotomy(.A(LOADED_WORD), .select(MEMORY_SELECT), .outA(LOADED_FOR_ALU_INPUT_A), .outB(LOADED_FOR_ALU_INPUT_B));
//MUX set there to load inputs from the ram into the ALU registers

reg RW_INPUT_A, RW_INPUT_B;
wire [7:0]ALU_A, ALU_B;
Word ALU_INPUT_A(.clk(clk), .in_word(LOADED_FOR_ALU_INPUT_A), .select(1'b1), .rw(RW_INPUT_A), .out_word(ALU_A)); //ALU REGISTER A
Word ALU_INPUT_B(.clk(clk), .in_word(LOADED_FOR_ALU_INPUT_B), .select(1'b1), .rw(RW_INPUT_B), .out_word(ALU_B)); //ALU REGISTER B

reg [3:0] ALU_SELECT;
wire [7:0] ALU_OUT;
ALU_8 ALU(.A(ALU_A), .B(ALU_B), .select(ALU_SELECT), .EN(1'b1), .out(ALU_OUT), .cout(overflow_flag)); // CHECK HERE OVERFLOW FLAG REMOVE WORKS. FIND WAY OVERFLOW

always begin
    wait (DONE_LOADING);
    #100;
    jmp_flag = 0;
    ARG1 = directive[15:8];
    ARG2 = directive[7:4];
    ARG3 = directive[3:0];
    case(directive[19:16])
        4'h1: begin  //  ADD

            /*enable RAM
            RAM to read mode
            load word to MUX
            select one.
            pass first value to alu A
            select two
            pass second value to alu B
            turn words from write to read
            set alu to correct operation*/

            ENABLE_MEMORY = 1; //enable memory
            RAM_RW = 1;
 
            address = ARG2; #50;      //output proper word
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0;   //load into 1
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;     //ouput second proper word
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;      // load into 2
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0001; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;

            if (overflow_flag===1'bx) $finish;
        end
        4'h2: begin  //  SUB
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0010; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;

            if (overflow_flag==1'b1) $finish;
        end
        4'h3: begin  //  AND
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0011; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'h4: begin  //   OR
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0100; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'h5: begin  //  XOR
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0101; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'h6: begin  //  NOT
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            ALU_SELECT = 4'b0110; #50;

            RAM_RW = 0;
            MEMORY_IN = ALU_OUT;
            address = ARG1;
            zero_flag = (ALU_OUT==0) ? 1 : 0;
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'h7: begin  //  MOV VAL location
            ENABLE_MEMORY = 1; //en mem
            #50;
            RAM_RW = 0; //write to mem
            MEMORY_IN = ARG1; //write arg 1
            address = ARG2; //on arg 2
            #50;
            ENABLE_MEMORY = 0; //disable mem
        end
        4'h8: begin  //  JMP
            jmp_flag = 1;
            temp_concat = {ARG1,ARG2,ARG3};
            PC = temp_concat[9:0];
            #50;
        end
        4'h9: begin  //  JPN
            jmp_flag = 1;
            temp_concat = {ARG1,ARG2,ARG3};
            PC = (zero_flag) ? temp_concat[9:0] : PC;
            #50;
        end
        4'hA: begin  // JPNZ ARGARGARG
            jmp_flag = 1;
            temp_concat = {ARG1,ARG2,ARG3};
            PC = (zero_flag) ? PC : temp_concat[9:0];
            #50;
        end
        4'hB: begin  //  CMP store A B
            ENABLE_MEMORY = 1;
            RAM_RW = 1;

            address = ARG2; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 0; 
            RW_INPUT_A = 0;
            #50; RW_INPUT_A = 1; #50;

            address = ARG3; #50;
            LOADED_WORD = MEMORY_OUT;
            #50;
            MEMORY_SELECT = 1;
            RW_INPUT_B = 0;
            #50; RW_INPUT_B = 1; #50;

            ENABLE_MEMORY = 0; #50;

            ALU_SELECT = 4'b0101; #50;

            ENABLE_MEMORY = 1; 
            #50;
            RAM_RW = 0;
            MEMORY_IN = (ALU_OUT==8'b00000000) ? 8'h01 : 8'h00;
            address = ARG1;
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'hC: begin  //  NOP
        end
        4'hD: begin  // LBSH dest memory times
            ENABLE_MEMORY = 1; #50;
            RAM_RW = 1; //read from mem

            address = ARG2; #50; //read from arg2
            temp_concat = (MEMORY_OUT << ARG3); //set temp concat to mem out
            shift_register = temp_concat[7:0]; #50; //set shift register to only the first 8 bits of temp_concat
            RAM_RW = 0; address = ARG1; //set to write and write to arg1
            MEMORY_IN = shift_register; //write the new num
            #50;
            ENABLE_MEMORY = 0;
        end
        4'hE: begin  // RBSH dest memory times
            ENABLE_MEMORY = 1; #50;
            RAM_RW = 1;

            address = ARG2; #50;
            temp_concat = (MEMORY_OUT >> ARG3);
            shift_register = temp_concat[7:0]; #50;
            RAM_RW = 0; address = ARG1;
            MEMORY_IN = shift_register;
            #50;
            ENABLE_MEMORY = 0;
        end
        4'hF: begin  // DISP memory
            ENABLE_MEMORY = 1; 
            RAM_RW = 1; #50;

            address = ARG1[3:0]; #50;
            $display("%d %b", MEMORY_OUT, MEMORY_OUT);
            #50; 
            ENABLE_MEMORY = 0;
        end
        4'h0: begin end
        default: begin end
    endcase
    PC = (jmp_flag) ? PC : (PC + 1); #50;
    if (directive==20'h00000 || PC==10'b1111111111) $finish; //HERE TOO
end
endmodule