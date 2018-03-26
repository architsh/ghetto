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

   // pc wires attached to the PC register's ports
   //f
   wire [15:0]   f_pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)
   wire [15:0] f_pc_plus_one;
   //d
   wire [15:0] d_pc;
   wire [15:0] d_i_cur_insn;
   wire [15:0] d_pc_plus_one;
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
   wire [15:0] i_wdata;
   wire [15:0] d_o_rs_data;
   wire [15:0] d_o_rt_data;
   wire [2:0] w_wsel;
   wire w_regfile_we;
   //x
   wire [15:0] x_pc_plus_one;
   wire [15:0] x_pc;
   wire [15:0] x_i_cur_insn;
   wire [15:0] x_o_rs_data;
   wire [15:0] x_o_rt_data;
   wire x_regfile_we;
   wire [2:0] x_r1sel;
   wire [2:0] x_r2sel;
   wire [2:0] x_wsel;
   wire x_is_store;
   wire x_is_load;
   wire x_is_branch;
   wire x_is_control_insn;
   wire x_nzp_we;
   wire [2:0]m_wsel;
   wire m_regfile_we;
   wire pd1;
   wire pd2;
   wire d1;
   wire d2;
   wire [1:0] x_bp_logic1;
   wire pd3;
   wire pd4;
   wire d3;
   wire d4;
   wire [1:0] x_bp_logic2;
   wire [15:0] m_alu_out;
   wire [15:0] alu_in1;
   wire [15:0] alu_in2;
   wire [15:0] x_alu_out;
   //m
   wire [15:0] m_pc_plus_one;
   wire [15:0] m_pc;
   wire [15:0] m_i_cur_insn;
   //wire m_regfile_we;
   wire [2:0] m_r1sel;
   wire [2:0] m_r2sel;
   wire [15:0] m_alu_in2;
   //wire [2:0] m_wsel;
   wire m_is_store;
   wire m_is_load;
   wire m_is_branch;
   wire m_is_control_insn;
   wire m_nzp_we;
   wire [15:0] m_addr;
   wire [15:0] i_dmem_towrite;
   wire mw_bp_logic;
   wire mwl;
   wire result_z;
   wire [2:0] nzp_inter;
   wire [2:0] nzp_in;
   wire [2:0] nzp_out;
   wire match_out;
   wire mux6_in;
   //w
   wire [15:0] w_pc;
   wire [15:0] w_i_cur_insn;
   wire [15:0] w_addr;
   wire [15:0] w_i_cur_dmem_data;
   //wire w_regfile_we;
   wire [2:0] w_r1sel;
   wire [2:0] w_r2sel;
   //wire [2:0] w_wsel;
   wire w_is_store;
   wire w_is_load;
   wire w_nzp_we;

   //..............................................................................................................
   //F or fetch stage register
   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) f_pc_reg (.in(next_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign f_pc_plus_one = f_pc + 16'd1;
   assign o_cur_pc = f_pc;


   //..............................................................................................................
   //D or recode stage register
   Nbit_reg #(16) d_pc_plus_one_reg (.in(f_pc_plus_one), .out(d_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_pc_reg (.in(f_pc), .out(d_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) d_i_cur_insn_reg (.in(i_cur_insn), .out(d_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //decoder module
   lc4_decoder decoder(.insn(d_i_cur_insn), .r1sel(d_r1sel), .r1re(d_r1re), .r2sel(d_r2sel), .r2re(d_r2re), .wsel(d_wsel), .regfile_we(d_regfile_we), .nzp_we(d_nzp_we), .select_pc_plus_one(d_select_pc_plus_one), .is_load(d_is_load), .is_store(d_is_store), .is_branch(d_is_branch), .is_control_insn(d_is_control_insn));
   //regfile
   lc4_regfile #(16) regfile(.clk(clk), .gwe(gwe), .rst(rst), .i_rs(d_r1sel), .o_rs_data(d_o_rs_data), 
   .i_rt(d_r2sel), .o_rt_data(d_o_rt_data), .i_rd(w_wsel), .i_wdata(i_wdata), .i_rd_we(w_regfile_we));
   
   //...............implement stall logic*********
   wire x_wsel_eq_d_r1sel;
   wire x_wsel_eq_d_r2sel;
   assign x_wsel_eq_d_r1sel = (d_r1sel == x_wsel) ? 1'b1 : 1'b0;
   assign x_wsel_eq_d_r2sel = (d_r2sel == x_wsel) ? 1'b1 : 1'b0;


   wire d_is_stall = (x_wsel_eq_d_r1sel | (x_wsel_eq_d_r2sel & ~d_is_store)) & x_is_load;
   // wire d_is_stall = 1'b0;
   wire [15:0] d_insn_update;
   assign d_insn_update = (d_is_stall) ? 16'b0 : d_i_cur_insn;
   wire [1:0] d_stall;
   //changed x_pc_ctl to mux6in.............................................................................................................................................
   assign d_stall = (d_is_stall) ? 2'b11 : ((mux6_in) ? 2'b10 : ((((f_pc == 16'h8200)|(f_pc==16'h0000)) ? 1'b1 : 1'b0) ? 2'b10 : 2'b00));


   //..............................................................................................................
   //X or execute stage register
   Nbit_reg #(16) x_pc_plus_one_reg (.in(d_pc_plus_one), .out(x_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_pc_reg (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //Nbit_reg #(16) x_i_cur_insn_reg (.in(d_i_cur_insn), .out(x_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(16) x_i_cur_insn_reg (.in(d_insn_update), .out(x_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(16) x_o_rs_data_reg (.in(d_o_rs_data), .out(x_o_rs_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(16) x_o_rt_data_reg (.in(d_o_rt_data), .out(x_o_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_regfile_we_reg (.in(d_regfile_we), .out(x_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(3) x_r1sel_reg (.in(d_r1sel), .out(x_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(3) x_r2sel_reg (.in(d_r2sel), .out(x_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(3) x_wsel_reg (.in(d_wsel), .out(x_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_store_reg (.in(d_is_store), .out(x_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_load_reg (.in(d_is_load), .out(x_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_branch_reg (.in(d_is_branch), .out(x_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_control_insn_reg (.in(d_is_control_insn), .out(x_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_nzp_we_reg (.in(d_nzp_we), .out(x_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  
   //x_bp_logic1 block
   assign pd1 = (x_r1sel == w_wsel) ? 1'b1 : 1'b0;
   assign pd2 = (x_r1sel == m_wsel) ? 1'b1 : 1'b0;
   assign d1 = pd1 & w_regfile_we;
   assign d2 = pd2 & m_regfile_we;
   assign x_bp_logic1 = ((d1 == 1'b0) & (d2 ==1'b0)) ? 2'b00 : (d1 == 1'b0) & (d2 ==1'b1) ? 2'b01 : (d1 == 1'b1) & (d2 ==1'b0) ? 2'b10 : 2'b11;
   //x_bp_logic2 block
   assign pd3 = (x_r2sel == w_wsel) ? 1'b1 : 1'b0;
   assign pd4 = (x_r2sel == m_wsel) ? 1'b1 : 1'b0;
   assign d3 = pd3 & w_regfile_we;
   assign d4 = pd4 & m_regfile_we;
   assign x_bp_logic2 = ((d3 == 1'b0) & (d4 ==1'b0)) ? 2'b00 : (d3 == 1'b0) & (d4 ==1'b1) ? 2'b01 : (d3 == 1'b1) & (d4 ==1'b0) ? 2'b10 : 2'b11;
   //................HAVENT DONE THE SIGN EXT THING***************
   //alu_in1 block
   assign alu_in1 = (x_bp_logic1 == 2'b10) ? x_o_rs_data : (x_bp_logic1 == 2'b01) ? m_alu_out : (x_bp_logic1 == 2'b00) ? i_wdata: 16'b0;
   //alu_in2 block
   assign alu_in2 = (x_bp_logic2 == 2'b10) ? x_o_rt_data : (x_bp_logic2 == 2'b01) ? m_alu_out : (x_bp_logic2 == 2'b00) ? i_wdata: 16'b0;
   //alu block
   lc4_alu a0 (.i_insn(x_i_cur_insn), .i_pc (x_pc), .i_r1data(alu_in1), .i_r2data(alu_in2), .o_result(x_alu_out));     

   //select = ((m_is_load | m_is_store) == 1'b0) ? 16'h0000 : m_alu_out;


   //branch
   assign match_out = ((nzp_out == 3'b100) & x_i_cur_insn[11]) | ((nzp_out == 3'b010) & x_i_cur_insn[10]) | ((nzp_out == 3'b001) & x_i_cur_insn[9]);
   assign mux6_in = (match_out & x_is_branch) | (x_is_control_insn);
   assign next_pc = (mux6_in == 3'd0) ? f_pc_plus_one : x_alu_out;
   // assign next_pc = d_pc_plus_one;

   //..............................................................................................................
   //M or memory stage register
   Nbit_reg #(16) m_pc_plus_one_reg (.in(x_pc_plus_one), .out(m_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_pc_reg (.in(x_pc), .out(m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_i_cur_insn_reg (.in(x_i_cur_insn), .out(m_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_alu_out_reg (.in(x_alu_out), .out(m_alu_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_regfile_we_reg (.in(x_regfile_we), .out(m_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) m_r1sel_reg (.in(x_r1sel), .out(m_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) m_r2sel_reg (.in(x_r2sel), .out(m_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_alu_in2_reg (.in(alu_in2), .out(m_alu_in2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) m_wsel_reg (.in(x_wsel), .out(m_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_store_reg (.in(x_is_store), .out(m_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_load_reg (.in(x_is_load), .out(m_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_branch_reg (.in(x_is_branch), .out(m_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_control_insn_reg (.in(x_is_control_insn), .out(m_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_nzp_we_reg (.in(x_nzp_we), .out(m_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //next pc
   assign m_addr = (d_select_pc_plus_one == 1'b0) ? m_alu_out : m_pc_plus_one;
   //mw bp logic
   assign mwl = (w_wsel == m_r2sel) ? 1'b1 : 1'b0;
   assign mw_bp_logic = mwl & m_is_store & m_is_load;
   //data mem data in
   assign i_dmem_towrite = (mw_bp_logic == 1'b0) ? m_alu_in2 : i_wdata;
   //data mem
   assign o_dmem_we = m_is_store;
   assign o_dmem_towrite = i_dmem_towrite;
   assign o_dmem_addr = ((m_is_store | m_is_load) == 1'b0)? 16'h0000:m_alu_out;
   wire [2:0] nzp;
   //nzp
   // assign nzp_inter = (i_wdata[15] == 3'd0) ? 3'b001 : 3'b100;
   // assign result_z = (i_wdata == 16'b0);
   // assign nzp_in = (result_z == 3'd0) ? nzp_inter : 3'b010;
   // assign test_nzp_new_bits = nzp_in;
   // Nbit_reg #(3) nzp_reg1 (.out(nzp_out), .in(nzp_in), .we(m_nzp_we), .rst(rst), .clk(clk), .gwe(gwe));
   // wire [2:0] nzp_inter;
   wire [2:0] nzp_inter1;
   // wire [15:0] result_z;
   wire [15:0] result_z1;
   wire [2:0] nzp_in1;
   wire [2:0] nzp_in2;
   wire [2:0] m_nzp;
   wire [2:0] nzp_sel;
   assign nzp_inter = (m_alu_out[15] == 3'd0) ? 3'b001 : 3'b100;
   assign result_z = (m_alu_out == 16'b0);
   assign nzp_in1 = (result_z == 3'd0) ? nzp_inter : 3'b010;
   Nbit_reg #(3) nzp_reg1 (.out(m_nzp), .in(nzp_in1), .we(m_nzp_we), .rst(rst), .clk(clk), .gwe(gwe));
   assign nzp_inter1 = (i_cur_dmem_data[15] == 3'd0) ? 3'b001 : 3'b100;
   assign result_z1 = (i_cur_dmem_data == 16'b0);
   assign nzp_in2 = (result_z1 == 3'd0) ? nzp_inter1 : 3'b010;
   Nbit_reg #(3) nzp_reg2 (.out(nzp_sel), .in(nzp_in2), .we(m_nzp_we), .rst(rst), .clk(clk), .gwe(gwe));
   

   //..............................................................................................................
   //W or write stage register
   Nbit_reg #(16) w_pc_reg (.in(m_pc), .out(w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) w_i_cur_insn__reg (.in(m_i_cur_insn), .out(w_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) w_addr_reg (.in(m_addr), .out(w_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) w_i_cur_dmem_data_reg (.in(i_cur_dmem_data), .out(w_i_cur_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_regfile_we_reg (.in(m_regfile_we), .out(w_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) w_r1sel_reg (.in(m_r1sel), .out(w_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) w_r2sel_reg (.in(m_r2sel), .out(w_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) w_wsel_reg (.in(m_wsel), .out(w_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_is_store_reg (.in(m_is_store), .out(w_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_is_load_reg (.in(m_is_load), .out(w_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_nzp_we_reg (.in(m_nzp_we), .out(w_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   wire [2:0] w_nzp;
   wire w_is_control_insn;
   Nbit_reg #(3) w_nzp_reg (.in(nzp_sel), .out(w_nzp), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_is_control_insn_reg (.in(m_is_control_insn), .out(w_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign nzp_out = (w_is_control_insn == 1'b0) ? w_nzp : m_nzp;

   //data mem block
   //..............**********CHECK THE MUX CASES COULD BE REVERSE...........
   //((m_is_store | m_is_load) == 1'b0)? 16'h0000:m_alu_out
   assign i_wdata = (w_is_load == 1'b1) ? w_addr : w_i_cur_insn;
   // assign i_wdata = (is_load == 3'd0) ? int_reg_mux : i_cur_dmem_data;
   //assign the tests
   assign test_cur_pc = w_pc;
   assign test_cur_insn = w_i_cur_insn;
   assign test_dmem_data = w_i_cur_dmem_data;
   assign test_dmem_we = w_is_store;
   assign test_nzp_we = w_nzp_we;
   assign test_regfile_we = w_regfile_we;
   assign test_regfile_data = i_wdata;
   assign test_regfile_wsel = w_wsel;
   assign test_nzp_new_bits = m_nzp;
   //................**************DO THIS LAST ONE.................
   assign test_dmem_addr = o_dmem_addr;
   assign test_stall = d_stall;





   // assign test_dmem_data = 16'd0;
   //  assign test_dmem_addr = 16'd0;
   //  assign test_dmem_we = 16'd0;
   //  assign test_stall = 2'd0;
   //  assign test_regfile_we = 1'd1;












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
      // $display("%d next_pc->%h f_pc->%h d_pc->%h x_pc->%h m_pc->%h cur_pc->%h d_r1sel->%h d_r2sel->%h d_is_stall->%h d_stall->%h x_wsel->%h mux6in-> %h dmem_addr->%h w_addr->%h nzp_in->%h nzp_out->%h i_wdata->%h ->%h ->%h i_cur_insn->%b  %b \n", $time, next_pc, f_pc, d_pc, x_pc, m_pc, test_cur_pc,d_r1sel, d_r2sel, d_is_stall,d_stall, x_wsel,mux6_in, test_dmem_addr, w_addr,nzp_in, nzp_out,  i_wdata, m_alu_out, i_cur_dmem_data, i_cur_insn, d_i_cur_insn);
      // $display("pc: %h x_pc: %h  m_pc: %h  w_pc: %h o_cur_pc: %h d_pc_plus_one: %h next_pc: %h test_cur_pc: %h",f_pc, x_pc, m_pc, w_pc, o_cur_pc, d_pc_plus_one, next_pc, test_cur_pc);
      //  $display("mux6_in: %h m_nzp: %h nzp_sel: %h nzp_out: %h",mux6_in, m_nzp, nzp_sel, nzp_out);
      // // if (o_dmem_we)  
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