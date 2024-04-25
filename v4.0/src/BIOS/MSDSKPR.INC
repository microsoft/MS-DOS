; The following structure defines the disk parameter table
; pointed to by Interrupt vector 1EH (location 0:78H)

DISK_PARMS	STRUC
DISK_SPECIFY_1	DB	?
DISK_SPECIFY_2	DB	?
DISK_MOTOR_WAIT DB	?	; Wait till motor off
DISK_SECTOR_SIZ DB	?	; Bytes/Sector (2 = 512)
DISK_EOT	DB	?	; Sectors per track (MAX)
DISK_RW_GAP	DB	?	; Read Write Gap
DISK_DTL	DB	?
DISK_FORMT_GAP	DB	?	; Format Gap Length
DISK_FILL	DB	?	; Format Fill Byte
DISK_HEAD_STTL	DB	?	; Head Settle Time (MSec)
DISK_MOTOR_STRT DB	?	; Motor start delay
DISK_PARMS	ENDS

ROMStatus	equ	1
ROMRead 	equ	2
ROMWrite	equ	3
ROMVerify	equ	4
ROMFormat	equ	5
