// hello.sv
// Design mínimo de teste do ambiente: duas entradas e uma saída.
// Objetivo: ter sinais que mudam de 0 para 1 e de 1 para 0 para
// observar no Verdi (ou GTKWave) e exercitar o fluxo das ferramentas.
// Puramente combinacional (sem clock).

module hello (
    input  logic a,
    input  logic b,
    output logic y
);

    assign y = a & b;

endmodule
