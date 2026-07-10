import vending_pkg::*;

module tb_vending;

    logic [1:0] coin_in, sel_item;
    logic       confirm, cancel, clk, rst;
    logic       dispense, error;
    logic [7:0] change_out, display;
    logic [2:0] state_out;

    int   errors = 0;
    logic f_dispense, f_error;

    vending_top dut (
        .coin_in    (coin_in),
        .sel_item   (sel_item),
        .confirm    (confirm),
        .cancel     (cancel),
        .clk        (clk),
        .rst        (rst),
        .dispense   (dispense),
        .error      (error),
        .change_out (change_out),
        .display    (display),
        .state_out  (state_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (dispense) f_dispense <= 1'b1;
        if (error)    f_error    <= 1'b1;
    end

    initial begin
`ifdef FSDB
        $fsdbDumpfile("waves.fsdb");
        $fsdbDumpvars(0, tb_vending);
`else
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_vending);
`endif
    end

    initial begin
        repeat (2000) @(posedge clk);
        $display("TIMEOUT: simulacao nao terminou a tempo");
        $finish;
    end

    task check(input int esperado, input int obtido, input string label);
        if (esperado === obtido)
            $display("  PASS: %-24s (esperado=%0d, obtido=%0d)", label, esperado, obtido);
        else begin
            $display("  FAIL: %-24s (esperado=%0d, obtido=%0d)", label, esperado, obtido);
            errors++;
        end
    endtask

    task apply_coin(input logic [1:0] value);
        @(negedge clk);
        coin_in = value;
        @(negedge clk);
        coin_in = 2'b00;
    endtask

    task buy_item(input logic [1:0] item, input logic [1:0] coins []);
        foreach (coins[i])
            apply_coin(coins[i]);
        @(negedge clk);
        sel_item = item;
        confirm  = 1'b1;
        @(negedge clk);
        confirm  = 1'b0;
    endtask

    task restock();
        dut.u_mem.mem[0] = {8'd25,  8'd5};
        dut.u_mem.mem[1] = {8'd50,  8'd5};
        dut.u_mem.mem[2] = {8'd75,  8'd3};
        dut.u_mem.mem[3] = {8'd100, 8'd2};
    endtask

    task do_reset();
        coin_in  = 2'b00;
        sel_item = 2'b00;
        confirm  = 1'b0;
        cancel   = 1'b0;
        rst      = 1'b1;
        repeat (2) @(negedge clk);
        rst        = 1'b0;
        f_dispense = 1'b0;
        f_error    = 1'b0;
        restock();
    endtask

    initial begin
        do_reset();

        $display("=== Cenario 1: compra com troco ===");
        buy_item(2'b00, '{2'b11});
        repeat (6) @(negedge clk);
        check(1,  f_dispense, "C1 dispensou");
        check(75, change_out, "C1 troco=75");
        check(0,  display,    "C1 credito=0");

        $display("=== Cenario 2: credito insuficiente ===");
        do_reset();
        buy_item(2'b11, '{2'b01});
        repeat (6) @(negedge clk);
        check(1,           f_error,   "C2 erro");
        check(int'(ERROR), state_out, "C2 estado=ERROR");

        $display("=== Cenario 3: cancelamento ===");
        do_reset();
        apply_coin(2'b11);
        apply_coin(2'b11);
        @(negedge clk);
        cancel = 1'b1;
        @(negedge clk);
        cancel = 1'b0;
        repeat (2) @(negedge clk);
        check(200,        change_out, "C3 devolucao=200");
        check(0,          display,    "C3 credito=0");
        check(int'(IDLE), state_out,  "C3 volta IDLE");

        $display("=== Cenario 4: estoque zerado ===");
        do_reset();
        for (int k = 0; k < 5; k++) begin
            f_dispense = 1'b0;
            buy_item(2'b00, '{2'b01});
            repeat (6) @(negedge clk);
            check(1, f_dispense, $sformatf("C4 compra %0d", k+1));
        end
        f_error = 1'b0;
        buy_item(2'b00, '{2'b01});
        repeat (6) @(negedge clk);
        check(1, f_error, "C4 6a compra = erro");

        $display("");
        if (errors == 0) $display(">>> TODOS OS TESTES PASSARAM <<<");
        else             $display(">>> %0d FALHA(S) <<<", errors);
        $finish;
    end

endmodule
