# RISC-V Multicycle CPU

A multicycle RISC-V processor written in Verilog, built step by step during the labs of EPFL's CS-200 *Computer Architecture* course (fall 2025): from a program in RISC-V assembly, to the ALU, to a full CPU with memory-mapped peripherals and interrupt handling. Everything is simulated with Verilator on the course's Gecko board model.

## Labs

### Lab A: Game of Life in RISC-V assembly
[`lab-a-game-of-life/`](lab-a-game-of-life)

Conway's Game of Life written in RISC-V assembly (`gol.s`, about 1,000 lines) for the Gecko board. The grid is shown on the LED matrix, the board's buttons control the game (start, pause, speed, random seed) and the step counter appears on the 7-segment display.

### Lab B: building the CPU
[`lab-b-cpu/`](lab-b-cpu)

- **Part 1, ALU**: adder/subtractor, comparator, logic unit and shift unit, with testbenches
- **Part 2, multicycle CPU**: the CPU datapath, and a testbench for the register file
- **Part 3, the complete CPU**: register file, program counter, instruction register, decoder and a controller written as a finite-state machine that executes each instruction over several cycles, connected to external memory and to memory-mapped peripherals (LEDs, buttons, 7-segment display). It is tested with an assembly program covering arithmetic, branches and memory accesses.

### Lab C: interrupts
[`lab-c-interrupts/`](lab-c-interrupts)

The CPU extended with machine-mode interrupt support: a CSR unit (`mstatus`, `mie`, `mtvec`, `mepc`, `mcause`, `mip`), the `mret` instruction and button interrupts, with an assembly program that installs an interrupt handler and reacts to button presses.

## Running

Requirements: Verilator, a RISC-V GCC toolchain and `make`. Each part with a `Makefile` builds the simulator and runs the assembly program on the simulated CPU.

## Notes

- The Gecko board model, the Verilator debug harness (`src/`), the linker scripts and `alu.v` (a pre-synthesised netlist) were provided by the course.
- The labs were completed on EPFL's virtual machines; each lab is committed at the date it was finished.
