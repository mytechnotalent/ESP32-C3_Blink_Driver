/*
 * FILE: main.s
 *
 * DESCRIPTION:
 * ESP32-C3 Bare-Metal GPIO8 Blink
 *
 * BRIEF:
 * Minimal bare‑metal LED blink on the ESP32-C3 using the direct
 * instructions to manipulate GPIO control registers. This bypasses
 * SDK abstractions and demonstrates register‑level control in assembler.
 * External crystal is 40 MHz; CPU runs at 80 MHz by default.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: October 24, 2025
 * UPDATE DATE: November 1, 2025
 */

/**
 * Memory addresses and constants.
 */
.equ TIMG0_BASE,                0x6001F000
.equ TIMG_WDTCONFIG0_REG,       TIMG0_BASE + 0x48
.equ TIMG_WDTFEED_REG,          TIMG0_BASE + 0x60
.equ TIMG_WDTWPROTECT_REG,      TIMG0_BASE + 0x64
.equ RTC_CNTL_BASE,             0x60008000
.equ RTC_CNTL_WDTCONFIG0_REG,   RTC_CNTL_BASE + 0x90
.equ RTC_CNTL_WDT_FEED_REG,     RTC_CNTL_BASE + 0xA4
.equ RTC_CNTL_WDTWPROTECT_REG,  RTC_CNTL_BASE + 0xA8
.equ RTC_CNTL_SWD_CONF_REG,     RTC_CNTL_BASE + 0xAC
.equ RTC_CNTL_SWD_WPROTECT_REG, RTC_CNTL_BASE + 0xB0
.equ GPIO_BASE,                 0x60004000
.equ GPIO_OUT_W1TS_REG,         GPIO_BASE + 0x08
.equ GPIO_OUT_W1TC_REG,         GPIO_BASE + 0x0C
.equ GPIO_ENABLE_W1TS_REG,      GPIO_BASE + 0x24
.equ APP_ENTRY,                 0x42010000

/**
 * Boot stub entry point.
 */
.section .boot
.align 2
.global Reset_Boot
.type Reset_Boot, %function
Reset_Boot:
  .space 8                                       # reserve 8 bytes for Direct Boot magic
  lui   t0, %hi(_stack_top)                      # load stack top high half
  addi  t0, t0, %lo(_stack_top)                  # add low half
  addi  sp, t0, 0                                # set stack pointer
  li    t1, 0x50d83aa1                           # TIMG0 WDT: unlock key value
  lui   t2, %hi(TIMG_WDTWPROTECT_REG)            # TIMG0 WDT protect register high
  addi  t2, t2, %lo(TIMG_WDTWPROTECT_REG)        # add low part
  sw    t1, 0(t2)                                # write unlock key
  lui   t2, %hi(TIMG_WDTCONFIG0_REG)             # TIMG0 WDT configuration register high
  addi  t2, t2, %lo(TIMG_WDTCONFIG0_REG)         # add low part
  lw    t3, 0(t2)                                # read current config
  li    t4, 0xFFFFBFFF                           # mask to clear enable bit
  and   t3, t3, t4                               # disable TIMG0 WDT
  sw    t3, 0(t2)                                # write updated config
  lw    t3, 0(t2)                                # re-read for modify
  li    t4, 1<<22                                # set flashboot feed bit (keep ROM happy)
  or    t3, t3, t4                               # OR flashboot bit into config
  sw    t3, 0(t2)                                # write updated config
  lui   t2, %hi(TIMG_WDTFEED_REG)                # TIMG0 WDT feed register high
  addi  t2, t2, %lo(TIMG_WDTFEED_REG)            # add low part
  li    t3, 1                                    # feed value
  sw    t3, 0(t2)                                # feed TIMG0 WDT once
  lui   t2, %hi(TIMG_WDTWPROTECT_REG)            # TIMG0 WDT protect register high (lock)
  addi  t2, t2, %lo(TIMG_WDTWPROTECT_REG)        # add low part
  li    t3, 0                                    # lock value
  sw    t3, 0(t2)                                # lock TIMG0 WDT register
  li    t1, 0x50d83aa1                           # RTC WDT: unlock key value
  lui   t2, %hi(RTC_CNTL_WDTWPROTECT_REG)        # RTC WDT protect register high
  addi  t2, t2, %lo(RTC_CNTL_WDTWPROTECT_REG)    # add low part
  sw    t1, 0(t2)                                # write unlock key
  lui   t2, %hi(RTC_CNTL_WDTCONFIG0_REG)         # RTC WDT config register high
  addi  t2, t2, %lo(RTC_CNTL_WDTCONFIG0_REG)     # add low part
  lw    t3, 0(t2)                                # read current config
  li    t4, 0xFFFFEFFF                           # mask to clear enable bit
  and   t3, t3, t4                               # disable RTC WDT
  sw    t3, 0(t2)                                # write updated config
  lui   t2, %hi(RTC_CNTL_WDT_FEED_REG)           # RTC WDT feed register high
  addi  t2, t2, %lo(RTC_CNTL_WDT_FEED_REG)       # add low part
  li    t3, 1                                    # feed value
  sw    t3, 0(t2)                                # feed RTC WDT once
  lui   t2, %hi(RTC_CNTL_WDTWPROTECT_REG)        # RTC WDT protect register high (lock)
  addi  t2, t2, %lo(RTC_CNTL_WDTWPROTECT_REG)    # add low part
  li    t3, 0                                    # lock value
  sw    t3, 0(t2)                                # lock RTC WDT register
  li    t1, 0x8f1d312a                           # RTC SWD: unlock key value
  lui   t2, %hi(RTC_CNTL_SWD_WPROTECT_REG)       # RTC SWD protect register high
  addi  t2, t2, %lo(RTC_CNTL_SWD_WPROTECT_REG)   # add low part
  sw    t1, 0(t2)                                # write unlock key
  lui   t2, %hi(RTC_CNTL_SWD_CONF_REG)           # RTC SWD configuration register high
  addi  t2, t2, %lo(RTC_CNTL_SWD_CONF_REG)       # add low part
  lw    t3, 0(t2)                                # read current config
  li    t4, 1<<30                                # mask to disable super watchdog
  or    t3, t3, t4                               # OR disable bit
  sw    t3, 0(t2)                                # write updated config
  lui   t2, %hi(RTC_CNTL_SWD_WPROTECT_REG)       # RTC SWD protect register high (lock)
  addi  t2, t2, %lo(RTC_CNTL_SWD_WPROTECT_REG)   # add low part
  li    t3, 0                                    # lock value
  sw    t3, 0(t2)                                # lock RTC SWD register
  li    t5, 100                                  # simple post-config delay count
1:
  addi  t5, t5, -1                               # decrement delay counter
  bnez  t5, 1b                                   # loop until zero
  lui   t1, %hi(APP_ENTRY)                       # load application entry address high
  addi  t1, t1, %lo(APP_ENTRY)                   # add low part
  jalr  x0, t1, 0                                # branch to application entry (no return)
.size Reset_Boot, .-Reset_Boot

/**
 * Initialize the .text section. 
 * The .text section contains executable code.
 */
.section .text
.align 2

/**
 * @brief   Reset handler for ESP32-C3.
 *
 * @details Provide a simple jump to main.
 *
 * @param   None
 * @retval  None
 */
.global Reset_Handler
.type Reset_Handler, %function
Reset_Handler:
  j main                                         # jump to main
.size Reset_Handler, .-Reset_Handler

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
  li    t6, 1                                    # load 1
  sll   t6, t6, 8                                # shift left 8 → GPIO8 bit mask
  lui   t2, %hi(GPIO_ENABLE_W1TS_REG)            # GPIO enable set register high
  addi  t2, t2, %lo(GPIO_ENABLE_W1TS_REG)        # add low part
  sw    t6, 0(t2)                                # enable GPIO8 output
  j     Loop                                     # jump to blink loop
.size main, .-main

/**
 * @brief   Delay_MS.
 *
 * @details
 *   Provides a simple busy‑loop delay routine:
 *   - Input in a0 = number of milliseconds
 *   - Each millisecond ≈ 5000 loop iterations (empirically calibrated for ESP32‑C3 @ 80 MHz)
 *   - Returns when the requested time has elapsed
 *
 * @param   a0 - milliseconds
 * @retval  None
 */
.global Delay_MS
.type Delay_MS, %function
Delay_MS:
.Delay_MS_Check:
  blez  a0, .Delay_MS_Done                       # if ms <= 0, skip delay
.Delay_MS_Setup:
  li    t1, 5000                                 # loops per ms (empirical constant)
  mul   t1, a0, t1                               # total loop count = ms * 5000
.Delay_MS_Loop:
  addi  t1, t1, -1                               # decrement loop counter
  bnez  t1, .Delay_MS_Loop                       # branch until zero
.Delay_MS_Done:
  ret                                            # return to caller
.size Delay_MS, .-Delay_MS

/**
 * @brief   Loop routine to blink GPIO8 at ~1 Hz.
 *
 * @details
 *   Provides a simple LED blink routine on GPIO8:
 *   - Sets GPIO8 high for ~500 ms
 *   - Sets GPIO8 low for ~500 ms
 *   - Loops indefinitely
 *
 * @param   None
 * @retval  None
 */
.global Loop
.type Loop, %function
Loop:
.Loop_Setup:
  li    t0, 1                                    # load 1
  sll   t0, t0, 8                                # shift left 8 → GPIO8 bit mask
  lui   t2, %hi(GPIO_BASE)                       # GPIO base high part
  addi  t2, t2, %lo(GPIO_BASE)                   # add low part → t2 = GPIO base
  lui   t3, %hi(GPIO_OUT_W1TS_REG)               # GPIO_OUT_W1TS_REG high part
  addi  t3, t3, %lo(GPIO_OUT_W1TS_REG)           # add low part → t3 = GPIO_OUT_W1TS_REG
.Loop_On:
  sw    t0, GPIO_OUT_W1TS_REG - GPIO_BASE(t2)    # set GPIO8 high (LED on)
  li    a0, 500                                  # 500 ms
  jal   ra, Delay_MS                             # call delay
  sw    t0, GPIO_OUT_W1TC_REG - GPIO_BASE(t2)    # clear GPIO8 low (LED off)
  li    a0, 500                                  # 500 ms
  jal   ra, Delay_MS                             # call delay
  j     .Loop_On                                 # repeat forever
.size Loop, .-Loop

/**
 * Test data and constants.
 * The .rodata section is used for constants and static data.
 */
.section .rodata                                 # read-only data section

/**
 * Initialized global data.
 * The .data section is used for initialized global or static variables.
 */
.section .data                                   # data section

/**
 * Uninitialized global data.
 * The .bss section is used for uninitialized global or static variables.
 */
.section .bss                                    # BSS section
