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
  j     .loop                                    # jump to .loop
.size main, .-main
