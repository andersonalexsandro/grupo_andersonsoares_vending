# ============================================================
# Controlador de Vending Machine - atalhos de simulacao e sintese
# Servidor (Synopsys):  make run  -> make wave  -> make syn
# Local (Icarus/GTKWave): make sim-local -> make wave-local
# ============================================================

RTL_FILES = rtl/vending_pkg.sv rtl/comparator.sv rtl/subtractor.sv \
            rtl/credit_reg.sv rtl/memory.sv rtl/control_unit.sv rtl/vending_top.sv
TB_FILE   = sim/tb_vending.sv
TOP       = tb_vending

.PHONY: help syntax compile run wave syn sim-local wave-local clean

help:
	@echo "Alvos:"
	@echo "  --- Synopsys (servidor) ---"
	@echo "  make run        vlogan -> vcs -> ./simv   (gera waves.fsdb)"
	@echo "  make wave       abre a onda no Verdi"
	@echo "  make syn        sintese com Design Compiler (dc_shell -f synth/synth.tcl)"
	@echo "  --- Local (Icarus/GTKWave) ---"
	@echo "  make sim-local  compila e roda com iverilog/vvp (gera waves.vcd)"
	@echo "  make wave-local abre a onda no GTKWave"
	@echo "  make clean      remove artefatos gerados"

# ---------------- Synopsys (servidor) ----------------
syntax:
	vlogan -full64 -sverilog -timescale=1ns/1ps -kdb +lint=all +define+FSDB $(RTL_FILES) $(TB_FILE)

compile: syntax
	vcs -full64 -debug_access+all -kdb $(TOP)

run: compile
	./simv

wave:
	verdi -nologo -ssf waves.fsdb &

syn:
	dc_shell -f synth/synth.tcl

# ---------------- Local (Icarus / GTKWave) ----------------
sim-local:
	iverilog -g2012 -o vending_sim $(RTL_FILES) $(TB_FILE)
	vvp vending_sim

wave-local:
	gtkwave waves.vcd &

# ---------------- Limpeza ----------------
clean:
	rm -rf csrc simv* *.daidir novas* AN.DB ucli.key verdi* DVEfiles .vlogan* \
	       *.fsdb *.vpd *.vcd *.log work vending_sim \
	       synth/work synth/reports/*.rpt synth/reports/*_mapeada.* \
	       synth/reports/*_nao_mapeada.* synth/reports/*.ddc
