# sw

Bare-metal C for the Cortex-A9, built in Vitis on a standalone platform.

| Folder | What |
| --- | --- |
| `hello/` | UART hello and an LED blink through AXI GPIO; board bring-up |
| `dma_loop/` | DMA loopback test and throughput measurement |
| `tpu/` | The driver: `tpu.h`, `tpu.c` |
| `demo/` | The demo app; `demo/data/` holds generated headers |

Driver API and rules: `docs/architecture.md`, section 9. The driver is tested on the board against a register stub; `tpu_reorder` is tested on the host against `demo/data/reorder_test.h`.
