# ============================================================
# Sintese do vending_top (Synopsys Design Compiler)
# Rodar da RAIZ do projeto:  dc_shell -f synth/synth.tcl
# Requer o .db do PDK em ./libs/ (nao versionado).
# ============================================================

# 1. Bibliotecas
set ROOT_DIR [pwd]
set_app_var search_path       [list $ROOT_DIR $ROOT_DIR/rtl $ROOT_DIR/libs]
set_app_var target_library    [list saed32rvt_tt1p05v25c.db]
set_app_var link_library      [concat "*" $target_library dw_foundation.sldb]
set_app_var synthetic_library [list dw_foundation.sldb]
define_design_lib WORK -path ./synth/work
set hdlin_check_no_latch true

# 2. Analisar todo o RTL (package primeiro)
analyze -format sverilog [list \
    ./rtl/vending_pkg.sv  \
    ./rtl/comparator.sv   \
    ./rtl/subtractor.sv   \
    ./rtl/credit_reg.sv   \
    ./rtl/memory.sv       \
    ./rtl/control_unit.sv \
    ./rtl/vending_top.sv  \
]

# 3. Elaborar o topo e linkar
elaborate vending_top
current_design vending_top
link

# 4. Netlist NAO mapeada (GTECH generica)
write_file -format verilog -hierarchy -output ./synth/reports/vending_nao_mapeada.v

# 5. Constraints de timing
read_sdc ./synth/vending.sdc

# 6. Checar o design (corrigir erros antes de compilar)
check_design > ./synth/reports/check_design.rpt

# 7. Sintese
compile_ultra -no_autoungroup

# 8. Relatorios
report_area   -hierarchy         > ./synth/reports/area.rpt
report_timing                    > ./synth/reports/timing.rpt
report_power                     > ./synth/reports/power.rpt
report_constraint -all_violators > ./synth/reports/constraint.rpt

# 9. Netlist mapeada (celulas reais do SAED32)
write -format verilog -hierarchy -output ./synth/reports/vending_mapeada.v
write -format ddc     -hierarchy -output ./synth/reports/vending_mapeada.ddc

exit
