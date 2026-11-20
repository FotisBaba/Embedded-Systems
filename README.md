# Embedded Systems Labs (ATmega16)

Labs for Embedded Microprocessor Systems (ACE411) at the Technical University of Crete, Fall 2020. The target is an **ATmega16 at 10 MHz**, written in AVR assembly and C in Atmel Studio and tested in its simulator. Each lab folder includes a `.stim` stimulus file.

## Labs

| Folder | Language | What it does |
|---|---|---|
| `Timer` | AVR asm | Delay loop and a Timer/Counter version |
| `Cyclical Counter` | AVR asm | Ring counter on the output port |
| `Serial Port Communication` | AVR asm | Interrupt-driven USART: receives commands and digits, replies `OK`, shows the digits on a multiplexed 7-segment display refreshed by a timer interrupt |
| `Serial Port Communication Variant` | C + asm | The same protocol with `main` in C and the routines in AVR assembly |
| `Serial Port Communication Variant 2` | C | The same protocol, all in C |
| `SPDT Debounce Logic` | C | Switch debouncing, with one version using polling and one using external interrupts |
| `Process Scheduler` | C | A timer-driven scheduler that switches between 3 processes, started and stopped over UART |
| `Cold Start using Watchdog Timer` | C | The serial and 7-segment program with the watchdog timer enabled, so the chip restarts cleanly if it hangs |

## Run

Open a lab in Atmel Studio (or Microchip Studio), select the ATmega16 and the simulator, attach the folder's `.stim` file, and step through.

In some labs, UART input is read from register `r15` instead of `UDR` so the stimulus file can drive it. Swap the marked line back to `UDR` to run on real hardware.
