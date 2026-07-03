# Controlador de Vending Machine (SystemVerilog)

Atividade avaliativa da trilha **RTL Design** (Residência em Microeletrônica
CI-Expert), módulo *Projeto de Controlador Digital*. O objetivo é projetar,
simular e sintetizar o controlador digital de uma máquina de vendas usando
**SystemVerilog + Synopsys VCS + Design Compiler**, integrando FSM de Moore,
memória síncrona e caminho de dados.

O foco imediato deste repositório é **conseguir rodar o fluxo completo das
ferramentas no servidor `microeletronica3`**. Por isso ele começa com um
sandbox `hello-world/` para exercitar as ferramentas antes de implementar o
projeto avaliado.

---

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `hello-world/` | Sandbox mínimo para testar as ferramentas (simulação + síntese) |
| `docs/tecnologias.md` | Guia das ferramentas: VCS, Verdi, vlogan, Design Compiler, SAED32… |
| `docs/enunciado.md` | Enunciado completo da atividade |
| `docs/diagrama-blocos.drawio` | Diagrama de blocos (editável no draw.io) |
| `docs/diagrama-estados.drawio` | Diagrama de estados da FSM (editável no draw.io) |
| `rtl/` | Módulos RTL do projeto — **a implementar** |
| `sim/` | Testbench do projeto — **a implementar** |
| `synth/` | Scripts de síntese e relatórios — **a implementar** |

> As pastas `rtl/`, `sim/` e `synth/` seguem a estrutura exigida pelo enunciado
> (seção 11) e por enquanto estão vazias — o código é escrito ao longo das fases
> do projeto.

---

## Começando: o hello-world

O primeiro passo é validar as ferramentas com um design trivial (duas entradas
que alternam entre 0 e 1, para ver na forma de onda):

```bash
cd hello-world

# teste local rápido (Icarus + GTKWave), sem licença:
make sim-local
make wave-local

# fluxo Synopsys no servidor:
make run     # vlogan -> vcs -> simv (waves.fsdb)
make wave    # Verdi
make syn     # Design Compiler
```

Passo a passo detalhado (incluindo licença e módulos do servidor) em
[`hello-world/README.md`](hello-world/README.md).

---

## Diagramas

Os diagramas em `docs/` são arquivos **draw.io**, editáveis num editor GUI:

- **Web (sem instalar):** abrir [app.diagrams.net](https://app.diagrams.net) →
  *Open Existing Diagram* → selecionar o `.drawio`.
- **VSCode:** instalar a extensão *Draw.io Integration* (`hediet.vscode-drawio`)
  e abrir o arquivo direto no editor.

Para o relatório, exportar de dentro do draw.io para PNG/SVG.

---

## Enunciado (resumo)

- **Sistema:** vending machine com 4 itens; o usuário insere moedas, seleciona,
  confirma e recebe produto + troco. Tudo síncrono, controlado por uma FSM.
- **FSM de Moore, 6 estados:** `IDLE → COLLECT → CHECK → DISPENSE → CHANGE →
  IDLE`, com desvio `CHECK → ERROR`.
- **Datapath:** registrador de crédito (8b), comparador (`can_sell`), subtrator
  de troco, e memória síncrona 4×16 (preço + estoque).
- **Entregáveis:** RTL, testbench self-checking (4 cenários), síntese com
  exploração de timing, e relatório técnico (PDF, ≤10 páginas).

Enunciado completo: [`docs/enunciado.md`](docs/enunciado.md).

### Avaliação (100 pts)

| Item | Pontos |
| --- | --- |
| Módulos RTL compilando e corretos | 20 |
| FSM de controle correta | 20 |
| Testbench self-checking (4 cenários + timeout) | 10 |
| Síntese com Design Compiler | 10 |
| Relatório técnico | 40 |

Penalizações: −5 por arquivo faltando · −10 se o top-level não compila ·
−5 se o testbench não cobre os 4 cenários · −5 se o `synth.tcl` não roda até o fim.
