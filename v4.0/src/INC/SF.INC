;	SCCSID = @(#)sf.asm	1.1 85/04/10
BREAK <Internal system file table format>
;
;   AN000   version 4.00   Jan. 1988
;   AN003   PTM 3680 --  make NAME offset the same as before (<=3.30)
;   AN009   PTM 3839	 reorder SFT for MS WINDOWS

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
;
; system file table
;

SF		STRUC
SFLink		DD	?
SFCount 	DW	?		; number of entries
SFTable 	DW	?		; beginning of array of the following
SF		ENDS

;
; system file table entry
;

sf_entry	STRUC
sf_ref_count	DW	?		; number of processes sharing entry
					;   if FCB then ref count
sf_mode 	DW	?		; mode of access or high bit on if FCB
sf_attr 	DB	?		; attribute of file
sf_flags	DW	?		;Bits 8-15
					; Bit 15 = 1 if remote file
					;	 = 0 if local file or device
					; Bit 14 = 1 if date/time is not to be
					;   set from clock at CLOSE.  Set by
					;   FILETIMES and FCB_CLOSE.  Reset by
					;   other reseters of the dirty bit
					;   (WRITE)
					; Bit 13 = Pipe bit (reserved)
					;
					; Bits 0-7 (old FCB_devid bits)
					; If remote file or local file, bit
					; 6=0 if dirty Device ID number, bits
					; 0-5 if local file.
					; bit 7=0 for local file, bit 7
					;      =1 for local I/O device
					; If local I/O device, bit 6=0 if EOF (input)
					;		Bit 5=1 if Raw mode
					;		Bit 0=1 if console input device
					;		Bit 1=1 if console output device
					;		Bit 2=1 if null device
					;		Bit 3=1 if clock device
sf_devptr	DD	?		; Points to DPB if local file, points
					; to device header if local device,
					; points to net device header if
					; remote
sf_firclus	DW	?		; First cluster of file (bit 15 = 0)
sf_time 	DW	?		; Time associated with file
sf_date 	DW	?		; Date associated with file
sf_size 	DD	?		; Size associated with file
sf_position	DD	?		; Read/Write pointer or LRU count for FCBs
;
; Starting here, the next 7 bytes may be used by the file system to store an
; ID
;
sf_cluspos	DW	?		; Position of last cluster accessed
sf_dirsec	DD	?		; Sector number of directory sector for
					; for this file
sf_dirpos	DB	?		; Offset of this entry in the above
;
; End of 7 bytes of file-system specific info.
;
sf_name 	DB	11 DUP (?)	; 11 character name that is in the
					; directory entry.  This is used by
					; close to detect file deleted and
					; disk changed errors.

; SHARING INFO
sf_chain	DD	?		; link to next SF
sf_UID		DW	?
sf_PID		DW	?
sf_MFT		DW	?
sf_lstclus	DW	?		;AN009; Last cluster accessed
sf_IFS_HDR	DD	?
sf_entry	ENDS

sf_fsda 	EQU	BYTE PTR sf_cluspos	     ;DOS 4.00
sf_serial_ID	EQU	WORD PTR sf_firclus	     ;DOS 4.00
sf_netid	EQU	BYTE PTR sf_cluspos
sf_OpenAge	EQU	WORD PTR sf_position+2
sf_LRU		EQU	WORD PTR sf_position

sf_default_number   EQU     5h

;
; Note that we need to mark an SFT as being busy for OPEN/CREATE.  This is
; because an INT 24 may prevent us from 'freeing' it.  We mark this as such
; by placing a -1 in the ref_count field.
;

sf_busy EQU -1


; mode mask for FCB detection
sf_isfcb		EQU	1000000000000000B

; Flag word masks
sf_isnet		EQU	1000000000000000B
sf_close_nodate 	EQU	0100000000000000B
sf_pipe 		EQU	0010000000000000B
sf_no_inherit		EQU	0001000000000000B
sf_net_spool		EQU	0000100000000000B
Handle_Fail_I24 	EQU	0000000100000000B  ;BIT 8 - DISK FULL I24 ERROR

; Local file/device flag masks
devid_file_clean	EQU	40h	; true if file and not written
devid_file_mask_drive	EQU	3Fh	; mask for drive number

devid_device		EQU	80h	; true if a device
devid_device_EOF	EQU	40h	; true if end of file reached
devid_device_raw	EQU	20h	; true if in raw mode
devid_device_special	EQU	10h	; true if special device
devid_device_clock	EQU	08h	; true if clock device
devid_device_null	EQU	04h	; true if null device
devid_device_con_out	EQU	02h	; true if console output
devid_device_con_in	EQU	01h	; true if consle input
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

;
; structure of devid field as returned by IOCTL is:
;
;	BIT	7   6	5   4	3   2	1   0
;	      |---|---|---|---|---|---|---|---|
;	      | I | E | R | S | I | I | I | I |
;	      | S | O | A | P | S | S | S | S |
;	      | D | F | W | E | C | N | C | C |
;	      | E |   |   | C | L | U | O | I |
;	      | V |   |   | L | K | L | T | N |
;	      |---|---|---|---|---|---|---|---|
;	ISDEV = 1 if this channel is a device
;	      = 0 if this channel is a disk file
;
;	If ISDEV = 1
;
;	      EOF = 0 if End Of File on input
;	      RAW = 1 if this device is in Raw mode
;		  = 0 if this device is cooked
;	      ISCLK = 1 if this device is the clock device
;	      ISNUL = 1 if this device is the null device
;	      ISCOT = 1 if this device is the console output
;	      ISCIN = 1 if this device is the console input
;
;	If ISDEV = 0
;	      EOF = 0 if channel has been written
;	      Bits 0-5	are  the  block  device  number  for
;		  the channel (0 = A, 1 = B, ...)
;
devid_ISDEV	EQU	80h
devid_EOF	EQU	40h
devid_RAW	EQU	20h
devid_SPECIAL	EQU	10H
devid_ISCLK	EQU	08h
devid_ISNUL	EQU	04h
devid_ISCOT	EQU	02h
devid_ISCIN	EQU	01h

devid_block_dev EQU	1Fh		; mask for block device number
