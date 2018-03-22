/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/


  



















   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule









module nzp(input  wire nzp_we,
          input  wire [15:0] i_wdata,
          output wire [2:0] nzp_out,
          input  wire         clk,
          input  wire         gwe,
          input  wire         rst,
          input  wire [2:0] test_nzp_new_bits
          );

      /*** YOUR CODE HERE ***/

      wire result_z;
      wire [2:0] nzp_inter;
      wire [2:0] nzp_in;

      assign nzp_inter = (i_wdata[15] == 3'd0) ? 3'b001 : 3'b100;

      assign result_z = (i_wdata == 16'b0);

      assign nzp_in = (result_z == 3'd0) ? nzp_inter : 3'b010;

      assign test_nzp_new_bits = nzp_in;

      Nbit_reg #(3) r00 (.out(nzp_out), .in(nzp_in), .we(nzp_we), .rst(rst), .clk(clk), .gwe(gwe));


endmodule

module branch(input  wire [15:0] pc_plus_one,
            input  wire [15:0] i_cur_insn,
            input  wire [2:0] nzp_out,
            input  wire [15:0] o_result,
            input  wire is_branch,
            input  wire is_control_insn,
            output wire [15:0] next_pc);

      /*** YOUR CODE HERE ***/

      wire match_out;

      wire mux6_in;

      assign match_out = ((nzp_out == 3'b100) & i_cur_insn[11]) | ((nzp_out == 3'b010) & i_cur_insn[10]) | ((nzp_out == 3'b001) & i_cur_insn[9]);

      assign mux6_in = (match_out & is_branch) | (is_control_insn);

      assign next_pc = (mux6_in == 3'd0) ? pc_plus_one : o_result;

endmodule
