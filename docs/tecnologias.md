# Tecnologias e ferramentas

Referência das ferramentas usadas no projeto: o que cada uma faz, como se
encaixa no fluxo e os comandos/flags principais. O foco é **rodar o fluxo
completo no servidor `microeletronica3`** (simulação + síntese Synopsys),
com um toolchain local leve para ensaios rápidos.

> Versões: o material do curso é o pacote `ces_svrtl_2019.03`; o PDK é o
> `SAED32_2012-12-25`. Não há número de versão explícito dos binários VCS/
> Verdi/DC no material — trate "2019.03" como a release da toolchain.

---

## 1. Os dois fluxos

| | Local (open-source) | Servidor (Synopsys) |
| --- | --- | --- |
| Simulação | `iverilog` + `vvp` | `vlogan` → `vcs` → `simv` |
| Ondas | GTKWave (`.vcd`) | Verdi (`.fsdb`) ou DVE (`.vpd`) |
| Síntese | — (não há) | Design Compiler (`dc_shell`) |
| Uso | ensaio rápido, sem licença | fluxo oficial da atividade |

O RTL é o mesmo nos dois; muda só a ferramenta que o processa. No testbench,
o dump de ondas é escolhido por `` `ifdef FSDB `` (FSDB no servidor, VCD local).

---

## 2. Toolchain local

### iverilog + vvp (Icarus Verilog)
Simulador open-source. Compila o SystemVerilog e roda a simulação.

```bash
iverilog -g2012 -o sim rtl/*.sv tb/tb.sv   # -g2012 habilita SystemVerilog
vvp sim                                     # roda; $dumpvars gera waves.vcd
```

### GTKWave
Visualizador de ondas `.vcd`/`.fst`.

```bash
gtkwave waves.vcd &
```

> O dump local usa `$dumpfile("waves.vcd")` + `$dumpvars(0, tb)`.

---

## 3. Simulação Synopsys

### vlogan — análise (parsing)
Primeiro estágio: analisa o HDL e gera a base para o VCS.

```bash
vlogan -full64 -sverilog -kdb +lint=all rtl/*.sv tb/tb.sv
```
- `-full64` 64 bits · `-sverilog` habilita SV · `-kdb` gera a Knowledge
  Database (para o Verdi) · `+lint=all` lint de qualidade.

### VCS — simulador
Compila+elabora o design num executável `simv`.

```bash
# comportamento (RTL)
vcs -full64 -debug_access+all -kdb +define+FSDB tb_top
./simv
```
- `-debug_access+all` preserva todos os sinais para debug (níveis: `+r`,
  `+rw`, `+pp`, `+class`, `+all`) · `-kdb` (casar com o vlogan) ·
  `+define+FSDB` liga o dump `.fsdb` no testbench.

Dump FSDB no testbench:
```systemverilog
initial begin
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, tb_top);   // 0 = hierarquia inteira
end
```

### Verdi / DVE — visualizadores
- **Verdi** (moderno, `.fsdb`): `verdi -nologo -ssf waves.fsdb &`
- **DVE** (clássico do VCS, `.vpd`): `dve -vpd waves.vpd &`

No Verdi: *Get Signals* → adiciona sinais → aplica.

---

## 4. Síntese Synopsys (Design Compiler)

Traduz o RTL numa netlist de standard cells otimizando área/tempo/potência.
Shell Tcl: `dc_shell`. Quatro fases: **analyze → elaborate → link → compile_ultra**.

```bash
dc_shell -f scripts/synth.tcl      # roda da raiz do projeto, com libs/ populado
```

Esqueleto do `synth.tcl`:
```tcl
source ./scripts/.synopsys_dc.setup
analyze -format sverilog ./rtl/<top>.sv
elaborate <top>
link
read_sdc scripts/<top>.sdc
compile_ultra                       ;# na atividade: compile_ultra -no_autoungroup
report_area   -hierarchy          > area.rpt
report_timing                     > timing.rpt
report_power                      > power.rpt
report_constraint -all_violators  > constraint.rpt
write -format verilog -hierarchy -output <top>_mapeada.v
write -format ddc     -hierarchy -output <top>_mapeada.ddc
```

Variáveis do `.synopsys_dc.setup` (lido no startup): `search_path`,
`target_library` (o `.db`), `link_library` (`"* $target_library
dw_foundation.sldb"`), `synthetic_library` (DesignWare), `define_design_lib
WORK -path ./work`, e as flags `hdlin_check_no_latch true`,
`hdlin_enable_rtldrc_info true`, `compile_autonogate true`.

### Design Vision — GUI do Design Compiler
Mostra esquemático e relatórios. `design_vision` (ou `start_gui` dentro do
`dc_shell`); abre com o `.ddc`.

---

## 5. Biblioteca SAED 32 nm (PDK)

Standard cells de um PDK 32 nm. Dois formatos: `.db` (Liberty compilada —
tempo/potência, lida pelo Design Compiler) e `.v` (modelos Verilog das
células — usados pelo VCS em simulação gate-level).

Existem **duas** bibliotecas neste contexto — não confundir:

| | Curso (`ces_svrtl`) | Atividade (CI-Expert / porta-and) |
| --- | --- | --- |
| `.db` | `saed32hvt_ss0p75v125c.db` | `saed32rvt_tt1p05v25c.db` |
| Família / corner | HVT, ss (pior caso), 0,75 V, 125 °C | RVT, tt (típico), 1,05 V, 25 °C |
| Onde | local (`ces_svrtl_2019.03/ref/...`) | só no servidor (`/pdks/SAED32/...`) |

> **A atividade usa a RVT/tt do servidor.** As libs são licenciadas —
> ficam em `libs/` e **nunca** vão para o Git.

---

## 6. Licença e módulos (a confirmar no servidor)

- Variáveis: `SNPSLMD_LICENSE_FILE` e `LM_LICENSE_FILE`, no formato `porta@host`
  (ex.: `27000@license_server`). O host/porta reais do `microeletronica3`
  ainda precisam ser confirmados.
- Carregar ferramentas: `module avail` → `module load <vcs>` / `<dc>`
  (nomes exatos a confirmar).
- Verdi e Design Vision exigem sessão gráfica (X2Go).

---

## 7. Referências (vault de microeletrônica)

- `Ferramentas Synopsys (guia de uso).md`
- `Roteiro 1 - Simulação e Debug (VCS, Verdi, vlogan).md`
- `Roteiro 2 - Síntese Lógica (dc_shell, Design Compiler).md`
- `Conectar no servidor (microeletronica3).md`
