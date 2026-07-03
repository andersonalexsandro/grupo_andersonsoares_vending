// tb_hello.sv
// Testbench do design de teste `hello`.
// Alterna as entradas `a` e `b` entre 0 e 1 ao longo do tempo, apenas
// para gerar transições visíveis na forma de onda.
//
// Dump de ondas em dois formatos:
//   - No servidor (VCS + Verdi): compilar com +define+FSDB  -> waves.fsdb
//   - Localmente (Icarus + GTKWave): sem define               -> waves.vcd

module tb_hello;

    logic a, b, y;

    hello dut (
        .a (a),
        .b (b),
        .y (y)
    );

    initial begin
`ifdef FSDB
        $fsdbDumpfile("waves.fsdb");
        $fsdbDumpvars(0, tb_hello);
`else
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_hello);
`endif

        $display("=== hello: iniciando estimulos ===");

        a = 1'b0; b = 1'b0;   // estado inicial
        #10 a = 1'b1;         // a: 0 -> 1
        #10 b = 1'b1;         // b: 0 -> 1  (agora y = 1)
        #10 a = 1'b0;         // a: 1 -> 0  (y volta a 0)
        #10 b = 1'b0;         // b: 1 -> 0
        #10;

        $display("=== hello: fim ===");
        $finish;
    end

    initial
        $monitor("t=%0t  a=%b b=%b  ->  y=%b", $time, a, b, y);

endmodule
