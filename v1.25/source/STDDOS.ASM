	TITLE	MS-DOS version 1.25 by Tim Paterson     March 3, 1982
	PAGE	60,132
; Use the following booleans to set the switches 
FALSE	EQU	0
TRUE	EQU	NOT FALSE

; Use the switches below to produce the standard Microsoft version of the IBM
; version of the operating system
MSVER	EQU	TRUE
IBM	EQU	FALSE

; Set this switch to cause DOS to move itself to the end of memory
HIGHMEM	EQU	FALSE

; Turn on switch below to allow testing disk code with DEBUG. It sets
; up a different stack for disk I/O (functions > 11) than that used for
; character I/O which effectively makes the DOS re-entrant.

DSKTEST	EQU	FALSE

	INCLUDE	MSDOS.ASM

