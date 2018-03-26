/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************/

    // pc stuff here ....................
    //assign pc = 16'b0; //program counter....................not sure if we shoudl initialize pc to 0
    assign o_cur_pc = pc;
    assign test_cur_pc = pc;
    wire [15:0] pc_plus_one;
    
    plus_one p0 (.pc(pc), .pc_plus_one(pc_plus_one));


    assign test_cur_insn = i_cur_insn;

    // output wires from decoder
    wire [2:0] r1sel;
    wire r1re;      
    wire [2:0] r2sel;
    wire r2re;
    wire [2:0] wsel;
    wire regfile_we;
    wire nzp_we;
    wire select_pc_plus_one;
    wire is_load;
    wire is_store;
    wire is_branch;
    wire is_control_insn;



    // decoder
    lc4_decoder d0 (.insn(i_cur_insn), .r1sel(r1sel), .r1re(r1re), .r2sel(r2sel), .r2re(r2re), .wsel(wsel), .regfile_we(regfile_we), .nzp_we(nzp_we), .select_pc_plus_one(select_pc_plus_one), .is_load(is_load), .is_store(is_store), .is_branch(is_branch), .is_control_insn(is_control_insn));
    //  test outputs
    assign test_regfile_wsel = wsel;
    assign test_regfile_we = regfile_we;
    assign test_nzp_we = nzp_we;


    // output wires from regfile
    wire [15:0] o_rs_data;
    wire [15:0] o_rt_data;
    // regfile
    lc4_regfile r0 (.clk(clk), .gwe(gwe), .rst(rst), .i_rs(r1sel), .o_rs_data(o_rs_data), .i_rt(r2sel), .o_rt_data(o_rt_data), .i_rd(wsel), .i_wdata(i_wdata), .i_rd_we(regfile_we));



    //  output wire from ALU
    wire[15:0] o_result; //alu output
    wire [15:0] int_mux;

    assign o_dmem_towrite = (is_store == 1'b0) ?1'b0 :o_rt_data;

    // ALU
    lc4_alu a0 (.i_insn(i_cur_insn), .i_pc (pc), .i_r1data(o_rs_data), .i_r2data(o_rt_data), .o_result(o_result));     


    assign int_mux = (is_load) ? i_cur_dmem_data : 16'b0;

    assign test_dmem_data= (is_store == 1'd0) ? int_mux : o_dmem_towrite;

    wire [15:0] int_reg_mux;
    wire [15:0] i_wdata;

    assign int_reg_mux = (select_pc_plus_one == 3'd0) ? o_result : pc_plus_one;
    assign i_wdata = (is_load == 3'd0) ? int_reg_mux : i_cur_dmem_data;
    
    
   // mux2to1_16bit mux2 (.i_r(select_pc_plus_one), .r0v(o_result), .r1v(pc_plus_one), .o_data(int_reg_mux));
   // mux2to1_16bit mux3 (.i_r(is_load), .r0v(int_reg_mux), .r1v(i_cur_dmem_data), .o_data(i_wdata));
    
   
    // outputs to data module
    assign o_dmem_we = is_store;
    assign o_dmem_addr  = ((is_store | is_load) == 1'b0)? 1'b0:o_result;
    
    

    
    

    // test outputs
    assign test_dmem_we = o_dmem_we;
    assign test_dmem_addr = o_dmem_addr;

    assign test_regfile_data = i_wdata;


    // NZP output
    wire [2:0] nzp_out;
    // NZP
    //assign test_nzp_new_bits = nzp_out;

    nzp n0 (nzp_we, i_wdata, nzp_out, clk, gwe, rst, test_nzp_new_bits);

    
    // branch output
    //wire [15:0] next_pc;
    // branch     
    branch b0 (.pc_plus_one(pc_plus_one), .i_cur_insn(i_cur_insn), .nzp_out(nzp_out), .o_result(o_result), .is_branch(is_branch), .is_control_insn(is_control_insn), .next_pc(next_pc));

    //assign pc = next_pc;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("time-> %d, o_dmem_addr ->%h, o_dmem_towrite -> %h, pc->%h,  i_cur_insn-> %h, o_result->%h", $time, o_dmem_addr, o_dmem_towrite, pc, i_cur_insn, o_result);

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
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      $display();
   end
`endif
endmodule


module mux2to1_16bit
   (input wire i_r,
    input wire [15:0] r0v,
    input wire [15:0] r1v,
    output wire [15:0] o_data
    );
    assign o_data = (i_r == 3'd0) ? r0v : r1v;
endmodule


module plus_one(input  wire [15:0] pc,
                output wire [15:0] pc_plus_one);

      /*** YOUR CODE HERE ***/

      assign pc_plus_one = pc + 16'b1;

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
