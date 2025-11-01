/**
 * FILE: linker.ld
 *
 * DESCRIPTION:
 * ESP32-C3 Minimal Linker Script for bare‑metal development.
 *
 * BRIEF:
 * Defines memory regions for flash, XIP, and DRAM.  
 * Places the .text section in the XIP region with its load address
 * offset into flash at 0x10000, ensuring the binary can be written
 * directly to flash at that offset.  
 * The .data section is placed in DRAM but loaded from flash immediately 
 * after `.text` and the .bss resides in DRAM with proper alignment.  
 * Provides heap and stack symbols, ensuring _stack_top is at the end of DRAM
 * and _heap_end leaves 1 KB reserved below the stack.  
 * Discards unnecessary sections like .comment.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 1, 2025
 * UPDATE DATE: Novermber 1, 2025
 */

MEMORY
{
  /* Physical flash (LMA) */
  flash (rx)  : ORIGIN = 0x00000000, LENGTH = 0x00400000
  /* XIP virtual mapping for flash when executed: 0x42000000 + flash_offset */
  xip (rx)    : ORIGIN = 0x42000000, LENGTH = 0x00400000
  dram0_0_seg (rwx) : ORIGIN = 0x3FFB0000, LENGTH = 0x00040000
  /* helper regions: rodata loads from flash, code VMA lives in XIP region */
  default_rodata_seg (rx) : ORIGIN = ORIGIN(flash), LENGTH = LENGTH(flash)
  default_code_seg (rx) : ORIGIN = ORIGIN(xip), LENGTH = LENGTH(xip)
}

SECTIONS
{
  . = ALIGN(4);
  /* Place executable VMA in XIP region, but set LMA to the flash offset (0x10000)
     so the generated binary can be written directly to flash at that offset. */
  .text : AT(ORIGIN(flash) + 0x10000)
  {
    _stext = .;
    *(.text .text.* .glue_7 .glue_7t)
    *(.rodata .rodata.* .constdata .constdata.*)
    . = ALIGN(4);
    _etext = .;
  } > default_code_seg

  .data : AT(ADDR(.text) + SIZEOF(.text))
  {
    _la_data = LOADADDR(.data);
    _sdata = .;
    *(.data .data.* .sdata .sdata.*)
    . = ALIGN(4);
    _edata = .;
  } > default_rodata_seg

  .bss (NOLOAD) :
  {
    _sbss = .;
    *(.bss .bss.* .sbss .sbss.* COMMON)
    . = ALIGN(8);
    _ebss = .;
  } > dram0_0_seg

  PROVIDE(_heap_start = _ebss);
  PROVIDE(_stack_top = ORIGIN(dram0_0_seg) + LENGTH(dram0_0_seg));
  PROVIDE(_heap_end = _stack_top - 0x400);

  PROVIDE(_la_data = _la_data);
  PROVIDE(_sdata = _sdata);
  PROVIDE(_edata = _edata);
  PROVIDE(_sbss = _sbss);
  PROVIDE(_ebss = _ebss);

  /DISCARD/ : { *(.comment) }
}
