import vending_pkg::*;

module vending_top (
    input  logic [1:0] coin_in,
    input  logic [1:0] sel_item,
    input  logic       confirm,
    input  logic       cancel,
    input  logic       clk,
    input  logic       rst,
    output logic       dispense,
    output logic       error,
    output logic [7:0] change_out,
    output logic [7:0] display,
    output logic [2:0] state_out
);

    logic [7:0] coin_value;
    logic [7:0] credit;
    logic [7:0] price, stock;
    logic       can_sell;
    logic [7:0] change;
    state_t     w_state;

    logic       credit_load, credit_clr, mem_read, mem_write;
    logic       change_load, refund_load;

    always_comb begin
        case (coin_in)
            2'b00:   coin_value = 8'd0;
            2'b01:   coin_value = 8'd25;
            2'b10:   coin_value = 8'd50;
            2'b11:   coin_value = 8'd100;
            default: coin_value = 8'd0;
        endcase
    end

    credit_reg u_credit (
        .clk         (clk),
        .rst         (rst),
        .credit_load (credit_load),
        .credit_clr  (credit_clr),
        .coin_value  (coin_value),
        .credit      (credit)
    );

    memory u_mem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (sel_item),
        .price     (price),
        .stock     (stock)
    );

    comparator u_cmp (
        .credit   (credit),
        .price    (price),
        .stock    (stock),
        .can_sell (can_sell)
    );

    subtractor u_sub (
        .credit (credit),
        .price  (price),
        .change (change)
    );

    control_unit u_fsm (
        .clk         (clk),
        .rst         (rst),
        .coin_in     (coin_in),
        .confirm     (confirm),
        .cancel      (cancel),
        .can_sell    (can_sell),
        .state       (w_state),
        .credit_load (credit_load),
        .credit_clr  (credit_clr),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .change_load (change_load),
        .refund_load (refund_load),
        .dispense    (dispense),
        .error       (error)
    );

    always_ff @(posedge clk) begin
        if (rst)              change_out <= 8'd0;
        else if (refund_load) change_out <= credit;
        else if (change_load) change_out <= change;
    end

    assign display   = credit;
    assign state_out = w_state;

endmodule
