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
   

   //d
   wire [15:0] i_wdata;
   wire [2:0] w_wsel;
   wire w_regfile_we;

   //x
   wire [2:0]m_wsel;
   wire m_regfile_we;
   wire [15:0] m_alu_out;
   wire [15:0] x_alu_out;

   //m
   wire [15:0] m_pc, m_pc_plus_one, m_i_cur_insn;
   //wire m_regfile_we;
   wire [2:0] m_r1sel, m_r2sel;
   wire [15:0] m_alu_in2;
   //wire [2:0] m_wsel;
   wire m_is_store, m_is_load, m_is_branch, m_is_control_insn, m_nzp_we;
   wire [15:0] i_wdata_m;
   wire [15:0] i_dmem_towrite;
   wire mw_bp_logic;
   wire mwl;
   wire result_z;
   wire [2:0] nzp_inter;
   wire [2:0] nzp_in, nzp_out;
   wire match_out;
   wire mux6_in;

   //w
   wire [15:0] w_pc;
   wire [15:0] w_i_cur_insn;
   wire [15:0] w_addr;
   wire [15:0] w_i_cur_dmem_data;
   //wire w_regfile_we;
   wire [2:0] w_r1sel, w_r2sel;
   //wire [2:0] w_wsel;
   wire w_is_store, w_is_load;
   wire w_nzp_we;

   // Fetch Register Stage ...................................................................................................
   
   wire [15:0]   f_pc, next_pc, f_pc_plus_one;

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) f_pc_reg (.in(next_pc), .out(f_pc), .clk(clk), .we(stall_we), .gwe(gwe), .rst(rst));
   assign f_pc_plus_one = o_cur_pc + 16'd1;
   assign o_cur_pc = f_pc;
   assign stall_we = ~load_to_use


   // Decode Register Stage ..................................................................................................
   
   wire [15:0] d_pc, d_i_cur_insn, d_pc_plus_one;
   wire [15:0] d_o_rs_data, d_o_rt_data;
   wire [2:0] d_r1sel, d_r2sel, d_wsel;
   wire d_r1re, d_r2re, d_regfile_we, d_nzp_we, d_select_pc_plus_one, d_is_store, d_is_load, d_is_branch, d_is_control_insn;

   wire [15:0] i_cur_insn_update = change_pc ? 16'd0 : i_cur_insn;

   Nbit_reg #(16) d_pc_reg (.in(f_pc), .out(d_pc), .clk(clk), .we(stall_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_pc_plus_one_reg (.in(f_pc_plus_one), .out(d_pc_plus_one), .clk(clk), .we(stall_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_i_cur_insn_reg (.in(i_cur_insn_update), .out(d_i_cur_insn), .clk(clk), .we(stall_we), .gwe(gwe), .rst(rst));
   
   // Decoder
   lc4_decoder decoder(.insn(d_i_cur_insn), .r1sel(d_r1sel), .r1re(d_r1re), .r2sel(d_r2sel), .r2re(d_r2re), .wsel(d_wsel), 
      .regfile_we(d_regfile_we), .nzp_we(d_nzp_we), .select_pc_plus_one(d_select_pc_plus_one), .is_load(d_is_load), 
      .is_store(d_is_store), .is_branch(d_is_branch), .is_control_insn(d_is_control_insn));
   
   // Regfile
   lc4_regfile #(16) regfile(.clk(clk), .gwe(gwe), .rst(rst), .i_rs(d_r1sel), .o_rs_data(d_o_rs_data), .i_rt(d_r2sel), 
      .o_rt_data(d_o_rt_data), .i_rd(w_wsel), .i_wdata(i_wdata_w), .i_rd_we(w_regfile_we));


   // Stall Logic
   wire load_to_use;
   assign load_to_use = (x_is_load & (((d_r1sel == x_wsel) & d_r1re) || ((d_r2sel == x_wsel) & d_r2re & ~d_is_store) || d_is_branch));


   //  Execute Register Stage ..................................................................................................
   
   wire [15:0] x_pc, x_pc_plus_one, x_i_cur_insn;
   wire [15:0] x_o_rs_data, x_o_rt_data;
   wire [2:0] x_r1sel, x_r2sel, x_wsel;
   wire x_regfile_we, x_nzp_we, x_select_pc_plus_one, x_is_load, x_is_store, x_is_branch, x_is_control_insn;

   wire x_load_to_use;

   wire [15:0] d_i_cur_insn_update == (change_pc | load_to_use) ? 16'b0 : d_i_cur_insn;

   wire [2:0] d_wsel_change = (change_pc | load_to_use) ?  3'b0 : d_wsel;
   wire d_regfile_we_change = (change_pc | load_to_use) ?  1'b0 : d_regfile_we;
   wire d_nzp_we_change = (change_pc | load_to_use) ?  1'b0 : d_nzp_we;
   wire d_select_pc_plus_one_change = (change_pc | load_to_use) ?  1'b0 : d_select_pc_plus_one;
   wire d_is_load_change = (change_pc | load_to_use) ?  1'b0 : d_is_load;
   wire d_is_store_change = (change_pc | load_to_use) ?  1'b0 : d_is_store;
   wire d_is_branch_change = (change_pc | load_to_use) ?  1'b0 : d_is_branch;
   wire d_is_control_insn_change = (change_pc | load_to_use) ?  1'b0 : d_is_control_insn;

   
   Nbit_reg #(16) x_pc_plus_one_reg (.in(d_pc_plus_one), .out(x_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_o_rs_data_reg (.in(d_o_rs_data), .out(x_o_rs_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_o_rt_data_reg (.in(d_o_rt_data), .out(x_o_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  
   Nbit_reg #(3) x_r1sel_reg (.in(d_r1sel), .out(x_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) x_r2sel_reg (.in(d_r2sel), .out(x_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) x_load_to_use_reg (.in(load_to_use), .out(x_load_to_use), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(16) x_pc_reg (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) x_i_cur_insn_reg (.in(d_i_cur_insn_update), .out(x_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(3) x_wsel_reg (.in(d_wsel_change), .out(x_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) x_regfile_we_reg (.in(d_regfile_we_change), .out(x_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   
   Nbit_reg #(1) x_nzp_we_reg (.in(d_nzp_we_change), .out(x_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) x_select_pc_plus_one_reg (.in(d_select_pc_plus_one_change), .out(x_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_load_reg (.in(d_is_load_change), .out(x_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_store_reg (.in(d_is_store_change), .out(x_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1) x_is_branch_reg (.in(d_is_branch_change), .out(x_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) x_is_control_insn_reg (.in(d_is_control_insn_change), .out(x_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
  

   wire d1, d2, d3, d4, d5, d6;
   wire [1:0] x_bp_logic1, x_bp_logic2;
   wire [15:0] select;
   wire [15:0] alu_in1, alu_in2;

   //branch 

   // x_bp_logic1 block
   assign d1 = (x_r1sel == m_wsel) & m_regfile_we;
   assign d2 = (x_r1sel == w_wsel) & w_regfile_we;
   assign d3 = (x_r1sel == w1_wsel) & w1_regfile_we;
   assign x_bp_logic1 = d3 ? 2'b11 : (d2 ? 2'b01 : d1 ? 2'b10 : 2'b00); 

  // x_bp_logic2 block
   assign d3 = (x_r2sel == m_wsel) & _regfile_we;
   assign d4 = (x_r2sel == w_wsel) & w_regfile_we;
   assign d6 = (x_r2sel == w1_wsel) & w1_regfile_we;
   assign x_bp_logic2 = d3 ? 2'b11 : (d2 ? 2'b01 : d1 ? 2'b10 : 2'b00);

   assign select = (w_is_load) ? w_i_cur_dmem_data : w_alu_out;

   //alu_in1 block
   assign alu_in1 = (x_bp_logic1 == 2'b00) ? x_o_rs_data : (x_bp_logic1 == 2'b01) ? select : (x_bp_logic1 == 2'b10) ? m_alu_out : i_wdata_w1;
   
   //alu_in2 block
   assign alu_in2 = (x_bp_logic2 == 2'b10) ? x_o_rt_data : (x_bp_logic2 == 2'b01) ? select : (x_bp_logic2 == 2'b00) ? m_alu_out : i_wdata_w1;

   //alu block
   lc4_alu a0 (.i_insn(x_i_cur_insn), .i_pc (x_pc), .i_r1data(alu_in1), .i_r2data(alu_in2), .o_result(x_alu_out));  


   
   //branch
   assign nzp_out = (m_nzp_we) ? x_nzp : w_nzp;
   assign match_out = ((nzp_out == 3'b100) & x_i_cur_insn[11]) | ((nzp_out == 3'b010) & x_i_cur_insn[10]) | ((nzp_out == 3'b001) & x_i_cur_insn[9]);
   assign change_pc = (match_out & x_is_branch) | (x_is_control_insn);

   assign next_pc = (change_pc) ? x_alu_out : f_pc_plus_one;
   

   //..............................................................................................................
   //M or memory stage register;
   wire m_select_pc_plus_one;
   wire m_load_to_use;
   Nbit_reg #(16) m_pc_plus_one_reg (.in(x_pc_plus_one), .out(m_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_alu_out_reg (.in(x_alu_out), .out(m_alu_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) m_r1sel_reg (.in(x_r1sel), .out(m_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) m_r2sel_reg (.in(x_r2sel), .out(m_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_alu_in2_reg (.in(alu_in2), .out(m_alu_in2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_load_to_use_reg (.in(x_load_to_use), .out(m_load_to_use), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(16) m_pc_reg (.in(x_pc), .out(m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) m_i_cur_insn_reg (.in(x_i_cur_insn), .out(m_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(3) m_wsel_reg (.in(x_wsel), .out(m_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_regfile_we_reg (.in(x_regfile_we), .out(m_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(1) m_nzp_we_reg (.in(x_nzp_we), .out(m_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_select_pc_plus_one_reg (.in(x_select_pc_plus_one), .out(m_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(1) m_is_load_reg (.in(x_is_load), .out(m_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_store_reg (.in(x_is_store), .out(m_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_branch_reg (.in(x_is_branch), .out(m_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_is_control_insn_reg (.in(x_is_control_insn), .out(m_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   

   //data mem
   assign o_dmem_we = m_is_store;
   assign o_dmem_addr = ((m_is_store | m_is_load)) ? m_alu_out : 16'h0000;
   wire a;
   wire b;
   assign a = (m_r2sel == w_wsel);
   assign b = (m_is_store & w_is_load);
   assign o_dmem_towrite = (a & b) i_wdata_w : m_alu_in2;

   //next_pc
   wire data_inter;
   assign data_inter = (m_is_load) i_cur_dmem_data : m_alu_out;
   assign i_wdata_m = (m_select_pc_plus_one) m_pc_plus_one : data_inter;

   //nzp
   wire [2:0] m_nzp;
   wire [2:0] x_nzp;

   wire [2:0] nzp_int1;
   assign nzp_int1 = (m_alu_out == 16'b0) ? 3'b010 : 3'b001;
   assign x_nzp = (m_alu_out [15]) ? 3'b100 : nzp_int1;

   wire [2:0] nzp_int2;
   assign nzp_int2 = (i_wdata_m == 16'b0) ? 3'b010 : 3'b001;
   assign m_nzp = (i_wdata_m [15]) ? 3'b100 : nzp_int1;

   //nzp final
   assign nzp_sel = (m_regfile_we) ? m_nzp : x_nzp;

  //..............................................................................................................
   //W or write stage register
   wire [15:0] i_wdata_w;
   wire [15:0] m_alu_out;
   wire w_is_branch;
   wire w_select_pc_plus_one;
   wire w_load_to_use;
   wire [15:0] w_o_dmem_towrite;
    
   
   Nbit_reg #(16) w_i_cur_dmem_data_reg (.in(i_cur_dmem_data), .out(w_i_cur_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) w_alu_out_reg (.in(m_alu_out), .out(w_alu_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) m_load_to_use_reg (.in(m_load_to_use), .out(w_load_to_use), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) w_nzp_reg (.in(nzp_sel), .out(w_nzp), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(16) w_dmem_towrite_reg (.in(o_dmem_towrite), .out(w_o_dmem_towrite), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //make sure that these names are in order
   Nbit_reg #(16) w_addr_reg (.in(i_wdata_m), .out(i_wdata_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(16) w_pc_reg (.in(m_pc), .out(w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) w_i_cur_insn_reg (.in(m_i_cur_insn), .out(w_i_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(3) w_wsel_reg (.in(m_wsel), .out(w_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_regfile_we_reg (.in(m_regfile_we), .out(w_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   

   Nbit_reg #(1) w_nzp_we_reg (.in(m_nzp_we), .out(w_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_select_pc_plus_one_reg (.in(m_select_pc_plus_one), .out(w_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) w_is_load_reg (.in(m_is_load), .out(w_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_is_store_reg (.in(m_is_store), .out(w_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w_is_branch_reg (.in(m_is_branch), .out(w_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));   
   Nbit_reg #(1) w_is_control_insn_reg (.in(m_is_control_insn), .out(w_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //additional registers
   wire [2:0] w1_wsel;
   wire w1_wsel_reg;
   wire [15:0] i_wdata_w1;
   Nbit_reg #(3) w1_wsel_reg (.in(w_wsel), .out(w1_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) w1_regfile_we_reg (.in(w_regfile_we), .out(w1_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   Nbit_reg #(16) w1_addr_reg (.in(i_wdata_w), .out(i_wdata_w1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   assign test_cur_pc = w_pc;
   assign test_cur_insn = w_i_cur_insn;
   assign test_dmem_we = w_is_store;
   assign test_nzp_we = w_nzp_we;
   assign test_regfile_we = w_regfile_we;
   assign test_regfile_wsel = w_wsel;
   assign test_nzp_new_bits = w_nzp;
   assign test_dmem_addr = (w_is_store | w_is_load) ? w_alu_out : 16'b0;
   assign test_stall =  w_load_to_use ? 2'b11 : (w_i_cur_insn == 16'b0 ? 2'b10 : 2'b00);
   assign test_dmem_data = w_is_store ? w_o_dmem_towrite : (w_is_load ? w_i_cur_dmem_data : 16'b0);
   assign test_regfile_data = w_i_cur_dmem_data;





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
       $display("---------------------------------------------------------------------------------------------------------------------------------------------------------------------");
       $display("pc: %h d_pc: %h x_pc: %h  m_pc: %h  w_pc: %h o_cur_pc: %h next_pc: %h",f_pc, d_pc, x_pc, m_pc, w_pc, o_cur_pc, next_pc);
       $display("i_cur_insn: %h d_i_cur_insn: %h d_insn_update: %h w_i_cur_insn: %h",i_cur_insn, d_i_cur_insn, d_insn_update,w_i_cur_insn);
       $display("i_wdata: %h i_wdata_w: %h w_i_cur_dmem_data: %h i_cur_dmem_data: %h m_alu_out: %h x_alu_out: %h",i_wdata, i_wdata_w, w_i_cur_dmem_data, i_cur_dmem_data, m_alu_out, x_alu_out);
       $display("alu_in1: %h alu_in2: %h", alu_in1, alu_in2);
       $display("w_is_load: %h w_is_store: %h",w_is_load, w_is_store);
       $display("x_o_rs_data: %h x_o_rt_data: %h m_alu_out: %h i_wdata_w: %h",x_o_rs_data, x_o_rt_data, m_alu_out, i_wdata_w);

       pinstr(x_i_cur_insn);
       pinstr(w_i_cur_insn);
       
       

       // $display("next_pc: %h",f_pc, x_pc, m_pc, w_pc, o_cur_pc, d_pc_plus_one, next_pc);
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
