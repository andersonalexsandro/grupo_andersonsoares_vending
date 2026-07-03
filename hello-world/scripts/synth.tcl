# ============================================================
# Script de sintese do design `hello` (Synopsys Design Compiler)
# Rodar da raiz do hello-world:  dc_shell -f scripts/synth.tcl
# ============================================================

# 1. Carregar a configuracao (search_path, libraries, WORK, DRC)
source ./scripts/.synopsys_dc.setup

# 2. Analisar o RTL
analyze -format sverilog ./rtl/hello.sv

# 3. Elaborar (define o topo)
elaborate hello

# 4. Linkar com a biblioteca
link

# 5. Netlist NAO mapeada (GTECH generica, util para conferir a estrutura)
write_file -format sverilog -hier -out hello_nao_mapeada.sv

# 6. Constraints (arquivo vazio: design combinacional)
read_sdc scripts/hello.sdc

# 7. Sintese
compile_ultra

# 8. Relatorios pos-sintese
report_area      -hierarchy       > area.rpt
report_timing                     > timing.rpt
report_power                      > power.rpt
report_constraint -all_violators  > constraint.rpt

# 9. Exportar netlist mapeada (celulas reais do PDK)
write -format verilog -hierarchy -output hello_mapeada.v
write -format ddc     -hierarchy -output hello_mapeada.ddc

# 10. Salvar o design em memoria (retomar depois com read_db)
save_designs -force hello.db
