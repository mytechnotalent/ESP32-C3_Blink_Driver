<img src="https://github.com/mytechnotalent/ESP32-C3_Blink_Driver/blob/main/ESP32-C3_Blink_Driver.png?raw=true">

## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)
### VIDEO PROMO [HERE](https://www.youtube.com/watch?v=aD7X9sXirF8)

<br>

# ESP32-C3 Blink Driver
An ESP32-C3 blink driver written entirely in RISC-V Assembler.

<br>

# Install ESP Toolchain
## Windows Installer [HERE](https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/windows-setup.html)
## Linux and macOS Installer [HERE](https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/linux-macos-setup.html)

<br>

# Hardware
## ESP32-C3 Super Mini [BUY](https://www.amazon.com/Teyleten-Robot-Development-Supermini-Bluetooth/dp/B0D47G24W3)
## USB-C to USB Cable [BUY](https://www.amazon.com/USB-Cable-10Gbps-Transfer-Controller/dp/B09WKCT26M)
## Complete Component Kit for Raspberry Pi [BUY](https://www.pishop.us/product/complete-component-kit-for-raspberry-pi)
## 10pc 25v 1000uF Capacitor [BUY](https://www.amazon.com/Cionyce-Capacitor-Electrolytic-CapacitorsMicrowave/dp/B0B63CCQ2N?th=1)
### 10% PiShop DISCOUNT CODE - KVPE_HS320548_10PC

<br>

# main.s Code
```
/*
 * FILE: main.s
 *
 * DESCRIPTION:
 * ESP32-C3 Bare-Metal GPIO0 Blink Example.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 14, 2025
 */

.include "inc/registers.inc"

/**
 * Initialize the .text.init section.
 * The .text.init section contains executable code.
 */
.section .text

/**
 * @brief   Main application entry point.
 *
 * @details Implements the infinite blink loop.
 *
 * @param   None
 * @retval  None
 */
.global main
.type main, %function
main:
  li    a0, 0                                    # pin number 0
  jal   gpio_output_enable                       # call gpio_output_enable
.loop:
  li    a0, 0                                    # pin number 0
  jal   gpio_toggle                              # call gpio_toggle
  li    a0, 500                                  # 500 ms delay
  jal   delay_ms                                 # call delay_ms
  j     .loop									                   # jump to .loop
.size main, .-main
```

<br>

# License
[Apache License 2.0](https://github.com/mytechnotalent/ESP32-C3_Blink_Driver/blob/main/LICENSE)
