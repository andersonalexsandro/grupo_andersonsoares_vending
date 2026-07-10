module memory (
    input  logic       clk,
    input  logic       mem_read,
    input  logic       mem_write,
    input  logic [1:0] addr,        // = sel_item
    output logic [7:0] price,
    output logic [7:0] stock
);
    // 1) declara o array mem
    logic [15:0] mem [0:3];

    // 2) initial begin ... end com a tabela
    initial begin
        mem[0] = {8'd25,  8'd5};   // café:  preço 25, estoque 5
        mem[1] = {8'd50,  8'd5};   // água:  preço 50, estoque 5
        mem[2] = {8'd75,  8'd3};   // suco:  preço 75, estoque 3
        mem[3] = {8'd100, 8'd2};   // snack: preço 100, estoque 2
    end
    // 3) always_ff com leitura/escrita

    always @(posedge clk) begin
        if (mem_write)
            mem[addr][7:0] <= mem[addr][7:0] - 8'd1;   // estoque--  (só o byte baixo)
        if (mem_read) begin
            price <= mem[addr][15:8];   // byte alto  -> price
            stock <= mem[addr][7:0];    // byte baixo -> stock
        end
    end

endmodule
