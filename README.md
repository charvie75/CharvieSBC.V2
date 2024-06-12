# CharvieSBC.V2

This project was inspired by Ben Eater's YOUTUBE series. I, like many others, started my computer experience with the 6502 based computers.

Where this board differs from Ben's breadboard computer is that I use a GAL16V8D for the decode logic, a MC68B50 for an ACIA, a 1.8432Mhz osc for the cpu clock and baud rate generation and a CP2102 Micro USB to Serial adapter for terminal connection.

I also use a MCP130-450 power supervisor for the reset circuit. This allows for 'clean' 'no bounce' resets. It will also put the 65C02 in reset if Vcc falls below +4.35v.

The ACIA runs at 115200 baud.

If the LM7805 is used the input power can be either +9vdc or +12vdc. If you use a +5vdc source don't install the LM7805, just put a jumper between the pin 1 and 3.

Using the GAL16V8D ic allows flexible decoding. Coding of the GAL16V8D was done via WinCupl.

The memory map created by this .jed file is as follows:
	C000 - FFFF ==> ROM
	9000 - BFFF ==> Not Used
	8000 - 8FFF ==> Hardware
			8008 & 8009 ==> ACIA
			8010 - 801F ==> VIA
	0000 - 7FFF ==> RAM

I have developed a basic OS.
There are two versions of the OS. One can be loaded into a 16k EEROM. It does not have ehbasic.
The other is loaded into a 32k EEROM and does include a version of ehbasic.

The KERNAL is run at power up or reset.  It test RAM and writes the startup meeages to the terminal.  Most of these startup routines were borrowed and modified from VIC20 code.  It also includes a few usful routines that can be used when writing code.

ILOAD is an Intel HEX loader program that I 'borrowed' from D. Hansel's smon.asm files.
(https://github.com/dhansel/smon6502)
This allows code to be loaded into RAM and exit directly into WOZMON. Then using the WOZMON 'R' command the code can be run.

ClearRAM just writes $00 to all RAM locations from $0400 to $7FFF.

WOZMON is modified to show 16 values per line instead of 8.  the echo feature is removed and the kernal TXCHAR routine is used in it's place.

If there are any questions I can be reached at the following email address: charvie7190@gmail.com.
