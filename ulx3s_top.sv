//------------------------------------------------------------------
// ULX3S 上で TD4 を動かすためのトップモジュール
//------------------------------------------------------------------
module ulx3s_top(
    input wire clk_25mhz,
    input wire [6:0] btn,
    output wire [7:0] led
);
    // ULX3S の LED と CPU の出力ポートを接続
    assign led = {4'b0000, cpu_out};

    // クロック生成
    // 25MHzのクロックから1Hzのクロックを生成する
    reg [24:0] cnt_25mhz;
    reg clk_1hz;
    always @(posedge clk_25mhz) begin
        if (cnt_25mhz == 12500000) begin
            cnt_25mhz <= 0;
            clk_1hz <= ~clk_1hz;
        end else begin
            cnt_25mhz <= cnt_25mhz + 1;
        end
    end

    // TD4 CPU
    wire [3:0] addr;
    wire [7:0] instr;
    wire [3:0] cpu_out;
    cpu cpu_inst(
        .clk(clk_1hz),
        .n_reset(btn[0]),
        .address(addr),
        .instr(instr),
        .in(btn[3:6]),
        .out(cpu_out)
    );

    // プログラムROM
    prog_rom prog_rom_inst(
        .addr(addr),
        .instr(instr)
    );
endmodule

module prog_rom(
    input wire [3:0] addr,
    output reg [7:0] instr
);

    assign instr = rom[addr];
    reg [7:0] rom [0:15];
    initial begin
        //------------------------
        // ラーメンタイマー
        //------------------------

        // LEDを3つ点灯
        rom[0] = OUT_IM(4'b0111);

        // キャリーが発生するまで16回ループ
        rom[1] = ADD_TO_A(1);
        rom[2] = JNC_TO_IM(1);

        // ここも16回ループ
        rom[3] = ADD_TO_A(1);
        rom[4] = JNC_TO_IM(3);

        // LEDを2つ点灯
        rom[5] = OUT_IM(4'b0110);

        // ここも16回ループ
        rom[6] = ADD_TO_A(1);
        rom[7] = JNC_TO_IM(6);

        // ここも16回ループ
        rom[8] = ADD_TO_A(1);
        rom[9] = JNC_TO_IM(8);

        // LEDの点滅を16回繰り返す
        rom[10] = OUT_IM(4'b0000);
        rom[11] = OUT_IM(4'b0100);
        rom[12] = ADD_TO_A(1);
        rom[13] = JNC_TO_IM(10);

        // 終了のLED 1000 を点灯
        rom[14] = OUT_IM(4'b1000);

        // 無限ループで停止
        rom[15] = JMP_TO_IM(15);
    end

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
