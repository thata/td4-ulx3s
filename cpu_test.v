//------------------------
// テストベンチ
// （ラーメンタイマーを実行して、out を $display するだけ）
//------------------------
module cpu_test();
  reg clk;
  reg n_reset;
  reg [3:0] port_in;

  wire [3:0] address;
  wire [7:0] dout;
  wire [3:0] port_out;

  // Generate clock
  always begin
    #5 clk = 1;
    #5 clk = 0;
  end

  cpu cpu(clk, n_reset, address, dout, port_in, port_out);
  test_rom rom(address, dout);

  // Finish after 3000 unit times
  always
    #3000 $finish;

  initial begin
    // 波形データを cpu_test.vcd へ出力する
    $dumpfile("cpu_test.vcd");

    // cpu モジュール内の変数を波形データとして出力
    $dumpvars(0, cpu);

    // 出力ポートをモニタする
    $monitor("%t: out = %b", $time, port_out);
  end

  initial begin
    // Init variables
    #0 clk = 0; n_reset = 1; port_in = 4'b0101;

    // Reset cpu
    #10 n_reset = 0;
    #10 n_reset = 1;
  end
endmodule

//------------------------
// ROM
//------------------------
module test_rom(
  input [3:0] address,
  output reg [7:0] dout
);

  always @(address)
    case (address)
      /*
        ラーメンタイマー
      */
      // LEDを3つ点灯
      4'b0000: dout <= OUT_IM(4'b0111);

      // キャリーが発生するまで16回ループ
      4'b0001: dout <= ADD_TO_A(4'b0001);
      4'b0010: dout <= JNC_TO_IM(4'b0001);

      // ここも16回ループ
      4'b0011: dout <= ADD_TO_A(4'b0001);
      4'b0100: dout <= JNC_TO_IM(4'b0011);

      // LEDを2つ点灯
      4'b0101: dout <= OUT_IM(4'b0110);

      // ここも16回ループ
      4'b0110: dout <= ADD_TO_A(4'b0001);
      4'b0111: dout <= JNC_TO_IM(4'b0110);
      // ここも16回ループ
      4'b1000: dout <= ADD_TO_A(4'b0001);
      4'b1001: dout <= JNC_TO_IM(4'b1000);

      // LEDの点滅（0000 -> 0100）を16回繰り返す
      4'b1010: dout <= OUT_IM(4'b0000); // LED 0000
      4'b1011: dout <= OUT_IM(4'b0100); // LED 0100
      4'b1100: dout <= ADD_TO_A(4'b0001);
      4'b1101: dout <= JNC_TO_IM(4'b1010);

      // 終了のLED 1000 を点灯
      4'b1110: dout <= OUT_IM(4'b1000); // LED 1000

      // 無限ループ
      4'b1111: dout <= JMP_TO_IM(4'b1111);

      default: dout <= 8'bxxxxxxxx;
    endcase

    //------------------------
    // 命令セット
    //------------------------

    // MOV A, Im
    // AレジスタにImを転送
    function [7:0] MOV_TO_A(input [3:0] im);
      MOV_TO_A = {4'b0011, im};
    endfunction

    // MOV B, Im
    // BレジスタにImを転送
    function [7:0] MOV_TO_B(input [3:0] im);
      MOV_TO_B = {4'b0111, im};
    endfunction

    // MOV B, A
    // BレジスタにAレジスタを転送
    `define MOV_B_TO_A 8'b10000000

    // ADD A, Im
    // AレジスタにImを加算
    function [7:0] ADD_TO_A(input [3:0] im);
      ADD_TO_A = {4'b0000, im};
    endfunction

    // ADD B, Im
    // BレジスタにImを加算
    function [7:0] ADD_TO_B(input [3:0] im);
      ADD_TO_B = {4'b0101, im};
    endfunction

    // IN A
    // 入力ポートからAレジスタへ転送
    `define IN_TO_A 8'b00100000

    // IN B
    // 入力ポートからBレジスタへ転送
    `define IN_TO_B 8'b01100000

    // OUT Im
    // 出力ポートへImを転送
    function [7:0] OUT_IM(input [3:0] im);
      OUT_IM = {4'b1011, im};
    endfunction

    // OUT B
    // 出力ポートへBレジスタを転送
    `define OUT_B 8'b10010000

    // JMP Im
    // Im番地へジャンプ
    function [7:0] JMP_TO_IM(input [3:0] im);
      JMP_TO_IM = {4'b1111, im};
    endfunction

    // JNC Im
    // Cフラグが1ではないときにジャンプ
    function [7:0] JNC_TO_IM(input [3:0] im);
      JNC_TO_IM = {4'b1110, im};
    endfunction
endmodule
