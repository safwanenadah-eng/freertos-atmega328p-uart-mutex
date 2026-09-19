# FreeRTOS Thread-Safe UART Communication Driver on ATmega328P

## 📌 Executive Summary

In safety-critical real-time embedded systems, hardware peripherals such as **UART buses, SPI controllers, and CAN transceivers** are frequently shared among multiple concurrent tasks. Without strict mutual exclusion, preemption during a multi-byte transmission leads to **race conditions, interleaved data frames, and telemetry corruption**.

This repository provides a bare-metal, production-grade **Thread-Safe UART Driver** implemented on the **ATmega328P 8-bit AVR microcontroller** running **FreeRTOS**. It demonstrates how **RTOS Mutex primitives** guarantee atomic string transmissions across concurrent tasks without sacrificing real-time determinism or scheduler responsiveness.

## 🏭 Real-World & Industrial Relevance

In mission-critical sectors (**Aeronautics, Defense, Automotive, and Space**), resource sharing is a fundamental design challenge. This project models architecture patterns used in:

### 1. Flight Data Recorders & Avionics Telemetry (e.g., Safran / Thales)

* **Scenario:** Independent tasks monitoring core parameters (engine temperature, hydraulic pressure, flight surface angles) output log streams to a single downlink or flash-storage bus.

* **Impact:** Interleaved bytes corrupt telemetry frames, causing checksum failures and ground station parse errors. Mutex protection guarantees complete, uncorrupted log packet serialization.

### 2. Automotive Electronic Control Units (ECUs) & ADAS

* **Scenario:** High-priority safety diagnostic tasks and low-priority system status monitors output diagnostic codes over a shared ISO-14229 / K-Line / UART interface.

* **Impact:** Mutexes ensure critical warning frames (e.g., `[CRITICAL_OVERHEAT]`) are transmitted atomically without fragmenting system status lines.

### 3. Industrial IoT & Sensor Gateways

* **Scenario:** Multiple sensor polling tasks transmit serialized JSON/Modbus frames via an RS-485 / Modbus transceiver.

## 🛠 Hardware & System Architecture

```
                       +---------------------------------------------------+
                       |                 ATmega328P (16MHz)                |
                       |                                                   |
                       |   +------------------+     +------------------+   |
                       |   |    vTask1()      |     |    vTask2()      |   |
                       |   | (Priority: 1)   |     | (Priority: 1)   |   |
                       |   +--------+---------+     +--------+---------+   |
                       |            |                        |             |
                       |            +-----------+------------+             |
                       |                        |                          |
                       |             xSemaphoreTake(xUARTMutex)            |
                       |                        v                          |
                       |             +---------------------+               |
                       |             |  UART_SendString_   |               |
                       |             |       Safe()        |               |
                       |             +----------+----------+               |
                       |                        |                          |
                       |              xSemaphoreGive(xUARTMutex)           |
                       |                        |                          |
                       |                        v                          |
                       |               +-----------------+                 |
                       |               |   HW UART /     |                 |
                       |               |  UDR0 Register  |                 |
                       +---------------+--------+--------+-----------------+
                                                |
                                            TXD | (PD1)
                                                v
                                      +-------------------+
                                      |  Virtual Terminal |
                                      |    (9600-8-N-1)   |
                                      +-------------------+

```

### System Configuration

* **Microcontroller:** Microchip ATmega328P (8-bit AVR, 32KB Flash, 2KB SRAM)

* **Clock Frequency:** 16.0 MHz (`configCPU_CLOCK_HZ = 16000000UL`)

* **Real-Time Kernel:** FreeRTOS V7.1.0

* **Tick Rate:** 1000 Hz (1ms per system tick)

* **Heap Management:** `heap_1.c` (Static Allocation Scheme suitable for safety-certified systems)

## 🔬 Implementation Details

### Hardware UART Initialization (`uart.c`)

The UART interface operates bare-metal by manipulating register values directly for low latency and minimal overhead:

```
void UART_Init(uint32_t baud)
{
    uint16_t ubrr = (F_CPU / (16UL * baud)) - 1;
    
    UBRR0H = (uint8_t)(ubrr >> 8);
    UBRR0L = (uint8_t)ubrr;

    /* Enable transmitter */
    UCSR0B = (1 << TXEN0);

    /* Frame format: 8 data bits, 1 stop bit, no parity */
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);

    /* Create Mutex for Thread Safety */
    xUARTMutex = xSemaphoreCreateMutex();
}

```

### Thread-Safe Wrapper with Mutex Locking (`uart.c`)

Access to `UART_SendChar()` is serialized through `xSemaphoreTake()` and `xSemaphoreGive()`:

```
void UART_SendString_Safe(const char *str)
{
    if (xUARTMutex != NULL)
    {
        /* Block indefinitely until Mutex becomes available */
        if (xSemaphoreTake(xUARTMutex, portMAX_DELAY) == pdTRUE)
        {
            while (*str != '\0')
            {
                UART_SendChar(*str);
                str++;
            }
            /* Release resource for next task */
            xSemaphoreGive(xUARTMutex);
        }
    }
}

```

## 📊 Experimental Results & Simulation Validation

The system was compiled with `avr-gcc` and validated under **Proteus 8 VSM** using the Virtual Terminal component.

### Comparison Table

| Feature | Unprotected Transmission (`UART_SendString`) | Mutex Protected Transmission (`UART_SendString_Safe`) | 
 | ----- | ----- | ----- | 
| **Context Switch Handling** | Preempts mid-string transmission | Blocks competing task until transmission finishes | 
| **Data Integrity** | **Corrupted / Interleaved** | **100% Atomic & Legible** | 
| **System Stability** | High risk of parsing failures in receivers | Predictable, deterministic serial output | 

### Output Verification

#### Unsafe Transmission (Race Condition Present)

> `[TASK 1] Hel[TASK 2] >>> CRITICAL WARNING <<<lo World! Executing task 1...`

#### Mutex-Protected Transmission (Thread-Safe)

```
[TASK 2] >>> CRITICAL WARNING FROM TASK 2 <<<
[TASK 1] Hello World! Executing task 1...
[TASK 2] >>> CRITICAL WARNING FROM TASK 2 <<<
[TASK 1] Hello World! Executing task 1...

```

## 📁 Repository Structure

```
.
├── FreeRTOS_Source/        # FreeRTOS Kernel Core Sources & Portable Layer
│   ├── include/            # Kernel Headers (FreeRTOS.h, task.h, semphr.h)
│   └── source/             # Core C Files (tasks.c, queue.c, list.c, heap_1.c)
├── FreeRTOSConfig.h        # Kernel Configuration Settings
├── main.c                  # Task definitions and Scheduler Entry point
├── uart.h                  # Hardware UART & Mutex Interface API
├── uart.c                  # Bare-metal UART implementation
├── Makefile                # AVR-GCC Build Automation Script
└── README.md               # Documentation

```

## ⚙️ Building & Running

### Prerequisites

* **Toolchain:** `avr-gcc`, `avr-libc`, `binutils-avr`

* **Build System:** `GNU Make`

* **Simulator:** Proteus VSM or `simavr`

### Compilation Commands

1. **Clean workspace:**

   ```
   make clean
   
   ```

2. **Compile and link project:**

   ```
   make
   
   ```

   *Generates `main.elf` and `main.hex` targets.*

3. **Load Hex File:**

   * Open the `.pdsprj` Proteus schematic.

   * Double-click the ATmega328P chip.

   * Point **Program File** to `main.hex`.

   * Set **Clock Frequency** to `16MHz`.

   * Run the simulation and observe the **Virtual Terminal**.

## 🚀 Key Engineering Takeaways

1. **Mutex vs. Binary Semaphore:** Mutexes feature an internal **Priority Inheritance Mechanism** that prevents **Priority Inversion** when higher-priority tasks request shared hardware peripherals.

2. **Resource Footprint:** Configured FreeRTOS kernel memory usage optimized for 2KB SRAM ATmega328P by tuning `configTOTAL_HEAP_SIZE` (1500 bytes) and disabling unused features (`configUSE_CO_ROUTINES = 0`).

3. **Build System Optimization:** Custom Makefile configured to include correct portable memory managers (`heap_1.c`) and platform specifiers (`-mmcu=atmega328p`).

## 👤 Author

* **Project Developer:** Embedded Systems Engineer

* **Target Industry:** Avionics, Defense, and Real-Time Embedded Software (Safran / Thales Focus)