# UART_Loopback

This project implements a UART (Universal Asynchronous Receiver/Transmitter) on an FPGA to demonstrate loopback communication between a PC and the FPGA.

The data path of UART Loopback starts from PC(PuTTY) -> UART_Rx -> FIFO -> UART_Tx -> PC

## UART_Loopback Architecture
![UART_Loopback](doc/UART_Loopback.png)

## Features
- External loopback (PC -> FPGA -> PC) operation
- Verified via simulation (ILA, VIO) and hardware

## PuTTY Setup
- Session Tab -> Serial line: COM8, baudrate = 9600
- Terminal Tab -> Line discipline options -> Local echo -> Force on
- SSH -> Serial -> Flow control -> None

## Result
![UART_Loopback](doc/UART_Loopback_result.png)
> Although you typed each letter just once, you may feel like each letter is typed twice.
