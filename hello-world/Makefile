# ============================================================
# hello-world - atalhos para exercitar as ferramentas
# ============================================================
# Fluxo Synopsys (servidor microeletronica3):  make run  -> make wave  -> make syn
# Fluxo local (Icarus + GTKWave):               make sim-local -> make wave-local
# ============================================================

RTL_DIR   = rtl
TB_DIR    = tb
RTL_FILES = $(RTL_DIR)/hello.sv
TB_FILES  = $(TB_DIR)/tb_hello.sv
TOP       = tb_hello

.PHONY: help syntax compile run wave syn sim-local wave-local clean

help:
	@echo "Alvos disponiveis:"
	@echo "  --- Synopsys (servidor) ---"
	@echo "  make syntax     analise (vlogan)"
	@echo "  make compile    compila (vcs) -> simv"
	@echo "  make run        syntax + compile + roda ./simv (gera waves.fsdb)"
	@echo "  make wave       abre a onda no Verdi"
	@echo "  make syn        sintese com Design Compiler (dc_shell)"
	@echo "  --- Local (Icarus/GTKWave) ---"
	@echo "  make sim-local  compila e roda com iverilog/vvp (gera waves.vcd)"
	@echo "  make wave-local abre a onda no GTKWave"
	@echo "  --- Limpeza ---"
	@echo "  make clean      remove artefatos gerados"

# ---------------- Synopsys (servidor) ----------------
syntax:
	vlogan -full64 -sverilog -kdb +lint=all $(RTL_FILES) $(TB_FILES)

compile: syntax
	vcs -full64 -debug_access+all -kdb +define+FSDB $(TOP)

run: compile
	./simv

wave:
	verdi -nologo -ssf waves.fsdb &

syn:
	dc_shell -f scripts/synth.tcl

# ---------------- Local (Icarus / GTKWave) ----------------
sim-local:
	iverilog -g2012 -o hello_sim $(RTL_FILES) $(TB_FILES)
	vvp hello_sim

wave-local:
	gtkwave waves.vcd &

# ---------------- Limpeza ----------------
clean:
	rm -rf csrc simv* *.daidir novas* AN.DB ucli.key verdi* DVEfiles .vlogan* \
	       *.fsdb *.vpd *.vcd *.log work *.rpt *_mapeada.* *_nao_mapeada.* \
	       *.ddc *.db hello_sim
