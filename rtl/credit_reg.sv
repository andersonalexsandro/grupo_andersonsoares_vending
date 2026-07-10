module credit_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       credit_load,   // soma coin_value
    input  logic       credit_clr,    // zera o credito
    input  logic [7:0] coin_value,
    output logic [7:0] credit
);

    always_ff @(posedge clk) begin
        if (rst)                 
            credit <= 8'd0;      
        else if (credit_clr)     
            credit <= 8'd0;      
        else if (credit_load)    
            credit <= credit + coin_value;
    end

endmodule
