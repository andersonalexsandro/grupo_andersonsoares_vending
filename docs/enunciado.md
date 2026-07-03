# Atividade Avaliativa — Controlador de Vending Machine em SystemVerilog

> Leia o documento completo antes de escrever qualquer linha de código.
> Trilha **RTL Design** · Módulo **Projeto de Controlador Digital** · Trabalho **individual ou em duplas**.

---

## 1. Objetivo

Projetar, codificar, simular e sintetizar o **controlador digital de uma vending machine** usando **SystemVerilog + Synopsys VCS + Design Compiler**. O projeto integra os três elementos de um sistema digital síncrono: **máquina de estados finitos (FSM)**, **memória de dados** e **lógica combinacional de caminho de dados**.

Ao final você será capaz de:
- Projetar e codificar uma **FSM de Moore** com múltiplos estados.
- Integrar **memória síncrona** de dados a uma FSM de controle.
- Separar claramente **caminho de dados** (datapath) e **unidade de controle**.
- Compilar, simular e depurar com **VCS e Verdi**.
- Escrever um **testbench self-checking** com múltiplos cenários.
- Sintetizar com **Design Compiler** e analisar os relatórios.

---

## 2. Descrição do sistema

Vending machine com **4 itens** (café, água, suco, snack). O usuário insere moedas, seleciona um item, confirma a compra e recebe o produto e o troco. **Não há programa armazenado** — toda a lógica de sequenciamento é feita pela FSM.

Características:
- Design **totalmente síncrono** com clock e reset globais.
- Memória interna com **preços e estoques** dos 4 itens.
- **Acumulador de crédito** (registrador síncrono).
- **Comparador** e **subtrator** combinacionais no caminho de dados.
- **FSM de Moore** com **6 estados** e saídas registradas.

---

## 3. Diagrama de blocos (1ª tarefa: desenhar)

**Entradas:** `coin_in[1:0]`, `sel_item[1:0]`, `confirm` (1b), `cancel` (1b), `clk`, `rst` (reset síncrono).

**Registrador de crédito — `credit[7:0]`:** registrador síncrono de 8 bits que acumula o valor total das moedas ao longo do tempo. Quando o usuário insere uma moeda e a FSM está em **COLLECT**, o sinal `credit_load` é ativado e `credit ← credit + coin_value`.

`coin_value` derivado de `coin_in` (representação em **ponto fixo**, em centavos):

| `coin_in` | Moeda | `coin_value` |
| --- | --- | --- |
| `00` | R$0,00 (nenhuma) | 0 |
| `01` | R$0,25 | 25 |
| `10` | R$0,50 | 50 |
| `11` | R$1,00 | 100 |

Com 8 bits sem sinal representa-se de **0 a 255 centavos** — suficiente para o item mais caro (100) e para acumular até R$2,55.

**Comparador** (combinacional, **não registrado**): produz `can_sell` que só vai a 1 se **ambas** forem verdadeiras:
```
can_sell = (credit >= price) AND (stock > 0)
```
- **Condição 1 — crédito suficiente:** compara `credit` com o `price` lido da memória (comparação de magnitude de 8 bits → subtrator + verifica o sinal).
- **Condição 2 — item disponível:** `stock` do item selecionado é maior que zero.
- A FSM lê a memória no estado **CHECK**; no ciclo seguinte `price` e `stock` já estão nos fios; o comparador avalia `can_sell` nesse mesmo ciclo, e a FSM usa esse valor para decidir DISPENSE ou ERROR.
- O comparador **não decide** — só calcula um booleano. Quem decide é a FSM (no CHECK).

**Subtrator** (combinacional): calcula o troco em centavos:
```
change = credit - price
```
- Calcula o tempo todo, mas o resultado só **importa** quando a FSM entra em **CHANGE** — aí ela registra `change` em `change_out` e zera o crédito.
- **Não pode ser negativo:** o comparador já garantiu `credit >= price` antes de ir para DISPENSE. Divisão de responsabilidades: o comparador garante que a conta é válida, o subtrator só executa.
- **Crédito exato:** `change = 0` → `change_out = 0`, nenhum troco; a FSM passa por CHANGE normalmente e volta a IDLE.

**Unidade de controle:** FSM de 6 estados (detalhe na seção 6).

**Saídas:**
- Combinacionais: `dispense`, `error`.
- Registradas: `change_out`, `display`, `state_out`.

---

## 4. Interface do módulo top-level (`vending_top`)

### 4.1 Entradas

| Sinal | Largura | Descrição |
| --- | --- | --- |
| `coin_in` | 2 bits | Valor da moeda inserida: `00`=nenhuma, `01`=R$0,25, `10`=R$0,50, `11`=R$1,00 |
| `sel_item` | 2 bits | Seleção do item (0..3). **Também é o endereço da memória** |
| `confirm` | 1 bit | Confirmação da compra (pulso síncrono) |
| `cancel` | 1 bit | Cancelamento: devolve crédito e retorna ao IDLE |
| `clk` | 1 bit | Clock global síncrono |
| `rst` | 1 bit | Reset síncrono, ativo em nível alto |

### 4.2 Saídas

| Sinal | Largura | Descrição |
| --- | --- | --- |
| `dispense` | 1 bit | **Pulso de 1 ciclo**: sinaliza que o item deve ser liberado |
| `change_out` | 8 bits | Valor do troco em centavos (`credit − price`). Válido no estado CHANGE |
| `error` | 1 bit | Ativo quando sem estoque ou crédito insuficiente |
| `display` | 8 bits | Crédito acumulado atual (para display externo) |
| `state_out` | 3 bits | Estado corrente da FSM (para depuração e testbench) |

> Observações importantes
> - `coin_in` é amostrado a cada borda de subida do clock; valor ≠ `00` indica inserção de moeda naquele ciclo.
> - `sel_item` deve estar estável **antes** de `confirm`; funciona como endereço direto da memória.
> - `dispense` é um **pulso de exatamente 1 ciclo** — o hardware externo detecta essa borda.
> - `cancel` em qualquer estado retorna ao IDLE e **zera o crédito**.

---

## 5. Memória de dados

4 posições de **16 bits**: 8 bits superiores = `price` (centavos), 8 bits inferiores = `stock`. Endereço direto por `sel_item[1:0]`.

| Addr | Item | `price[7:0]` | `stock[7:0]` | Observação |
| --- | --- | --- | --- | --- |
| `0x0` | Café | `0x19` (25) | `0x05` | R$0,25 — 5 unidades iniciais |
| `0x1` | Água | `0x32` (50) | `0x05` | R$0,50 |
| `0x2` | Suco | `0x4B` (75) | `0x03` | R$0,75 |
| `0x3` | Snack | `0x64` (100) | `0x02` | R$1,00 |

Comportamento:
- **Leitura síncrona:** com `mem_read=1`, `price` e `stock` ficam disponíveis **no ciclo seguinte**.
- **Escrita síncrona:** com `mem_write=1`, o campo `stock` é decrementado de 1 (`stock ← stock − 1`) no endereço `sel_item`.
- Inicializar com os valores da tabela via **`initial begin`**.
- **Não há escrita em `price`** — preços são fixos.

---

## 6. Máquina de estados — FSM de Moore

FSM de Moore: as saídas dependem **apenas do estado atual**, não das entradas. Implementar com **dois blocos always**: um `always_ff` para a transição de estados e um `always_comb` para a lógica de saídas.

| Estado | Encoding | Condição de entrada | Saídas ativas / Ação |
| --- | --- | --- | --- |
| `IDLE` | `3'b000` | `rst` ou `cancel` (de qualquer estado) | Aguarda: nenhuma saída ativa |
| `COLLECT` | `3'b001` | `coin_in ≠ 00` em IDLE ou em COLLECT | `credit_load=1`; acumula `coin_value` no crédito |
| `CHECK` | `3'b010` | `confirm=1` em COLLECT | `mem_read=1`; compara `credit ≥ price` e `stock > 0` |
| `DISPENSE` | `3'b011` | `can_sell=1` em CHECK | `dispense=1` (1 ciclo); `mem_write=1` (decrementa stock) |
| `CHANGE` | `3'b100` | sempre após DISPENSE | `change_out = credit − price`; `credit_load=1` (zera crédito) |
| `ERROR` | `3'b101` | `can_sell=0` em CHECK | `error=1`; aguarda `cancel` para voltar ao IDLE |

- **Fluxo normal completo:** `IDLE → COLLECT → CHECK → DISPENSE → CHANGE → IDLE`.
- **Desvio de erro:** `CHECK → ERROR → IDLE`.
- `cancel` em **qualquer** estado retorna imediatamente ao IDLE e zera o crédito.

Detalhe dos estados:
- **CHECK:** ativa `mem_read` para buscar `price` e `stock`; no ciclo seguinte o comparador produz `can_sell` → `1` vai para DISPENSE, `0` vai para ERROR.
- **DISPENSE:** `dispense` por 1 ciclo (pulso); `mem_write` decrementa o estoque; avança imediatamente para CHANGE.
- **CHANGE:** registra o troco (`change_out = credit − price`) e zera o crédito (`credit_load=1, credit ← 0`); volta a IDLE.
- **ERROR:** crédito insuficiente ou sem estoque; mantém `error=1` e aguarda `cancel`; crédito devolvido via `change_out`.

### 6.1 Diagrama de transição de estados
Desenhar o diagrama de acordo com o descrito (entregável do relatório).

---

## 7. Caminho de dados

### 7.1 Registrador de crédito
Registrador síncrono de 8 bits, controlado por `credit_load`:
- `credit_load=1` **e** FSM em COLLECT: `credit ← credit + coin_value`
- `credit_load=1` **e** FSM em CHANGE: `credit ← 0` (zera após dispensar)
- `cancel` ou `rst`: `credit ← 0`

`coin_value` derivado de `coin_in`: `00→0, 01→25, 10→50, 11→100` (centavos).

### 7.2 Comparador
Lógica combinacional pura (`always_comb` ou `assign`):
```systemverilog
assign can_sell = (credit >= price) && (stock > 8'b0);
```

### 7.3 Subtrator de troco
Lógica combinacional pura, valor usado no estado CHANGE:
```systemverilog
assign change = credit - price;  // resultado em centavos
```
`change_out` é registrado na saída quando a FSM entra em CHANGE, e mantido até o próximo ciclo de operação.

---

## 8. Simulação com Synopsys VCS

Escrever um **testbench simples (sem UVM)** e um script de simulação.

### 8.1 Cenários de teste obrigatórios
O testbench deve implementar e verificar **automaticamente** todos os cenários:

| # | Cenário | Sequência de entradas | Verificação esperada |
| --- | --- | --- | --- |
| 1 | Compra bem-sucedida com troco | `coin_in=11` (R$1,00); `sel_item=0` (café, R$0,25); `confirm=1` | `dispense=1`; `change_out=75`; `credit=0` ao final |
| 2 | Crédito insuficiente | `coin_in=01` (R$0,25); `sel_item=3` (snack, R$1,00); `confirm=1` | `error=1`; FSM vai para ERROR |
| 3 | Cancelamento | `coin_in=11`; `coin_in=11`; `cancel=1` | `credit=0`; FSM retorna a IDLE; `change_out=200` |
| 4 | Estoque zerado | Comprar café 5 vezes (estoque=5); tentar 6ª vez | Na 6ª: `error=1` (`stock=0`) |

### 8.2 Estrutura do testbench
O testbench deve conter:
1. Geração de clock: `always #5 clk = ~clk;` (período 10 ns).
2. Reset inicial por 2 ciclos de clock.
3. Task `apply_coin(value)` que aplica uma moeda e aguarda 1 ciclo.
4. Task `buy_item(item, coins[])` que executa uma compra completa.
5. Task `check(expected, actual, label)` que reporta **PASS/FAIL**.
6. Geração de waveform.

---

## 9. Síntese com Synopsys Design Compiler

Com o design verificado em simulação, sintetizar e analisar os limites temporais.

### Parte 1 — Script de síntese (`synth.tcl`), nesta ordem:
1. Configurar `target_library` e `link_library` apontando para a biblioteca **disponível no ambiente do laboratório**.
2. `analyze -format sverilog` em todos os arquivos RTL.
3. `elaborate` definindo **`vending_top`** como módulo de topo; `link`.
4. `read_sdc vending.sdc`.
5. `check_design` salvando em `reports/check_design.rpt`. **Corrigir todos os erros antes de prosseguir.**
6. `compile_ultra -no_autoungroup`.
7. Gerar e salvar: `report_area`, `report_timing`, `report_power`, `report_constraint -all_violators`.
8. `write -format verilog -hierarchy` (exportar a netlist).

### Parte 2 — Arquivo de constraints (`vending.sdc`):
1. `create_clock` de nome `clk`, período inicial **20 ns (50 MHz)**.
2. `set_clock_uncertainty` de **0,5 ns** (jitter e skew).
3. `set_input_delay` de **3 ns** para todas as entradas (relativo ao clock).
4. `set_output_delay` de **3 ns** para todas as saídas.
5. `set_load` e `set_driving_cell` com valores típicos da biblioteca.

### Parte 3 — Exploração dos limites do design
1. Partir de 20 ns e **reduzir em passos de 2 ns**, re-sintetizando a cada iteração.
2. Registrar o **slack** (`report_timing`) e a **área** (`report_area`) para cada período.
3. Identificar o **menor período com slack ainda não-negativo** = período mínimo suportado.
4. Tentar um período 2 ns abaixo do mínimo e observar como o DC reage.
5. Retirar `-no_autoungroup` e ver se há diferença nos reports de timing e área.

| Período | Frequência | Slack (ns) | Área | Timing |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

### Parte 4 — Análise e discussão (responder no relatório)
1. Qual é o **caminho crítico**? Quais módulos ele atravessa?
2. Como a **área** variou ao reduzir o período? Explique o motivo.
3. A partir de qual frequência o DC **não fechou o timing**? Qual o slack nesse ponto?
4. Considerando a FSM e o datapath, **qual estado/transição** você acredita estar no caminho crítico, e por quê?
5. Que **modificação no RTL** você proporia para reduzir o caminho crítico **sem alterar o comportamento**?

---

## 10. Relatório técnico

Entregar em **PDF (máx. 10 páginas)**, contendo:
1. Link para o repositório GitHub do projeto.
2. Diagrama de blocos.
3. Diagrama de estados (redesenho manual ou com ferramenta, com todas as transições e saídas).
4. Descrição dos módulos: decisões de projeto e justificativas.
5. **Waveforms anotadas:** capturas do DVE identificando cada cenário de teste.
6. Saída do testbench: terminal mostrando os PASS/FAIL de cada verificação.
7. Resultados de síntese: área total, frequência máxima e slack do caminho crítico.
8. Análise: qual estado/transição é o caminho crítico? Por quê?
9. Conclusão: dificuldades encontradas e lições aprendidas.

> "DVE" no item 5: o documento pede "capturas do DVE". Os roteiros da trilha usam **Verdi** (`.fsdb`). Use o visualizador disponível (Verdi ou DVE) — o que importa é anotar cada cenário na forma de onda.

---

## 11. Estrutura de diretórios

```
grupo_NN_vending/
├── rtl/
│   ├── vending_pkg.sv
│   ├── credit_reg.sv
│   ├── memory.sv
│   ├── comparator.sv
│   ├── subtractor.sv
│   ├── control_unit.sv
│   └── vending_top.sv
├── sim/
│   └── tb_vending.sv
├── synth/
│   ├── synth.tcl
│   ├── vending.sdc
│   └── reports/
└── relatorio.pdf
```

| # | Arquivo | Descrição |
| --- | --- | --- |
| 1 | `vending_pkg.sv` | Package com parâmetros, encoding de estados e tipos |
| 2 | `credit_reg.sv` | Registrador de crédito acumulador (síncrono, com reset) |
| 3 | `memory.sv` | Memória síncrona 4×16 bits com leitura e escrita separadas |
| 4 | `comparator.sv` | Combinacional: `can_sell = (credit ≥ price) && (stock > 0)` |
| 5 | `subtractor.sv` | Combinacional: `change = credit − price` |
| 6 | `control_unit.sv` | FSM de Moore com 6 estados |
| 7 | `vending_top.sv` | Top-level: instancia e interconecta todos os módulos |
| 8 | `tb_vending.sv` | Testbench VCS com cenários de teste e verificação automática |
| 9 | `synth.tcl` | Script de síntese para Synopsys Design Compiler |
| 10 | `vending.sdc` | Constraints de timing (clock 50 MHz, I/O delays) |
| 11 | `relatorio.pdf` | Relatório técnico (diagrama de estados, waveforms, síntese) |

---

## 12. Critérios de avaliação

| Item | Pontos | Critério |
| --- | --- | --- |
| Módulos RTL compilando e corretos | 20 | Cada módulo compila sem erros com `vcs` e produz comportamento correto na simulação unitária |
| FSM de controle correta | 20 | Todos os 6 estados implementados; transições e saídas corretas para todos os cenários |
| Testbench self-checking | 10 | Cobre os 4 cenários obrigatórios; reporta PASS/FAIL automaticamente; possui timeout |
| Síntese com Design Compiler | 10 | Script executa sem erros; netlist gerada; relatório de área e timing disponível |
| Relatório técnico | 40 | Diagrama de estados desenhado, waveforms anotadas, análise do slack |

**Penalizações:**
- −5 pontos por arquivo faltando na estrutura de diretórios.
- −10 pontos se o top-level não compilar com `vcs` sem erros.
- −5 pontos se o testbench não cobrir todos os 4 cenários obrigatórios.
- −5 pontos se o `synth.tcl` não executar até o fim sem erros fatais.
