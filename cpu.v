//--------------------------------
// 4bitCPU 「TD4」
//--------------------------------
module cpu(
  input clk,
  input n_reset,
  output [3:0] address,
  input [7:0] instr,
  input [3:0] in,
  output [3:0] out);

  //------------------------
  // （デバッグ用）モニタの設定
  //------------------------
  initial begin
    // $monitor("%t: pc = %b, a = %b, b = %b, instr = %b, op = %b, im = %b, select_a = %b, select_b = %b, load0 = %b, load1 = %b, load2 = %b", $time, pc_reg, a_reg, b_reg, instr, op, im, select_a, select_b, load0, load1, load2);
  end

  //------------------------
  // ワイヤ・レジスタの宣言
  //------------------------
  wire [3:0] op;
  wire [3:0] im;
  wire select_a, select_b;
  wire load0, load1, load2, load3;
  wire [3:0] selector_out;
  wire [3:0] alu_out;
  wire c; // Carry out

  reg [3:0] pc_reg; // Program counter
  reg [3:0] a_reg, b_reg; // A, B register
  reg [3:0] out_reg; // Out port register
  reg co_reg; // Carry out register

  //------------------------
  // 外部モジュールとの接続
  //------------------------

  // データセレクタ
  data_selector ds (a_reg, b_reg, in, 4'b0000, select_a, select_b, selector_out);

  //------------------------
  // レジスタ
  //------------------------
  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) begin
      a_reg <= 0;
      b_reg <= 0;
    end
    else begin
      a_reg <= load0 ? alu_out : a_reg;
      b_reg <= load1 ? alu_out : b_reg;
    end
  end

  //------------------------
  // 出力ポート
  //------------------------
  assign out = out_reg;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) out_reg <= 0;
    else out_reg <= load2 ? alu_out : out_reg;
  end

  //------------------------
  // プログラムカウンタ
  //------------------------
  assign address = pc_reg;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) pc_reg <= 0;
    else pc_reg <= load3 ? im : pc_reg + 1;
  end

  //------------------------
  // ALU と carry レジスタ
  //------------------------
  assign {c, alu_out} = selector_out + im;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) co_reg <= 0;
    else co_reg <= c;
  end

  //------------------------
  // 命令のデコード
  //------------------------

  // 命令を「オペレーションコード」と「イミディエイトデータ」へ分割
  assign op = instr[7:4]; // オペレーションコード
  assign im = instr[3:0]; // イミディエイトデータ

  // データセレクタ制御フラグ
  assign select_a = op[0] | op[3];
  assign select_b = op[1];

  // ロードレジスタ制御フラグ
  assign load0 = !(op[2] | op[3]); // Aレジスタへロード
  assign load1 = !(!op[2] | op[3]); // Bレジスタへロード
  assign load2 = !op[2] & op[3]; // 出力ポートへロード
  assign load3 = (!co_reg | op[0]) & op[2] & op[3]; // PCへロード
endmodule

//------------------------
// データセレクタ
//
// select_a、select_bの信号に応じてc0〜c3の信号を出力する
//
// * (select_a = L, select_b = L) => c0を出力
// * (select_a = H, select_b = L) => c1を出力
// * (select_a = L, select_b = H) => c2を出力
// * (select_a = H, select_b = H) => c3を出力
//------------------------
module data_selector(
  input [3:0] c0,
  input [3:0] c1,
  input [3:0] c2,
  input [3:0] c3,
  input select_a, select_b,
  output reg [3:0] y
);

  always @(*) begin
    if (select_a & select_b)
      y = c3;
    else if (!select_a & select_b)
      y = c2;
    else if (select_a & !select_b)
      y = c1;
    else
      y = c0;
  end
endmodule

