# Controlador de Vending Machine (SystemVerilog)

Atividade avaliativa da trilha **RTL Design** (Residência em Microeletrônica
CI-Expert), módulo *Projeto de Controlador Digital*: projetar, simular e
sintetizar o controlador de uma máquina de vendas em **SystemVerilog**, no fluxo
**Synopsys VCS + Design Compiler**, integrando FSM de Moore, memória síncrona e
caminho de dados.

> 📄 **Relatório técnico (entrega):** [`docs/relatorio.pdf`](docs/relatorio.pdf)
> — diagramas, waveforms anotadas, resultados de síntese e análise do caminho
> crítico (A4, ≤ 10 páginas).

---

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `rtl/` | Módulos RTL: package, datapath, FSM e top-level |
| `sim/` | Testbench self-checking (`tb_vending.sv`) |
| `synth/` | Síntese: `synth.tcl`, `vending.sdc` e `reports/` |
| `docs/` | Relatório (`relatorio.pdf`), enunciado e diagramas (blocos/estados) |
| `Makefile` | Atalhos de simulação e síntese (local e servidor) |

### Módulos (`rtl/`)

| Arquivo | Função |
| --- | --- |
| `vending_pkg.sv` | Package: tipo `state_t` (enum de 6 estados) |
| `credit_reg.sv` | Registrador de crédito (8 b, síncrono); prioridade `rst` > `credit_clr` > `credit_load` |
| `memory.sv` | Memória 4×16 (preço + estoque), leitura/escrita síncronas |
| `comparator.sv` | Combinacional: `can_sell = (credit >= price) && (stock > 0)` |
| `subtractor.sv` | Combinacional: `change = credit - price` |
| `control_unit.sv` | FSM de Moore (6 estados) |
| `vending_top.sv` | Top-level: integra os módulos e registra `change_out`/`display` |

---

## Tecnologias e ferramentas

O RTL é **o mesmo** nos dois fluxos; muda só a ferramenta que o processa. No
testbench, o dump de ondas é escolhido por `` `ifdef FSDB `` (FSDB no servidor,
VCD localmente).

| | Local (open-source) | Servidor (Synopsys) |
| --- | --- | --- |
| Simulação | `iverilog` + `vvp` (Icarus) | `vlogan` → `vcs` → `simv` |
| Ondas | GTKWave (`.vcd`) | Verdi (`.fsdb`) |
| Síntese | — (não há) | Design Compiler (`dc_shell`) |
| Uso | ensaio rápido, sem licença | fluxo oficial da atividade |

- **Icarus Verilog** (`iverilog -g2012` + `vvp`) — simulação leve local; `-g2012`
  habilita SystemVerilog. O `$dumpfile`/`$dumpvars` gera `waves.vcd`.
- **GTKWave** — visualizador de ondas `.vcd`.
- **VCS** (Synopsys) — `vlogan` (análise, `-sverilog -kdb`) → `vcs`
  (compila/elabora em `simv`, `-debug_access+all +define+FSDB`) → `./simv`
  (gera `waves.fsdb`).
- **Verdi** (Synopsys) — visualizador `.fsdb` (`verdi -ssf waves.fsdb`); requer
  sessão gráfica.
- **Design Compiler** (Synopsys) — `dc_shell -f synth/synth.tcl`: `analyze →
  elaborate → link → compile_ultra`, gera netlist + relatórios de área/timing.
- **PDK SAED 32 nm** — standard cells; usa-se a lib **RVT / corner `tt`**
  (`saed32rvt_tt1p05v25c.db`). É **licenciada**: fica só no servidor, vai para
  `synth/libs/` e **nunca** é versionada (já no `.gitignore`).

---

## Como rodar

### Pré-requisitos

**Local (sem licença):**
- `git`, `make`
- **Icarus Verilog** (`iverilog`/`vvp`) com suporte a `-g2012` (SystemVerilog)
- **GTKWave** (opcional, para ver as ondas)

**Servidor (fluxo Synopsys oficial):**
- Acesso ao **servidor da residência** com o ambiente Synopsys instalado
  (**VCS**, **Verdi**, **Design Compiler**) e o **PDK SAED32**
- **Licença Synopsys** válida e as variáveis de licença configuradas conforme as
  instruções da residência (`SNPSLMD_LICENSE_FILE` / `LM_LICENSE_FILE`)
- **Sessão gráfica** (ex.: X2Go) para abrir Verdi / Design Vision

> ⚠️ Endereços do servidor, host/porta de licença e caminhos internos das
> ferramentas **não são versionados** — use os valores fornecidos pela residência.

### Local (Icarus + GTKWave)

```bash
git clone https://github.com/andersonalexsandro/grupo_andersonsoares_vending.git
cd grupo_andersonsoares_vending

make sim-local     # compila (iverilog -g2012) e roda (vvp); imprime PASS/FAIL dos 4 cenários
make wave-local    # (opcional) abre waves.vcd no GTKWave
```

Ao final, `make sim-local` deve terminar com:

```
>>> TODOS OS TESTES PASSARAM <<<   (14/14)
```

### Servidor (Synopsys)

```bash
# 1. Carregue o ambiente Synopsys fornecido pela residência
#    (script de setup que exporta VCS/Verdi/DC e as variáveis de licença)
source <script-de-ambiente-synopsys>.sh

# 2. Simulação (VCS + Verdi)
make run     # vlogan -> vcs -> ./simv   (gera waves.fsdb)
make wave    # abre o Verdi (requer sessão gráfica, ex.: X2Go)

# 3. Síntese (Design Compiler)
make syn     # dc_shell -f synth/synth.tcl  (relatórios em synth/reports/)
```

> **Síntese:** antes de `make syn`, copie o `.db` do PDK
> (SAED32 RVT, `saed32rvt_tt1p05v25c.db`), disponível no servidor, para
> `synth/libs/`. Ele é **licenciado — nunca versionar**.

Outros alvos: `make help` (lista tudo) · `make clean` (remove artefatos gerados).

---

## Diagramas

Fontes **draw.io** em `docs/` (`diagrama-blocos.drawio`, `diagrama-estados.drawio`);
a explicação detalhada de blocos, sinais, estados e transições está em
[`docs/diagramas.md`](docs/diagramas.md).

- Web: [app.diagrams.net](https://app.diagrams.net) → *Open Existing Diagram*.
- VSCode: extensão *Draw.io Integration* (`hediet.vscode-drawio`).
- Exportados como PNG e embutidos no relatório.

---

## Enunciado (resumo)

- **Sistema:** vending machine com 4 itens; o usuário insere moedas, seleciona,
  confirma e recebe produto + troco. Tudo síncrono, controlado por uma FSM.
- **FSM de Moore, 6 estados:** `IDLE → COLLECT → CHECK → DISPENSE → CHANGE → IDLE`,
  com desvio `CHECK → ERROR`. Um `cancel` (de qualquer estado) devolve o crédito
  via `change_out` (`refund_load`) e volta a `IDLE`.
- **Datapath:** registrador de crédito (8b), comparador (`can_sell`), subtrator de
  troco e memória síncrona 4×16 (preço + estoque).
- **Entregáveis:** RTL, testbench self-checking (4 cenários), síntese com
  exploração de timing e relatório técnico (PDF, ≤ 10 páginas).

Enunciado completo: [`docs/enunciado.md`](docs/enunciado.md).

### Avaliação (100 pts)

| Item | Pontos |
| --- | --- |
| Módulos RTL compilando e corretos | 20 |
| FSM de controle correta | 20 |
| Testbench self-checking (4 cenários + timeout) | 10 |
| Síntese com Design Compiler | 10 |
| Relatório técnico | 40 |

Penalizações: −5 por arquivo faltando · −10 se o top-level não compila · −5 se o
testbench não cobre os 4 cenários · −5 se o `synth.tcl` não roda até o fim.
