This folder contains the .jed file that is needed to program the GAL16V8 ic 
that is used for decoding and enabling the ROM, RAM, ACIA and VIA.

The memory map created by this .jed file is as follows:
	C000 - FFFF ==> ROM
	9000 - BFFF ==> Not Used
	8000 - 8FFF ==> Hardware
			8008 & 8009 ==> ACIA
			8010 - 801F ==> VIA
	0000 - 7FFF ==> RAM
	
The GAL .jed file coding was created using WinCupl.

Using the GAL ic reduces the chip count and adds flexablity to the project.  
GALs can be added to extension boards for further decoding needs.




