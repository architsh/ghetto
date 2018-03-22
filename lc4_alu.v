/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/

      wire [15:0] newrem1;
      wire [15:0] newrem2;
      wire [15:0] newrem3;
      wire [15:0] newrem4;
      wire [15:0] newrem5;
      wire [15:0] newrem6;
      wire [15:0] newrem7;
      wire [15:0] newrem8;

      airth a(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem1));
      logic l(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem2));
      const c(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem3));
      nop n(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem4));
      js j(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem5));
      jm j1(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem6));
      cmp p(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem7));
      shift s(.i_insn(i_insn), .i_pc(i_pc), .i_r1data(i_r1data),.i_r2data(i_r2data), .o_result(newrem8));

      wire [5:0] imm6 = i_insn[5:0];
      wire [15:0] sext_imm6 = {{10{imm6[5]}}, {imm6}};

      assign o_result = (i_insn[15:12] == 4'b0001) ?  newrem1 : (i_insn[15:12] == 4'b0101) ? newrem2 : (i_insn[15:12] == 4'b1001) ? newrem3 : (i_insn[15:12] == 4'b0000) ? newrem4 : (i_insn[15:12] == 4'b0110) ? i_r1data + sext_imm6 : (i_insn[15:12] == 4'b0111) ? i_r1data + sext_imm6 : (i_insn[15:12] == 4'b1000) ? i_r1data : (i_insn[15:12] == 4'b0100) ? newrem5 : (i_insn[15:12] == 4'b1100) ? newrem6 : (i_insn[15:12] == 4'b1111) ? (16'h8000 | i_insn[7:0]) : (i_insn[15:12] == 4'b1101) ? (i_r1data & 16'hFF | (i_insn[7:0] << 8)) : (i_insn[15:12] == 4'b0010) ? newrem7 : (i_insn[15:12] == 4'b1010) ? newrem8 : 16'b0;


      /***(i_insn[15:12] = 4'b0001) ? airth : (i_insn[15:12] = 4'b0010) ? cmp : (i_insn[15:12] = 4'b0100) ? jsr : (i_insn[15:12] = 4'b0110) ? ldr : (i_insn[15:12] = 4'b0111) ? str : (i_insn[15:12] = 4'b1000) ? rti : (i_insn[15:12] = 4'b1001) ? const : (i_insn[15:12] = 4'b1010) ? shift : (i_insn[15:12] = 4'b1100) ? jmp : (i_insn[15:12] = 4'b1101) ? hicon : (i_insn[15:12] = 4'b1111) ? trap : 16'd0;***/

endmodule

module airth(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [15:0] newwire;
      wire [15:0] newwire1;
      wire [4:0] imm5 = i_insn[4:0];

      wire [15:0] sext_imm5 = {{11{imm5[4]}}, {imm5}};

      lc4_divider d(.i_dividend(i_r1data),.i_divisor(i_r2data),.o_remainder(newwire1),.o_quotient(newwire));

      assign o_result = (i_insn[5:3] == 3'b000) ? (i_r1data + i_r2data) : (i_insn[5:3] == 3'b001) ? (i_r1data * i_r2data) : (i_insn[5:3] == 3'b010) ? (i_r1data - i_r2data) : (i_insn[5:3] == 3'b011) ? newwire : (i_insn[5] == 1'b1) ? (i_r1data + sext_imm5) : 16'b0 ;

endmodule

module logic(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [15:0] newwire;
      wire [15:0] newwire1;
      wire [4:0] imm5 = i_insn[4:0];
      
      wire [15:0] sext_imm5 = {{11{imm5[4]}}, {imm5}};

      assign o_result = (i_insn[5:3] == 3'b000) ? (i_r1data & i_r2data) : (i_insn[5:3] == 3'b001) ? (~i_r1data) : (i_insn[5:3] == 3'b010) ? (i_r1data | i_r2data) : (i_insn[5:3] == 3'b011) ? (i_r1data ^ i_r2data) : (i_insn[5] == 1'b1) ? (i_r1data & sext_imm5) : 16'b0;

endmodule

module const(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [8:0] imm9 = i_insn[8:0];
      
      wire [15:0] sext_imm9 = {{7{imm9[8]}}, {imm9}};

      assign o_result = sext_imm9;

endmodule

module nop(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [8:0] imm9 = i_insn[8:0];
      
      wire [15:0] sext_imm9 = {{7{imm9[8]}}, {imm9}};

      assign o_result = (i_insn[11:9] == 3'b000) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b001) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b010) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b011) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b100) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b101) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b110) ? (i_pc + 1) + sext_imm9 : (i_insn[11:9] == 3'b111) ? (i_pc + 1) + sext_imm9 : 16'b0;

endmodule

module js(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [10:0] imm11 = i_insn[10:0];
      
      wire [15:0] sext_imm11 = {{5{imm11[10]}}, {imm11}};

      assign o_result = (i_insn[11] == 1'b0) ? i_r1data : (i_insn[11] == 1'b1) ? (i_pc & 16'h8000) | (imm11 << 4) : 16'b0;

endmodule

module jm(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [10:0] imm11 = i_insn[10:0];
      
      wire [15:0] sext_imm11 = {{5{imm11[10]}}, {imm11}};

      assign o_result = (i_insn[11] == 1'b0) ? i_r1data : (i_insn[11] == 1'b1) ? (i_pc + 1 + sext_imm11) : 16'b0;

endmodule

module cmp(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [6:0] imm7 = i_insn[6:0];
      
      wire [15:0] sext_imm7 = {{10{imm7[6]}}, {imm7}};

      assign o_result = (i_insn[8:7] == 2'b00) ? (($signed(i_r1data)<$signed(i_r2data)) ? 16'b1111111111111111 : ($signed(i_r1data)>$signed(i_r2data)) ? 16'b1 : 16'b0) : (i_insn[8:7] == 2'b10) ? (($signed(i_r1data)<$signed(imm7)) ? 16'b1111111111111111 : ($signed(i_r1data)>$signed(imm7)) ? 16'b1 : 16'b0) : (i_insn[8:7] == 2'b01) ? (((i_r1data)<(i_r2data)) ? 16'b1111111111111111 : ((i_r1data)>(i_r2data)) ? 16'b1 : 16'b0) : (i_insn[8:7] == 2'b11) ? (((i_r1data)<(imm7)) ? 16'b1111111111111111 : ((i_r1data)>(imm7)) ? 16'b1 : 16'b0) : 16'b0;

endmodule

module shift(input  wire [15:0] i_insn,
           	input wire [15:0]  i_pc,
          	input wire [15:0]  i_r1data,
           	input wire [15:0]  i_r2data,
           	output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/	

      wire [15:0] newwire;
      wire [15:0] newwire1;

      wire [3:0] imm4 = i_insn[3:0];
      
      wire [15:0] sext_imm4 = {{13{imm4[3]}}, {imm4}};

      lc4_divider d(.i_dividend(i_r1data),.i_divisor(i_r2data),.o_remainder(newwire1),.o_quotient(newwire));

      wire signed [15:0] new;

      assign new = $signed(i_r1data)>>>imm4;      

      assign o_result = (i_insn[5:4] == 2'b00) ? i_r1data << imm4 : (i_insn[5:4] == 2'b10) ? i_r1data >> imm4 : (i_insn[5:4] == 2'b11) ? newwire1 : (i_insn[5:4] == 2'b01) ? (new)  : 16'b0;

endmodule
