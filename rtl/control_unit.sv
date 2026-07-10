import vending_pkg::*;             

module control_unit (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] coin_in,
    input  logic       confirm,
    input  logic       cancel,
    input  logic       can_sell,
    output state_t     state,
    output logic       credit_load,
    output logic       credit_clr,
    output logic       mem_read,
    output logic       mem_write,
    output logic       change_load,
    output logic       refund_load,
    output logic       dispense,
    output logic       error
);

    state_t next_state;

    // Bloco 1 — registrador de estado
    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // Bloco 2 — proximo estado + saidas (combinacional)
    always_comb begin
        // defaults (evita latch)
        next_state  = state;
        credit_load = 1'b0;
        credit_clr  = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        change_load = 1'b0;
        refund_load = 1'b0;
        dispense    = 1'b0;
        error       = 1'b0;

        if (cancel) begin
            next_state  = IDLE;
            credit_clr  = 1'b1;      // zera o credito
            refund_load = 1'b1;      // devolve o credito via change_out
        end
        else begin
            case (state)
                IDLE: begin
                    if (coin_in != 2'b00) begin
                        next_state  = COLLECT;
                        credit_load = 1'b1;   // conta a 1a moeda
                    end
                end
                COLLECT: begin
                    if (confirm) begin
                        next_state = CHECK;
                        mem_read   = 1'b1;    // dispara a leitura (latencia de 1 ciclo)
                    end
                    else if (coin_in != 2'b00) begin
                        next_state  = COLLECT;
                        credit_load = 1'b1;   // soma mais moedas
                    end
                end
                CHECK: begin
                    if (can_sell) next_state = DISPENSE;
                    else          next_state = ERROR;
                end
                DISPENSE: begin
                    dispense   = 1'b1;        // pulso de 1 ciclo
                    mem_write  = 1'b1;        // estoque--
                    next_state = CHANGE;
                end
                CHANGE: begin
                    change_load = 1'b1;       // registra o troco
                    credit_clr  = 1'b1;       // zera o credito
                    next_state  = IDLE;
                end
                ERROR: begin
                    error = 1'b1;             // fica ate o cancel
                end
                default: next_state = IDLE;
            endcase
        end
    end

endmodule
