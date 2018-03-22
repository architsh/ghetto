/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      
      
      wire [15:0] divout0;
      wire [15:0] remout0;
      wire [15:0] quoout0;
      wire [15:0] divout1, remout1, quoout1;
      wire [15:0] divout2, remout2, quoout2;
      wire [15:0] divout3, remout3, quoout3;
      wire [15:0] divout4, remout4, quoout4;
      wire [15:0] divout5, remout5, quoout5;
      wire [15:0] divout6, remout6, quoout6;
      wire [15:0] divout7, remout7, quoout7;
      wire [15:0] divout8, remout8, quoout8;    
      wire [15:0] divout9, remout9, quoout9;
      wire [15:0] divout10, remout10, quoout10;
      wire [15:0] divout11, remout11, quoout11;
      wire [15:0] divout12, remout12, quoout12;
      wire [15:0] divout13, remout13, quoout13;
      wire [15:0] divout14, remout14, quoout14;
      wire [15:0] divout15;

      // do the divisor = 0 part
      

      lc4_divider_one_iter d0(.i_dividend(i_dividend), .i_divisor(i_divisor), .i_remainder(16'b0), .i_quotient(16'b0), .o_dividend(divout0), .o_remainder(remout0), .o_quotient(quoout0));
      lc4_divider_one_iter d1(.i_dividend(divout0), .i_divisor(i_divisor), .i_remainder(remout0), .i_quotient(quoout0), .o_dividend(divout1), .o_remainder(remout1), .o_quotient(quoout1));
      lc4_divider_one_iter d2(.i_dividend(divout1), .i_divisor(i_divisor), .i_remainder(remout1), .i_quotient(quoout1), .o_dividend(divout2), .o_remainder(remout2), .o_quotient(quoout2));
      lc4_divider_one_iter d3(.i_dividend(divout2), .i_divisor(i_divisor), .i_remainder(remout2), .i_quotient(quoout2), .o_dividend(divout3), .o_remainder(remout3), .o_quotient(quoout3));
      lc4_divider_one_iter d4(.i_dividend(divout3), .i_divisor(i_divisor), .i_remainder(remout3), .i_quotient(quoout3), .o_dividend(divout4), .o_remainder(remout4), .o_quotient(quoout4));
      lc4_divider_one_iter d5(.i_dividend(divout4), .i_divisor(i_divisor), .i_remainder(remout4), .i_quotient(quoout4), .o_dividend(divout5), .o_remainder(remout5), .o_quotient(quoout5));
      lc4_divider_one_iter d6(.i_dividend(divout5), .i_divisor(i_divisor), .i_remainder(remout5), .i_quotient(quoout5), .o_dividend(divout6), .o_remainder(remout6), .o_quotient(quoout6));
      lc4_divider_one_iter d7(.i_dividend(divout6), .i_divisor(i_divisor), .i_remainder(remout6), .i_quotient(quoout6), .o_dividend(divout7), .o_remainder(remout7), .o_quotient(quoout7));
      lc4_divider_one_iter d8(.i_dividend(divout7), .i_divisor(i_divisor), .i_remainder(remout7), .i_quotient(quoout7), .o_dividend(divout8), .o_remainder(remout8), .o_quotient(quoout8));
      lc4_divider_one_iter d9(.i_dividend(divout8), .i_divisor(i_divisor), .i_remainder(remout8), .i_quotient(quoout8), .o_dividend(divout9), .o_remainder(remout9), .o_quotient(quoout9));
      lc4_divider_one_iter d10(.i_dividend(divout9), .i_divisor(i_divisor), .i_remainder(remout9), .i_quotient(quoout9), .o_dividend(divout10), .o_remainder(remout10), .o_quotient(quoout10));
      lc4_divider_one_iter d11(.i_dividend(divout10), .i_divisor(i_divisor), .i_remainder(remout10), .i_quotient(quoout10), .o_dividend(divout11), .o_remainder(remout11), .o_quotient(quoout11));
      lc4_divider_one_iter d12(.i_dividend(divout11), .i_divisor(i_divisor), .i_remainder(remout11), .i_quotient(quoout11), .o_dividend(divout12), .o_remainder(remout12), .o_quotient(quoout12));
      lc4_divider_one_iter d13(.i_dividend(divout12), .i_divisor(i_divisor), .i_remainder(remout12), .i_quotient(quoout12), .o_dividend(divout13), .o_remainder(remout13), .o_quotient(quoout13));
      lc4_divider_one_iter d14(.i_dividend(divout13), .i_divisor(i_divisor), .i_remainder(remout13), .i_quotient(quoout13), .o_dividend(divout14), .o_remainder(remout14), .o_quotient(quoout14));
      lc4_divider_one_iter d15(.i_dividend(divout14), .i_divisor(i_divisor), .i_remainder(remout14), .i_quotient(quoout14), .o_dividend(divout15), .o_remainder(o_remainder), .o_quotient(o_quotient));



endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/


    wire [15:0] newrem;

    assign newrem = (i_remainder << 1) | ((i_dividend >> 15) & 16'b1);

    assign o_quotient = (i_divisor == 0) ? 16'b0 : (newrem < i_divisor) ? ((i_quotient << 1) | 16'b0) : ((i_quotient << 1) | 16'b1);

    assign o_remainder = (i_divisor == 0) ? 16'b0 : (newrem < i_divisor) ?  newrem : (newrem - i_divisor);
    assign o_dividend =  i_dividend << 1;
    
endmodule
