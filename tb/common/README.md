# tb/common

Bench components shared by every testbench. One folder per component; `tb_pkg.sv` (seed, hex loading, compare, cover counters) sits here.

| Component | Stands in for |
| --- | --- |
| `axis_src/` | DMA MM2S, or any word source |
| `axis_sink/` | DMA S2MM |
| `axil_master/` | The CPU on GP0 |
| `axis_check/` | Stream protocol checker |
| `mxu_check/` | Contract 4 checker |

Each file's header is its spec. They are tested by use: `tb_out_fifo` exercises the stream components, `tb_regfile` the register master, `tb_mxu` the MXU checker.
