# Controlador de Vending Machine (SystemVerilog)

Atividade avaliativa da trilha **RTL Design** (Residência em Microeletrônica
CI-Expert), módulo *Projeto de Controlador Digital*: projetar, simular e
sintetizar o controlador de uma máquina de vendas em **SystemVerilog**, no fluxo
**Synopsys VCS + Design Compiler**, integrando FSM de Moore, memória síncrona e
caminho de dados.

---

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `rtl/` | Módulos RTL: package, datapath, FSM e top-level |
| `sim/` | Testbench self-checking (`tb_vending.sv`) |
| `synth/` | Síntese: `synth.tcl`, `vending.sdc` e `reports/` |
| `docs/` | Enunciado, guia de ferramentas e diagramas (blocos/estados) |
| `Makefile` | Atalhos de simulação e síntese (local e servidor) |

### Módulos (`rtl/`)

| Arquivo | Função |
| --- | --- |
| `vending_pkg.sv` | Package: tipo `state_t` (6 estados) e parâmetros |
| `credit_reg.sv` | Registrador de crédito (8 b, síncrono) |
| `memory.sv` | Memória 4×16 (preço + estoque), leitura/escrita síncronas |
| `comparator.sv` | Combinacional: `can_sell = (credit>=price) && (stock>0)` |
| `subtractor.sv` | Combinacional: `change = credit - price` |
| `control_unit.sv` | FSM de Moore (6 estados) |
| `vending_top.sv` | Top-level: integra os módulos |

---

## Como rodar

**Local (Icarus + GTKWave) — sem licença:**

```bash
make sim-local     # compila e roda; imprime PASS/FAIL dos 4 cenários
make wave-local    # abre waves.vcd no GTKWave
```

**Servidor `microeletronica3` (Synopsys):**

```bash
source /Tools/synopsys/snps.sh   # carrega VCS/Verdi/DC + licença
make run     # vlogan -> vcs -> ./simv  (gera waves.fsdb)
make wave    # Verdi (requer sessão gráfica X2Go)
make syn     # síntese com Design Compiler
```

> **Síntese:** copie o `.db` do PDK (SAED32 RVT, `saed32rvt_tt1p05v25c.db`) para
> `synth/libs/`. Ele é **licenciado — nunca versionar** (já ignorado no `.gitignore`).

---

## Diagramas

Arquivos **draw.io** em `docs/` (`diagrama-blocos.drawio`, `diagrama-estados.drawio`):

- Web: [app.diagrams.net](https://app.diagrams.net) → *Open Existing Diagram*.
- VSCode: extensão *Draw.io Integration* (`hediet.vscode-drawio`).
- Para o relatório, exportar para PNG/SVG.

---

## Enunciado (resumo)

- **Sistema:** vending machine com 4 itens; o usuário insere moedas, seleciona,
  confirma e recebe produto + troco. Tudo síncrono, controlado por uma FSM.
- **FSM de Moore, 6 estados:** `IDLE → COLLECT → CHECK → DISPENSE → CHANGE → IDLE`,
  com desvio `CHECK → ERROR`.
- **Datapath:** registrador de crédito (8b), comparador (`can_sell`), subtrator de
  troco e memória síncrona 4×16 (preço + estoque).
- **Entregáveis:** RTL, testbench self-checking (4 cenários), síntese com
  exploração de timing e relatório técnico (PDF, ≤10 páginas).

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
