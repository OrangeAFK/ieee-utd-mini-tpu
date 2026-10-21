# tb/common/axil_master

AXI4-Lite master: `write` and `read` tasks with random channel delays and selectable address/data order.

- `axil_master.sv`: the component. Its header comment is the full spec, including the tasks benches call.
- Tested by use in `tb_regfile` and `tb_accel_top`.
