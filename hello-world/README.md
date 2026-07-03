# hello-world — testar as ferramentas

Projeto mínimo para **exercitar o fluxo das ferramentas** antes de mexer no
controlador de vending machine. O design (`rtl/hello.sv`) tem só duas entradas
`a`, `b` e uma saída `y = a & b`; o testbench alterna `a`/`b` entre 0 e 1 para
gerar transições visíveis na forma de onda.

A estrutura (`rtl/`, `tb/`, `scripts/` + `Makefile`) espelha o repositório
`porta-and` do instrutor, que já roda no servidor — assim os comandos aqui são
os mesmos que serão reaproveitados no projeto principal.

```
hello-world/
├── rtl/hello.sv          # a, b -> y = a & b (combinacional)
├── tb/tb_hello.sv        # alterna a/b entre 0 e 1; dump de onda
├── scripts/
│   ├── .synopsys_dc.setup  # libraries / WORK / DRC do Design Compiler
│   ├── hello.sdc           # vazio (design sem clock)
│   └── synth.tcl           # analyze -> elaborate -> link -> compile_ultra -> reports
└── Makefile
```

---

## 1. Teste rápido local (Icarus + GTKWave)

Não precisa de servidor nem licença — só para conferir que o RTL/testbench
estão sãos:

```bash
make sim-local     # iverilog + vvp  -> imprime os estímulos e gera waves.vcd
make wave-local    # abre waves.vcd no GTKWave
```

Espera-se ver `a`, `b` e `y` mudando de 0 para 1 e de 1 para 0 ao longo do tempo.

---

## 2. Fluxo Synopsys no servidor (microeletronica3)

> Rodar no servidor exige sessão gráfica (X2Go) para o Verdi/Design Vision.
> Ver: `Conectar no servidor (microeletronica3)` no vault.

### 2.1 Preparar o ambiente (uma vez por sessão)

```bash
# carregar as ferramentas (nomes exatos a confirmar no servidor)
module avail
module load <vcs>
module load <design_compiler>

# licença (host:porta a confirmar no servidor)
export SNPSLMD_LICENSE_FILE=<porta>@<host>
```

> **Pendências a confirmar no servidor** (preencher depois):
> - nomes exatos dos módulos (`module load ...`) do VCS/Verdi e do Design Compiler;
> - host e porta reais da licença (`SNPSLMD_LICENSE_FILE` / `LM_LICENSE_FILE`);
> - caminho/arquivo `.db` da biblioteca SAED32 (ver `scripts/.synopsys_dc.setup`).

### 2.2 Simulação (VCS + Verdi)

```bash
make run     # vlogan -> vcs -> ./simv  (gera waves.fsdb)
make wave    # verdi -nologo -ssf waves.fsdb &
```

No Verdi: *Get Signals* → adicionar `a`, `b`, `y` → aplicar, e observar as ondas.

### 2.3 Síntese (Design Compiler)

Antes: colocar o `.db` da SAED32 em `hello-world/libs/` (não versionar — licença).

```bash
make syn     # dc_shell -f scripts/synth.tcl
```

Saída: `area.rpt`, `timing.rpt`, `power.rpt`, `constraint.rpt`, a netlist
mapeada (`hello_mapeada.v`) e o `.ddc`.

---

## 3. Limpeza

```bash
make clean   # remove simv*, waves.*, work/, *.rpt, netlists, etc.
```

Detalhes das ferramentas e flags em [`../docs/tecnologias.md`](../docs/tecnologias.md).
