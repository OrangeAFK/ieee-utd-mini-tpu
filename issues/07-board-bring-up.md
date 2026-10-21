Board bring-up

## Goal

Get the Cora Z7-07S from a fresh clone to a booting block design: a bare-metal app that prints over UART and blinks an LED through AXI GPIO. Every later hardware step starts from this design.

Steps:

1. Install the Digilent board files and create a project targeting the Cora Z7-07S.
2. In a block design, add the ZYNQ7 Processing System and run Block Automation with the board preset. Enable M_AXI_GP0 and set FCLK_CLK0 to 100 MHz.
3. Add an AXI GPIO connected to one RGB LED through the board interface. Run Connection Automation.
4. Validate, create the HDL wrapper, generate the bitstream, export the hardware with the bitstream.
5. In Vitis, build a standalone platform from the export and an app that prints over the UART at 115200 baud and blinks the LED by writing the GPIO register.
6. Save the block design with `write_bd_tcl` into `hw/bd_d1.tcl`.

## Files

- `hw/bd_d1.tcl`, and a few lines in `hw/README.md` on rebuilding it
- `sw/hello/`

## Interfaces

- Board: Cora Z7-07S, part `xc7z007sclg400-1`, Digilent board files, the one pinned Vivado and Vitis version.
- PS settings: `docs/architecture.md`, section 7. FCLK_CLK0 at 100 MHz, M_AXI_GP0 enabled.

## Done when

A second person goes from a fresh clone to a blinking LED and a UART message using only `hw/bd_d1.tcl` and the README.

## Out of scope

- The AXI DMA, HP0 and the loopback test.
- The driver and anything inside `accel_top`.
