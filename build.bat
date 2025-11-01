@echo off
REM ==============================================================================
REM FILE: build.bat
REM
REM DESCRIPTION:
REM Build and flash script for ESP32-C3.
REM
REM BRIEF:
REM Automates assembling, linking, binary extraction, image creation, and flashing.
REM
REM AUTHOR: Kevin Thomas
REM CREATION DATE: November 1, 2025
REM UPDATE DATE: November 1, 2025
REM ==============================================================================

setlocal

set "RISCV_DIR=C:\Espressif\tools\riscv32-esp-elf\esp-14.2.0_20241119\riscv32-esp-elf\bin"
set "PYTHON=C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
set "PORT=COM6"

echo Building ESP32-C3 firmware...

REM ==============================================================================
REM Clean Previous Build Artifacts
REM ==============================================================================
del /q "%~dp0main.o" "%~dp0main_app.o" "%~dp0main.elf" "%~dp0main.bin" "%~dp0full_flash.bin" >nul 2>&1

REM ==============================================================================
REM Verify Toolchain
REM ==============================================================================
if not exist "%RISCV_DIR%\riscv32-esp-elf-as.exe" (
    echo Toolchain missing at %RISCV_DIR%
    goto error
)

REM ==============================================================================
REM Assemble Source File
REM ==============================================================================
"%RISCV_DIR%\riscv32-esp-elf-as.exe" -march=rv32imc_zicsr -mabi=ilp32 -o "%~dp0main.o" "%~dp0main.s"
if errorlevel 1 goto error

REM ==============================================================================
REM Extract Bootloader Section (if present)
REM ==============================================================================
"%RISCV_DIR%\riscv32-esp-elf-objcopy.exe" --dump-section .boot="%~dp0bootloader.bin" "%~dp0main.o" >nul 2>&1

REM ==============================================================================
REM Remove Boot Section and Prepare App Object
REM ==============================================================================
"%RISCV_DIR%\riscv32-esp-elf-objcopy.exe" --remove-section .boot "%~dp0main.o" "%~dp0main_app.o"
if errorlevel 1 goto error

REM ==============================================================================
REM Link Object File into ELF
REM ==============================================================================
"%RISCV_DIR%\riscv32-esp-elf-ld.exe" -T "%~dp0linker.ld" -Ttext=0x42010000 -e Reset -o "%~dp0main.elf" "%~dp0main_app.o"
if errorlevel 1 goto error

REM ==============================================================================
REM Extract Sections and Create Application Binary
REM ==============================================================================
"%RISCV_DIR%\riscv32-esp-elf-objcopy.exe" --dump-section .text="%~dp0tmp_text.bin" "%~dp0main.elf"
if errorlevel 1 goto error

"%RISCV_DIR%\riscv32-esp-elf-objcopy.exe" --dump-section .data="%~dp0tmp_data.bin" "%~dp0main.elf"
if errorlevel 1 goto error

copy /b "%~dp0tmp_text.bin"+"%~dp0tmp_data.bin" "%~dp0main.bin" >nul
if errorlevel 1 goto error

del /q "%~dp0tmp_text.bin" "%~dp0tmp_data.bin"

REM ==============================================================================
REM Verify Bootloader Presence
REM ==============================================================================
if not exist "%~dp0bootloader.bin" (
    echo bootloader.bin missing
    goto error
)

REM ==============================================================================
REM Create Full Flash Image
REM ==============================================================================
"%PYTHON%" "%~dp0create_full_flash.py" --add-header --boot-off 0x0 --app "%~dp0main.bin" --out "%~dp0full_flash.bin" --boot "%~dp0bootloader.bin"
if errorlevel 1 goto error

REM ==============================================================================
REM Flash Firmware to Device
REM ==============================================================================
echo Flashing to %PORT%...
"%PYTHON%" -m esptool --chip esp32c3 --port %PORT% write_flash 0x0 "%~dp0full_flash.bin"
if errorlevel 1 goto error

del /q "%~dp0full_flash.bin"

REM ==============================================================================
REM Success Message
REM ==============================================================================
echo.
echo =================================
echo SUCCESS! Firmware flashed to ESP32-C3
echo =================================
echo.
goto end

REM ==============================================================================
REM Error Handling
REM ==============================================================================
:error
echo.
echo BUILD FAILED!
echo.

:end
endlocal
exit /b 0
