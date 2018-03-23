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
   
   // in to D reg
   wire [15:0] f_pc;
   wire [15:0] i_curr_insn;
   wire [15:0] pc_plus_one;
   
   // out of D reg
   wire [15:0] d_pc;
   wire [15:0] d_i_curr_insn;
   wire [15:0] d_pc_plus_one;
   
   // D register
   Nbit_reg #(16, 16'h0000) d_pc_reg (.in(f_pc), .out(d_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) d_insn_reg (.in(i_curr_insn), .out(d_i_curr_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) d_pc_plus_one_reg (.in(pc_plus_one), .out(d_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
   
   // Decoder
   wire [2:0] d_r1sel;
   wire d_r1re;
   wire [2:0] d_r2sel;
   wire d_r2re;
   wire [2:0] d_wsel;
   wire d_regfile_we;
   wire d_nzp_we;
   wire d_select_pc_plus_one;
   wire d_is_store;
   wire d_is_load;
   wire d_is_branch;
   wire d_is_control_insn;
   wire d_alu_src = ~d_r2re;
   // decoder module
   lc4_decoder decoder(.insn(d_insn), .r1sel(d_r1sel), .r1re(d_r1re), .r2sel(d_r2sel), .r2re(d_r2re), .wsel(d_wsel), 
   .regfile_we(d_regfile_we), .nzp_we(d_nzp_we), .select_pc_plus_one(d_select_pc_plus_one), .is_load(d_is_load), .is_store(d_is_store), 
   .is_branch(d_is_branch), is_control_insn.(d_is_control_insn));
   
   
   // Regfile
   wire [15:0] d_rs_out;
   wire [15:0] d_rt_out;
   lc4_regfile #(16) regfile(.clk(clk), .gwe(gwe), .rst(rst), .i_rs(d_r1sel), .o_rs_data(d_rs_out), 
   .i_rt(d_r2sel), .o_rt_data(d_rt_out), .i_rd(w_wsel), .i_wdata(w_rd_data), .i_rd_we(w_regfile_we));
   
   
   // r1 and r2 results
   wire [15:0] d_r1_result;
   wire [15:0] d_r2_result;
   wire w_wsel_eq_d_r1sel;
   wire w_wsel_eq_d_r2sel;
   assign w_wsel_eq_d_r1sel (d_r1sel == w_wsel) ? 1'b1 : 1'b0;
   assign w_wsel_eq_d_r2sel (d_r2sel == w_wsel) ? 1'b1 : 1'b0;
   assign d_r1_result (w_wsel_eq_d_r1sel) ? w_rd_data : d_rs_out;
   assign d_r2_result (w_wsel_eq_d_r2sel) ? w_rd_data : d_rt_out;

   
   // Stall
   wire x_wsel_eq_d_r1sel;
   wire x_wsel_eq_d_r2sel;
   assign x_wsel_eq_d_r1sel (d_r1sel == x_wsel) ? 1'b1 : 1'b0;
   assign x_wsel_eq_d_r2sel (d_r2sel == x_wsel) ? 1'b1 : 1'b0;
   wire d_is_stall = (x_wsel_eq_d_r1sel | (x_wsel_eq_r2sel & ~d_is_store)) & x_is_load;
   wire [15:0] d_insn_update;
   assign d_insn_update (d_is_stall) ? 16'b0 : d_insn;
   wire [1:0] d_stall;
   assign d_stall (d_is_stall) ? 2'b11 : ((x_pc_ctl) ? 2'b10 : (((f_pc == 16'h8200) ? 1'b1 : 1'b0) ? 2'b10 : 2'b00));
   
 
   
  
  


    // execute (s stage)


    //x register out wires
    wire [15:0] x_pc;
    wire [15:0] x_insn;
    wire [15:0] x_r1out;
    wire [15:0] x_r2out;
    wire [15:0] x_sext;
    wire [2:0] x_r1sel;
    wire [2:0] x_r2sel;
    wire [2:0] x_wsel;
    wire x_alu_src;
    wire x_regfile_we;
    wire x_nzp_we;
    wire x_is_store;
    wire x_is_load;
    wire x_is_branch;
    wire x_is_control_insn;
    wire [1:0] x_stall;
    wire x_select_pc_plus_one;
    wire [15:0] x_pc_plus_one;

    // m input wires;
    wire [15:0] x_new_insn;
    wire [15:0] o_result;
    wire [15:0] x_r2out;

    //additional wires
    wire [15:0] i_wdata;

    assign x_new_insn = x_insn;
    




     // X register 
   Nbit_reg #(16, 16'h0000) x_pc_reg (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_insn_reg (.in(d_insn_update), .out(x_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_r1out_reg (.in(d_r1_result), .out(x_r1out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_r2out_reg (.in(d_r2_result), .out(x_r2out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_r1sel_reg (.in(d_r1sel), .out(x_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_r2sel_reg (.in(d_r2sel), .out(x_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_wsel_reg (.in(d_wsel), .out(x_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  
   Nbit_reg #(16) x_regfile_we_reg (.in(d_regfile_we), .out(x_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(16) x_nzp_we_reg (.in(d_nzp_we), .out(x_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_is_store_reg (.in(d_is_store), .out(x_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_is_load_reg (.in(d_is_load), .out(x_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(16) x_is_branch_reg (.in(d_is_branch), .out(x_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(16) x_is_control_insn_reg (.in(d_is_control_insn), .out(x_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_select_pc_plus_one_reg (.in(d_select_pc_plus_one), .out(x_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_pc_plus_one_reg (.in(d_pc_plus_one), .out(x_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_alu_src_reg (.in(d_alu_src), .out(x_alu_src), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_stall_reg (.in(d_stall), .out(x_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));






    


    /**......................wires from w..........................**/

    //w_regfile_we
    //w_wsel

    /**......................wires from w..........................**/

    //m_sel
    //m_refile_we




    // test outputs
    //assign test_dmem_we = o_dmem_we;
    //assign test_dmem_addr = o_dmem_addr;

    //assign test_regfile_data = i_wdata;
    assign i_wdata = w_rd_data;


    // NZP output
    wire [2:0] nzp_out;
    // NZP
    //assign test_nzp_new_bits = nzp_out;

    nzp n0 (x_nzp_we, i_wdata, nzp_out, clk, gwe, rst, test_nzp_new_bits);

    
    // branch output
    wire [15:0] x_next_pc;


    // branch     
    branch b0 (.pc_plus_one(pc_plus_one), .i_cur_insn(x_insn), .nzp_out(nzp_out), .o_result(o_result), .is_branch(x_is_branch), .is_control_insn(x_is_control_insn), .next_pc(x_next_pc));


    //x bypass logic

    wire [1:0] x_bypass_logic1;
    wire [1:0] x_bypass_logic2;

    x_bypass_l b0 (.x_rsel(x_r1sel), .m_wsel(m_wsel), .w_wsel(w_wsel), .m_regfile_we(m_regfile_we), .w_regfile_we(w_regfile_we), .x_bypass_logic(x_bypass_logic1));
    x_bypass_l b0 (.x_rsel(x_r2sel), .m_wsel(m_wsel), .w_wsel(w_wsel), .m_regfile_we(m_regfile_we), .w_regfile_we(w_regfile_we), .x_bypass_logic(x_bypass_logic2));



    //after by mux


    wire [15:0] alu_in1;
    wire [15:0] alu_in2;

    wire [15:0] sign_ext;

    assign sign_ext = (x_alu_out == 1'b0) ? x_r2out : x_insn;
    ////////////^^ could be d_insn

    assign alu_in1 = (x_bypass_logic1 == 2'b00) ? x_r1out : (x_bypass_logic1 == 2'b01) ? m_addr : (x_bypass_logic1 == 2'b10) ? i_wdata : 16'b0;

    assign alu_in1 = (x_bypass_logic1 == 2'b00) ? sign_ext : (x_bypass_logic1 == 2'b01) ? m_addr : (x_bypass_logic1 == 2'b10) ? i_wdata : 16'b0;

    wire [15:0] x_r2out_new = sign_ext;


    // ALU // used o_reult instead of x_alu_out
    lc4_alu a0 (.i_insn(x_insn), .i_pc (x_pc), .i_r1data(alu_in1), .i_r2data(alu_in2), .o_result(o_result));     












    //memory phase
    wire [15:0] m_pc;
    wire [15:0] m_insn;
    wire [15:0] m_addr;
    wire [15:0] m_mem_to_write;
    wire [2:0] m_r2sel;
    wire [2:0] m_wsel;
    wire m_regfile_we;
    wire m_nzp_we;
    wire m_is_store;
    wire m_is_load;
    wire [1:0] m_stall;

   
    

    wire m2;
    wire [15:0] m_addr_to_write;

    assign m2 = m_is_store | m_is_load;
    assign m_addr_to_write = (m2 == 1'b 0) ? m_addr : 16'h0000;

    assign o_dmem_addr = m_addr_to_write;
    





















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


module x_bypass_l(input  wire [2:0] x_rsel,
            input  wire [2:0] m_wsel,
            input  wire [2:0] w_wsel,
            input  wire m_regfile_we,
            input  wire w_regfile_we,
            output wire [1:0] x_bypass_logic);

      /*** YOUR CODE HERE ***/

      wire w1, w2, w3, w4;

      assign w1 = (x_rsel == m_wsel) ?  1'b1 : 1'b0;

      assign w2 = (x_rsel == w_wsel) ?  1'b1 : 1'b0;

      assign w3 = w1 & m_regfile_we;

      assign w4 = w2 & w_regfile_we;

      assign x_bypass_logic = ((w3 == 1'b0) & (w4 ==1'b0)) ? 2'b00 : ((w3 == 1'b0) & (w4 ==1'b1)) ? 2'b01 : ((w3 == 1'b1) & (w4 ==1'b0)) ? 2'b10 : 2'b11;

endmodule