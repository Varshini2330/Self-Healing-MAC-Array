 # Fault-Tolerant Self-Healing MAC Array

A hardware-based fault-tolerant MAC array with autonomous fault detection, isolation, dynamic remapping, and recovery using a spare MAC unit. The design is implemented at the RTL level and verified using a SystemVerilog/UVM-based verification environment.

## Overview

Modern AI accelerators rely on highly parallel Multiply-Accumulate (MAC) arrays for neural-network computation. As the number of processing elements increases, individual hardware faults caused by aging, thermal stress, or manufacturing variation can affect system reliability.

This project implements a **Self-Healing MAC Array** that detects faulty MAC units, isolates them from the computation path, dynamically remaps their workload to a standby spare MAC, and restores normal operation without software intervention.

The recovery mechanism is controlled entirely in hardware using a **Mealy FSM**, enabling deterministic fault recovery within an **8-cycle recovery window**.

## Key Features

* Parameterized MAC array architecture
* Real-time fault detection using:

  * Error flag monitoring
  * MAC heartbeat monitoring
* Automatic fault isolation
* LUT-based dynamic MAC remapping
* Hot-standby spare MAC unit
* FSM-controlled self-healing mechanism
* Output MUX for primary/spare path selection
* Hardware-only recovery without software intervention
* Deterministic 8-cycle recovery window
* SystemVerilog/UVM-based functional verification
* 100% functional coverage
* Zero UVM scoreboard errors
* Zero assertion failures
* Single-fault tolerance for the implemented 3×3 MAC array

## Architecture

The system consists of the following major blocks:

```text
                    +----------------------+
Input Data -------->|    Input Buffer      |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
Weights ----------->|     MAC Array       |
                    |       (3 × 3)        |
                    +----------+-----------+
                               |
                 +-------------+-------------+
                 |                           |
                 v                           v
       +-------------------+       +-------------------+
       | Fault Detection   |       | Primary MAC Path  |
       |      Unit (FDU)   |       |                   |
       +---------+---------+       +---------+---------+
                 |                           |
                 | Fault                     |
                 v                           |
       +-------------------+                 |
       | Self-Healing FSM  |                 |
       |    Controller     |                 |
       +---------+---------+                 |
                 |                           |
                 v                           |
       +-------------------+                 |
       | Remapping Unit    |                 |
       |      + LUT        |                 |
       +---------+---------+                 |
                 |                           |
                 v                           |
       +-------------------+                 |
       |   Spare MAC Unit  |                 |
       +---------+---------+                 |
                 |                           |
                 +-------------+-------------+
                               |
                               v
                    +----------------------+
                    |      Output MUX      |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |    Output Buffer     |
                    +----------------------+
```

## Design Components

### 1. MAC Array

The MAC array forms the primary computational fabric. Each MAC performs multiplication between input data and its corresponding weight and accumulates the result.

The implemented design uses a **3×3 MAC array**, with a parameterized architecture intended to support larger configurations.

### 2. Fault Detection Unit

The Fault Detection Unit (FDU) continuously monitors the MAC units.

Fault detection is based on:

* Error flags
* Heartbeat signals

A missed heartbeat or detected error triggers the fault-recovery sequence. The FDU identifies the faulty MAC using its row and column coordinates.

The documented detection latency is **one clock cycle**.

### 3. Self-Healing FSM Controller

The FSM acts as the central recovery controller.

The recovery lifecycle is divided into ten states:

1. Idle
2. Normal Operation
3. Fault Detection
4. Fault Isolation
5. Remapping Calculation
6. Recovery
7. Output Selection
8. Output Verification
9. Return to Normal
10. Error State

A **Mealy FSM** was selected so that recovery control signals can respond directly to fault-related inputs.

### 4. Remapping Unit

The Remapping Unit uses a **Look-Up Table (LUT)** to associate a faulty MAC position with an available spare MAC.

When a fault occurs:

  text
Faulty MAC
    ↓
Fault Coordinates
    ↓
LUT Lookup
    ↓
Spare MAC Selection
    ↓
Updated Routing Address
    ↓
Workload Redirected
```

### 5. Spare MAC

A hot-standby spare MAC remains available during normal operation.

When the FSM activates the spare unit, the workload of the faulty MAC is redirected to the spare MAC.

The current implementation uses **one spare MAC for the 3×3 primary array**, supporting the single-fault scenarios covered by the verification environment.

### 6. Output MUX and Buffer

The Output MUX selects between:

* Primary MAC output
* Spare MAC output

During normal operation, the primary path is selected. During recovery, the FSM switches the output path to the spare MAC.

An output buffer provides an additional cycle of storage for the selected result.

## Fault Recovery Flow

The complete recovery sequence is:

```text
Normal Operation
       |
       v
Fault Detected
       |
       v
Identify Faulty MAC
       |
       v
Isolate Faulty MAC
       |
       v
Calculate Remapping
       |
       v
Activate Spare MAC
       |
       v
Redirect Computation
       |
       v
Select Spare Output
       |
       v
Verify Output
       |
       v
Return to Normal Operation
```

Under nominal conditions, the documented recovery sequence completes within **8 clock cycles**.

## UVM Verification

A SystemVerilog/UVM verification environment was developed to validate both normal MAC operation and fault-recovery behaviour.

### UVM Components

* Sequencer
* Driver
* Monitor
* Scoreboard
* Coverage Collector

### Verification Scenarios

The test environment covers:

* Normal MAC operation
* Fault injection
* Fault detection
* MAC isolation
* Spare MAC remapping
* Output recovery
* Recovery-related corner cases

The scoreboard compares DUT outputs against expected results, while functional and code coverage are collected to evaluate verification completeness.

## Verification Results

| Metric                   |         Result |
| ------------------------ | -------------: |
| Normal Operation Test    |           PASS |
| Fault Detection Test     |           PASS |
| MAC Isolation Test       |           PASS |
| Spare MAC Remapping Test |           PASS |
| Output Recovery Test     |           PASS |
| UVM Scoreboard Errors    |              0 |
| Functional Coverage      |           100% |
| Assertion Failures       |              0 |
| Recovery Latency         | 8 clock cycles |

### Fault-Recovery Example

The documented simulation results include:

* Fault detected at: **60 ns**
* Recovery completed at: **120 ns**
* Faulty MAC: **MAC_3**
* Assigned spare: **MAC_2**

## Interface

### Input Ports

| Port           | Description                           |
| -------------- | ------------------------------------- |
| `clk`          | System clock                          |
| `reset`        | System reset                          |
| `input_data`   | Input data for MAC computation        |
| `weights`      | Weight values used for multiplication |
| `enable`       | Enables MAC array operation           |
| `start`        | Starts computation                    |
| `error_inject` | Fault-injection control for testing   |
| `valid_in`     | Indicates valid input data            |

### Output Ports

| Port             | Description                  |
| ---------------- | ---------------------------- |
| `result`         | Final MAC computation result |
| `valid_out`      | Indicates valid output       |
| `done`           | Indicates completion         |
| `busy`           | Indicates active processing  |
| `fault_detected` | Indicates detected MAC fault |
| `recovery_done`  | Indicates completed recovery |
| `error_out`      | External error indication    |
| `status`         | Current system status        |

## Technologies

* **Verilog / SystemVerilog**
* **RTL Design**
* **Digital Design**
* **Finite State Machines**
* **MAC Architecture**
* **Fault-Tolerant Hardware Design**
* **UVM**
* **Functional Verification**
* **Simulation & Debugging**

## Applications

The architecture is targeted toward reliability-critical computing applications such as:

* AI accelerators
* Edge AI systems
* Autonomous systems
* Medical AI inference
* High-availability communication hardware

## Future Enhancements

Potential extensions include:

* Supporting larger MAC arrays
* Multiple spare MAC units for multi-fault tolerance
* FPGA implementation and hardware validation
* Reducing recovery latency
* Improving accelerator power efficiency
* Enhanced fault-detection mechanisms
* Application to larger AI and edge-computing architectures

## Project Outcome

The project demonstrates an RTL implementation of a fault-tolerant MAC array capable of detecting injected faults, isolating faulty processing elements, dynamically remapping computation to a spare MAC, and verifying the recovered output.

The implementation achieved a documented **8-cycle recovery window**, with all five UVM test sequences passing, **100% functional coverage**, **zero scoreboard errors**, and **zero assertion failures**.

## References

* FORTALESA: Fault-Tolerant Systolic Array, arXiv, 2025
* Accellera Systems Initiative — UVM 1.2 User Guide
* ChipVerify — SystemVerilog & UVM Reference
* SystemVerilog.io — SystemVerilog Language Reference
* MACISH: Designing Approximate MAC Accelerators with Internal Self-Healing
