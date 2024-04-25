
PAGE	85,132				;Set for 5182 Pageprinter
					;85 lines per page, 132 col per line
					;(formerly 60,132)

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ									  บ
;บ  This is the new version of the XMA2EMS driver for DOS 3.3.		  บ
;บ  It contains the following revisions and code flags: 		  บ
;บ									  บ
;บ     @RH0 - Correct scrolling problem 				  บ
;บ     @RH1 - Expand table to 32M					  บ
;บ     @RH2 - Real Mode support (XMA/A card)				  บ
;บ     @RH3 - Memory Expansion Option (MXO a.k.a. XMO) support		  บ
;บ     @RH4 - LIM 4.0 support						  บ
;บ     @RH5 - Multicard support 					  บ
;บ     @RH6 - WSP interfaces						  บ
;บ     @RH7 - 386 XMA Emulator support					  บ
;บ     @RH8 - Make driver reentrant					  บ
;บ									  บ
;บ	AN007	P5134	- Provide variable planar size support. 	  บ
;บ			  Modify linked list to forward link vs. the	  บ
;บ			  reverse linked list.				  บ
;บ									  บ
;บ	AN008	P5150	- Fix incorrect access of slot 0 when no	  บ
;บ			  Catskill/Holster card is in slot 0.		  บ
;บ									  บ
;วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ
;บ     It should be noted that certain EMS calls will alter the contents  บ
;บ  of the translate table pointer for any supported memory cards or	  บ
;บ  emulators (i.e. MXO, XMA, XMA/A cards, 80386 XMA emulator).	 	  บ
;บ  Therefore, software that writes to the translate table(s) has the	  บ
;บ  responsiblity of keeping the integrity of the TT pointer.  For	  บ
;บ  example, programs should disable interrupts between setting the	  บ
;บ  TT pointer and writing the TT data.  This will prevent: An interrupt  บ
;บ  occurring between the two, control going to another application	  บ
;บ  that makes an EMS call and thus screws up the TT ptr.  The EMS calls  บ
;บ  that do this are:							  บ
;บ	 Function #   EMS Call						  บ
;บ	   5	       Map logical to physical page			  บ
;บ	   8, 15/0     Save (Get) mapping array 			  บ
;บ	   9, 15/1     Restore (Set) mapping array			  บ
;บ	   15/2        Get and Set mapping array			  บ
;บ									  บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ

;XMA2EMS provides a Lotus/Intel/Microsoft Expanded Memory (EMS) interface
;for the IBM Expanded Memory Adapter (XMA).

;Program Property of Microsoft

;Add the following statement to CONFIG.SYS
;	DEVICE=[d:][path]XMA2EMS.SYS


;-----------------------------------------------------------------------;
;	Equates go here 						;
;-----------------------------------------------------------------------;
EMS_INT EQU	67H			;EMS INTERRUPT
EM_INT	EQU	15H			;EM INTERRUPT				;an000; dms;
DK_Int	equ	13h			;disk interrupt 			;an004; dms;
EM_Size_Get EQU 88h			;get EM size				;an000; dms;
EMM_VERSION EQU 40H			;VERSION 4.0
PF_HI_LIMIT EQU 0E000H			;highest allowable page frame segment
PF_LOW_LIMIT EQU 0A000H 		;lowest allowable page frame segment
OK	EQU	'OK'                    ;card is good
HW_ERROR EQU	'HW'                    ;card is not functional...HardWare error
SW_ERROR EQU	'SW'                    ;SoftWare error has been detected
PAGE_INHIBITTED    EQU 0FFFFh		;Entry in the save area indicating
					; a page is currently inhibitted
REUSABLE_HANDLE    EQU 'HR'             ;Reusable (free) entry in the      @RH1
					; handle lookup table.	Placed in  @RH1
					; the 'pages' field                @RH1
REUSABLE_SAVEA	   EQU 'SR'             ;Reusable (free) entry in the      @RH1
					; handle save area. 0 is a valid   @RH1
					; page #, and 'FFFF' is for saving @RH1
					; an inhibitted field, so S(ave)   @RH1
					; R(eusable) is stored.  Page 5352 @RH1
					; not a valid page (5352 = 333Meg) @RH1
					;Page Allocation List entries
					; Allocated pages have the handle #
UNALLOCATED	   EQU 'U'              ; Unused entry
ALLOCATED	   EQU 'X'              ; Temporary...used by reallocate   @RH4
PAL_NULL	   EQU '--'             ; End of list marker               @RH8
EXTENDED	   EQU 'ME'             ; Extended memory (not for EMS use)@RH8
BACMEM_ALLOC	   EQU 'MB'             ; Allocated to back conventional   @RH8
					;  memory (back disabled planar)
WSP_ALLOC	   EQU 'SW'             ; Allocated to Workstation Program @RH8
					; Pages kept as extended memory by:
RESR_EXT	   EQU 'ER'             ;  /E parameter
PREV_EXT	   EQU 'EP'             ;  Previously loaded drivers
					; These values are OK as long as the
					; # of handles supported (40h) is
					; not above the ascii 'B' (42h)
WARM_MASK	   EQU	 1			;ISOLATE WARM START BIT
OFFSET_IN_XREF	   EQU BYTE PTR[BX+SI]
LENGTH_IN_XREF	   EQU BYTE PTR[BX+SI+1]
PAGE_LIST_ENTRY    EQU WORD PTR[SI + OFFSET PAGE_ALLOC_LIST]	    ;	   @RH8
page_table_entry    EQU byte PTR[SI + OFFSET PAGE_ALLOC_table] ;temp for assembl
XREF_TABLE_ENTRY   EQU word PTR[DI + OFFSET HANDLE_XREF_TABLE]	    ;	   @RH1
NUM_PHYSICAL_PAGES EQU 4
STACK_SIZE	   EQU	100H
Instance_Size	   EQU 150		;instance size				;an000; dms;
Instance_Count	   EQU 3		;number of instances			;an000; dms;

			     ;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			     ;ณ   Common memory adapter declares	       ณ
			     ;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SLOT_SETUP	EQU   08h		;Mask to put the desired adapter   @RH2
					; slot into setup mode, activating @RH2
					; the 10X registers		   @RH2
CARD_ID_LO	EQU   100H		;PS/2 Adapter card id low and	   @RH2
CARD_ID_HI	EQU   101H		; high bytes - read only	   @RH2
					;Card IDs read from port 100,101   @RH2
XMAA_CARD_ID	EQU   0FEF7h		; XMA/A Card ID 		   @RH2
HLST_CARD_ID	EQU   0FEFEh		; MXO				   @RH3
NO_CARD 	EQU   0FFFFh		; No card present		   @RH5
					;Values for the flag MEMCARD_MODE  @RH5
					; indicating what type of memory   @RH5
					; card is being used.		   @RH5
XMA1_VIRT	EQU  00000001B		; XMA 1...always in virtual
XMAA_VIRT	EQU  00000010B		; XMA/A card (PS/2) in virtual
EMUL_VIRT	EQU  00000100B		; XMA emulator on 80386 	   @RH7
XMAA_REAL	EQU  00001000B		; XMA/A in real mode...no banking  @RH3
HOLS_REAL	EQU  00010000B		; MXO card			   @RH3
					;Combinations
XMA1A_VIRT	EQU  00000011B		; XMA1 or XMA/A in virtual mode
WSP_VIRT	EQU  00000111B		; Any virtual mode...banking used

			     ;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			     ;ณ   XMA, XMA\A, and XMA emulator declares        ณ
			     ;ณ 					       ณ
			     ;ณ   The XMA translate table is a 4K x 12 bit     ณ
			     ;ณ     array.  A 12 bit address points to entries ณ
			     ;ณ     in the TT.	The data in the entry is:      ณ
			     ;ณ 					       ณ
			     ;ณ        Bit    Contents			       ณ
			     ;ณ 	12     Inhibit bit (1 = inhibit xlate) ณ
			     ;ณ 	10-0   On XMA 1, pointer to 4K block   ณ
			     ;ณ 		for up to 4 meg capability     ณ
			     ;ณ 	11-0   On XMA/A, pointer to 4K block   ณ
			     ;ณ 		for up to 8 meg capability     ณ
			     ;ณ 					       ณ
			     ;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
					;All are byte ports unless indicated

X_CTRL_REG	EQU   102H		;Control register - en/disable functions
X_CONF_REG	EQU   105H		;Config (mem size), channel check reg.
RM_TTPTR_LO	EQU   106H		;Translate table pointer low and
RM_TTPTR_HI	EQU   107H		; high bytes
RM_TTDATA_LO	EQU   103H		;TT data - high and low bytes
RM_TTDATA_HI	EQU   104H		; Low byte  (103) auto incs the TT ptr

					;Virtual mode port addresses for:
TTPOINTER	EQU   31A0H		;  Translate Table Pointer	 (word)
TTDATA		EQU   31A2H		;  Translate Table Data 	 (word)
AIDATA		EQU   31A4H		;  TT Data with auto increment	 (word)
IDREG		EQU   31A6H		;  Bank ID register
MODE_REG	EQU   31A7H		;  Mode register
DMACAPT 	EQU   31A8H		;  DMA capture register

CR_ROMSLEEP_DIS EQU   11011111B 	;XMA/A control register mask to
					; disable the ROM on XMA/A card
XMA_TT_INHIBIT	EQU   0000100000000000B ;XMA mask for an inhibitted TT entry
XMA_TT_MASK	EQU   0000111111111111B ;XMA mask for anding off unused bits
EMUL_TTDATA_ON	EQU   1000000000000000B ;XMA translate table data - mask for
					; the emulator.  On XMA cards, data
					; is only 12 bits.  On the emulator,
					; bit 15 turned on indicates data is
					; 15 bits.  This allows the emulator
					; to use more than 8 Meg.  Note that
					; both 0FFFh and FFFFh are inhibit.

			     ;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			     ;ณ   MXO declares				       ณ
			     ;ณ 					       ณ
			     ;ณ   The MXO translate table is a 1K x 8 bit      ณ
			     ;ณ     array.  A 10 bit address points to entries ณ
			     ;ณ     in the TT.	The data in the entry is:      ณ
			     ;ณ 					       ณ
			     ;ณ        Bit    Contents			       ณ
			     ;ณ 	8      Inhibit bit (0 = inhibit xlate) ณ
			     ;ณ 	7-0    Pointer to 16K block for up to  ณ
			     ;ณ 		2 meg capability	       ณ
			     ;ณ 					       ณ
			     ;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
					;All are byte ports
H_CARD_INFO	EQU   102H		;Info  Bits 7-1 mem size  Bit 0 sleep
H_CC_PRES	EQU   105H		;Channel check, presence (Bit 0)
H_TTPTR_LO	EQU   106H		;Translate table pointer low and
H_TTPTR_HI	EQU   107H		; high bytes
H_TTDATA	EQU   103H		;TT data - one byte. No auto inc.

H_TT_INHIBIT  EQU   00000000B		;MXO value for setting inhibitted
					; translate table entry
H_TT_ENBMASK  EQU   10000000B		;Pattern to test if TT entry read is
					; enabled.  'and' with entry,jz inhib

					;EMS ERROR CODES
EMS_CODE80 EQU	80H			; Sotware malfunction
EMS_CODE81 EQU	81H			; Hardware malfunction
EMS_CODE82 EQU	82H			; This return code not used
EMS_CODE83 EQU	83H			; Handle not found
EMS_CODE84 EQU	84H			; Invalid function code
EMS_CODE85 EQU	85H			; All handles used
EMS_CODE86 EQU	86H			; Save or restore mapping error
EMS_CODE87 EQU	87H			; Not enough pages to satisfy request
EMS_CODE88 EQU	88H			; Not enough unallocated pages
EMS_CODE89 EQU	89H			; Can't allocate zero pages
EMS_CODE8A EQU	8AH			; Logical page out of range
EMS_CODE8B EQU	8BH			; Physical page out of range
EMS_CODE8C EQU	8CH			; Hardware save area is full
EMS_CODE8D EQU	8DH			; Save area already saved for handle
EMS_CODE8E EQU	8EH			; Save area not saved for this handle
EMS_CODE8F EQU	8FH			; Subfunction parameter not defined
;-------------------------------------------------------------------
EMS_CODE91 EQU	091H
EMS_CODE92 EQU	092H			; added for DMS 				;an000;
EMS_CODE93 EQU	093H									;an000;
EMS_CODE94 EQU	094H									;an000;
EMS_CODE95 EQU	095H									;an000;
EMS_CODE96 EQU	096H									;an000;
EMS_CODE97 EQU	097H									;an000;
EMS_CODE98 EQU	098H									;an000;
EMS_CODE9E EQU	09EH									;an000;
EMS_CODE9C EQU	09CH									;an000;
;-------------------------------------------------------------------			;an000;
EMS_CODEA0 EQU	0A0h			; No matching handle
EMS_CODEA1 EQU	0A1h			; Duplicate handle name
EMS_CODEA2 EQU	0A2h			; Memory wrap error
EMS_CODEA3 EQU	0A3h			; Data in control structure corrupted
EMS_CODEA4 EQU	0A4h			; Access to this function denied

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Request Header (Common portion)			       ณ
;ณ								       ณ
;ณ	 This structure defines the portion  that is common to	       ณ
;ณ	 all Request Headers.					       ณ
;ณ								       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
RH	EQU	DS:[BX] 		;addressability to Request Header structure

RHC	STRUC				;fields common to all request types
	DB	?			;length of Request Header (including data)
	DB	?			;unit code (subunit)
RHC_CMD DB	?			;command code
RHC_STA DW	?			;status
	DQ	?			;reserved for DOS
RHC	ENDS				;end of common portion

CMD_INPUT EQU	4			;RHC_CMD is INPUT request

;status values for RHC_STA

STAT_GOOD     EQU 0000H 		;invalid command code error
STAT_DONE     EQU 0100H 		;function complete status (OR on bit)
STAT_CMDERR   EQU 8003H 		;invalid command code error
STAT_CRC      EQU 8004H 		;CRC error
STAT_SNF      EQU 8008H 		;sector not found error
STAT_GENFAIL  EQU 800CH 		;general failure
NOT_BUSY      EQU 11111101B		;busy bit (9) NOT BUSY mask (high order byte)
BUSY_MASK     EQU 00000010B		;busy bit (9) BUSY mask (high order byte)

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Request Header for INIT command			       ณ
;ณ								       ณ
;ณ	 This structure defines the Request Header for the	       ณ
;ณ	 INIT command						       ณ
;ณ								       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
RH0	STRUC
	DB	(TYPE RHC) DUP (?)	;common portion

RH0_NUN DB	?			;number of units
					;set to 1 if installation succeeds,
					;set to 0 to cause installation failure
RH0_ENDO DW	?			;offset  of ending address
RH0_ENDS DW	?			;segment of ending address
RH0_BPBO DW	?			;offset  of BPB array address
RH0_BPBS DW	?			;segment of BPB array address
RH0_DRIV DB	?			;drive code (DOS 3 only)
RH0_ERR  DW	0			; error flag used by DOS - gga
RH0	ENDS

RH0_BPBA EQU	DWORD PTR RH0_BPBO	;OFFSET/SEGMENT OF BPB
;note RH0_BPBA at entry to init points to all after DEVICE= on CONFIG.SYS stmt

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Request Header for OUTPUT STATUS command		       ณ
;ณ								       ณ
;ณ	 This structure defines the Request Header for the	       ณ
;ณ	 Output Status command. 				       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
RH10	STRUC
	DB	(TYPE RHC) DUP (?)	;common portion
RH10	ENDS


;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Request Header for Generic IOCTL Request		       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

RH19	STRUC
	    DB	 (TYPE RHC) DUP (?)	; Reserve space for the header	   @RH6

RH19_MAJF   DB	 ?		; Major function			   @RH6
RH19_MINF   DB	 ?		; Minor function			   @RH6
RH19_SI     DW	 ?		; Contents of SI			   @RH6
RH19_DI     DW	 ?		; Contents of DI			   @RH6
RH19_RQPK   DD	 ?		; Pointer to Generic IOCTL request packet  @RH6
RH19	ENDS


;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Map EMS INT 67H vector in low storage			       ณ
;ณ								       ณ
;ณ	 The vector for the interrupt handler for INT 67H	       ณ
;ณ	 is defined here.					       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
INT_VEC SEGMENT AT 00H
	ORG	4*EMS_INT
EMS_VEC LABEL	DWORD
EMS_VECO DW	?			;offset
EMS_VECS DW	?			;segment
INT_VEC ENDS

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Map EM INT 15H vector in low storage			       ณ
;ณ								       ณ
;ณ	 The vector for the extended memory interrupt handler INT 15h  ณ
;ณ	 is defined here.					       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
INT_VEC15 SEGMENT AT 00H							;an000; dms;
	ORG	4*EM_INT							;an000; dms;
EM_VEC LABEL  DWORD								;an000; dms;
EM_VECO DW    ? 		      ;offset					;an000; dms;
EM_VECS DW    ? 		      ;segment					;an000; dms;
INT_VEC15 ENDS									;an000; dms;


;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ	 Map INT 13h vector in low storage			       ณ
;ณ								       ณ
;ณ	 The vector for the disk access interrupt handler INT 13h      ณ
;ณ	 is defined here.					       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
INT_VEC13 SEGMENT AT 00H							;an004; dms;
	ORG	4*DK_INT							;an004; dms;
DK_VEC LABEL  DWORD								;an004; dms;
DK_VECO DW    ? 		      ;offset					;an004; dms;
DK_VECS DW    ? 		      ;segment					;an004; dms;
INT_VEC13 ENDS									;an004; dms;

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	This marks the start of the device driver code segment		บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ

CSEG	SEGMENT PARA PUBLIC 'CODE'
	ASSUME	CS:CSEG

START	EQU	$			;begin resident XMA2EMS data & code

;DEVICE HEADER - must be at offset zero within device driver
	DD	-1			;becomes pointer to next device header
	DW	0C040H			;attribute (character device)
	DW	OFFSET STRATEGY 	;pointer to device "strategy" routine
	DW	OFFSET IRPT		;pointer to device "interrupt handler"
	DB	'EMMXXXX0'              ;device name


;-----------------------------------------------------------------------;
;	The next word is used to inform the 3270 Workstation Program	;
;	which 4K block in XMA marks the start of EMS Expanded Memory.	;
;-----------------------------------------------------------------------;
EMS_START_IN_XMA	DW	0	;initially, memory manager uses all

;-----------------------------------------------------------------------;
;	The following is the Code Label:
;-----------------------------------------------------------------------;
COPYRIGHT DB	'74X9921 (C)COPYRIGHT 1988 Microsoft '
	DB	'LEVEL 1.00 LICENSED MATERIAL - PROGRAM '
	DB	'PROPERTY OF Microsoft '

;-----------------------------------------------------------------------;
;	Request Header (RH) address, saved here by "strategy" routine   ;
;-----------------------------------------------------------------------;
RH_PTRA LABEL	DWORD
RH_PTRO 	DW	?		;offset
RH_PTRS 	DW	?		;segment
		db	7 dup(0)	;align following tables on seg.

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ  HANDLE LOOKUP TABLE 						ณ
;ณ									ณ
;ณ     This table keeps track of EMS handles and pages assigned 	ณ
;ณ  to each handle.  An entry exists for each of the 64 handles 	ณ
;ณ  supported.	If the handle is active, the first field will		ณ
;ณ  contain the number of pages it owns.  Otherwise, the field		ณ
;ณ  will indicate the handle is free.  The second field is a head	ณ
;ณ  pointer to the handle's pages in the linked Page Allocation List.   ณ
;ณ									ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
H_LOOKUP_STRUC	STRUC			;Structure for Handle lookup table @RH1
H_PAGES 	DW	REUSABLE_HANDLE ;If handle is active, # of owned   @RH8
					; pages.  Init to reusable handle   RH8
H_PAL_PTR	DW	PAL_NULL	;Head ptr for owned pages in PAL   @RH8
H_NAME		DB	8 DUP(0)	;Name - new for LIM 4.0 	   @GGA
H_BANK		DB	0		;If virtual, this handle's bank    @RH6
xref_pages	dw	0		;temp to compile
xref_index	dw	0		;temp to compile
H_LOOKUP_STRUC	ENDS

NUM_HANDLES	EQU 64					   ;One structure  @RH1
HANDLE_LOOKUP_TABLE  H_LOOKUP_STRUC  <0,,,,,>		    ; initialize handle 0
		     H_LOOKUP_STRUC  NUM_HANDLES-1 DUP (<>) ; for OS use - gga

;-----------------------------------------------------------------------;
;    HANDLE CROSS REFERENCE (XREF) TABLE				;
;	Each entry in the Handle_Xref_Table points to a corresponding	;
;	page in the page allocation table.  Entries in the XREF table	;
;	are contiguous for a handle, while PAT entries may not be.	;
;-----------------------------------------------------------------------;
XREF_TABLE_LEN	EQU  2048			;			   @RH1

HANDLE_XREF_TABLE  DW  XREF_TABLE_LEN  DUP(0)	; Changed from byte to	   @RH1
						;  word table		   @RH1
XREF_TABLE_END	EQU  ($)	       ;Used for table shift on deallocate @RH1
;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ  PAGE ALLOCATION LIST						ณ
;ณ									ณ
;ณ	 This is the structure pointed to by the handle lookup table.	ณ
;ณ    The Page Allocation list is a linked list governing EMS pages.	ณ
;ณ    Each 16KB EMS page has an entry in the PAGE_ALLOC_LIST.		ณ
;ณ    The entries correspond to the physical blocks on the extended	ณ
;ณ    memory cards (ex. the first 2 Meg card in a system will use the	ณ
;ณ    first 128 entries in the PAL).					ณ
;ณ	 At initialization time, a 'free' pointer will point to the lastณ
;ณ    (top) page in the PAL, and all entries will be linked from top	ณ
;ณ    down.  Whenever pages are allocated they are retreived from the	ณ
;ณ    free chain, and deallocated pages are placed back on the free	ณ
;ณ    chain.								ณ
;ณ									ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
EMS_PAGES_SUPPORTED EQU  1024		;Support up to 16 Megabytes of EMS @RH8

PAGE_ALLOC_LIST DW  EMS_PAGES_SUPPORTED DUP(0)
					;Page Allocation List (PAL)	   @RH8
page_alloc_table db 1024 dup(unallocated)  ;temp for assemble
;-----------------------------------------------------------------------;
;    HANDLE SAVE AREA							;
;	Each handle has 4 entries where the page frame map can		;
;	be stored. Each entry contains a word for the handle and	;
;	a word for the logical page active there.  If no save has	;
;	occurred for a handle, then the logical page field in the	;
;	save area will contain a value indicating it's reusable.        ;
;-----------------------------------------------------------------------;
H_SAVEA_ENTRY  STRUC			;This is an overlay for one page's @RH5
HSA_HNDL	DW    ? 		; entry in the handle save area.   @RH5
HSA_LP		DW    ? 		; It is used to clear the save	   @RH5
H_SAVEA_ENTRY  ENDS			; area after a restore.  While not @RH5
					; directly used by the structure   @RH5
					; below, its size should match	   @RH5
					; that for one page entry	   @RH5

H_SAVE_STRUC	STRUC			;Structure for Handle Save Area    @RH1
PG0_HNDL	DW    0
PG0_LP		DW    REUSABLE_SAVEA
PG1_HNDL	DW    0
PG1_LP		DW    REUSABLE_SAVEA
PG2_HNDL	DW    0
PG2_LP		DW    REUSABLE_SAVEA
PG3_HNDL	DW    0
PG3_LP		DW    REUSABLE_SAVEA
PGFE_HNDL	DW    0 							;AN006;
PGFE_LP 	DW    REUSABLE_SAVEA						;AN006;
PGFF_HNDL	DW    0 							;AN006;
PGFF_LP 	DW    REUSABLE_SAVEA						;AN006;
H_SAVE_STRUC	ENDS

HANDLE_SAVE_AREA  H_SAVE_STRUC	NUM_HANDLES DUP (<>)
				       ;One structure for each handle	   @RH1

H_SAVE_ENTRY	  EQU	WORD PTR[DI + OFFSET HANDLE_SAVE_AREA]	     ;	   @RH1


;-------------------------------------------------------------------
;
;	mappable_phys_page	table
;
;	This table is used by function 5800h
;
;-------------------------------------------------------------------

mappable_phys_page_struct	STRUC	; define the structure
  phys_page_segment	dw	?	; segment
  phys_page_number	dw	?	; page ID
  ppm_handle		dw	?	; handle, -1 means unused
  ppm_log_page		dw	?	; logical page, -1 means unused
mappable_phys_page_struct	ENDS

;	allocate the storage

map_table	mappable_phys_page_struct <-1, -1, -1, -1>  ;p0   no default
		mappable_phys_page_struct <-1, -1, -1, -1>  ;p1   no default
		mappable_phys_page_struct <-1, -1, -1, -1>  ;p2   no default
		mappable_phys_page_struct <-1, -1, -1, -1>  ;p3   no default
		mappable_phys_page_struct <-1, -1, -1, -1>  ;p254 no default
		mappable_phys_page_struct <-1, -1, -1, -1>  ;p255 no default

map_count_def	equ	6		; default 6
map_count	dw	0		;
map_size	dw	type mappable_phys_page_struct * map_count_def ; size of default table
ppm_size	equ	6		;size of partial page map entry

;	flags and a word used in setting up map_table stuff, see parmpars.inc

p0_flag 	equ	0001h		; flags used to indicate which p's were
p1_flag 	equ	0002h		; set on command line
p2_flag 	equ	0004h
p3_flag 	equ	0008h
p254_flag	equ	0010h
p255_flag	equ	0020h
frame_flag	equ	8000h		; special flag used when FRAME= was found

page_flags	dw	0		; word of above flags used in setting map_table
parse_flag	dw	0		; flag used to indicate command line args were encountered

;-------------------------------------------------------------------
;	rom scan stuff
;-------------------------------------------------------------------
family1 	equ	1
micro_channel	equ	2


rom_scan_type	dw	micro_channel	;
segment_error	dw	0		; segment error flag = 0 means all OK

;-----------------------------------------------------------------------
;    Tables added for multicard support 				บ
;									บ
;	These tables manage the mapping of multiple memory cards	บ
;    on a PS/2 Model 50 and 60.  These systems may have a combination	บ
;    of MXO and XMA/A cards.  The model 80 is excluded, since		บ
;    it uses the XMA emulator.						บ
;									บ
;-----------------------------------------------------------------------
			;-----------------------------------------------
			; Memory Card Descriptor Table			บ
			;-----------------------------------------------

MEM_CARD_STRUC	STRUC			;Structure for the memory cards    @RH5
CARD_ID 	DW	NO_CARD 	;Card ID from ports 100 and 101    @RH5
CARD_SLOT	DB	?		;Physical slot of card (0 based)   @RH5
START_PG_NUM	DW	?		;Starting and ending #s of the	   @RH5
END_PG_NUM	DW	?		; pages this card has within the   @RH5
MEM_CARD_STRUC	ENDS			; total EMS page pool (0 based)    @RH5

					;Memory Card Table - entries are   @RH5
					; filled in ascending order (from  @RH5
					; slot 0) for each card found.	   @RH5
					; MXOs scanned 1st, then XMA/A	   @RH5
MAX_SLOTS	EQU 8				     ;Max of 8, but most   @RH5
MEM_CARD_TABLE	MEM_CARD_STRUC	MAX_SLOTS DUP (<>)   ; likely 1 or 2 cards @RH5

			;-----------------------------------------------
			; Multicard Page Frame Descriptor Table 	บ
			;-----------------------------------------------
MULTIC_PM_STRUC STRUC			;Structure for storing the card ID @RH5
PG_CARD 	DW	NO_CARD 	; and slot of the card currently   @RH5
PG_SLOT 	DB	0		; mapped to this page of the page  @RH5
MULTIC_PM_STRUC ENDS			; frame 			   @RH5

					;Multicard Page Mapping Table.
					; Entry for each page of the page
					; frame (including pages FE & FF)
MC_PM_TABLE  MULTIC_PM_STRUC   MAP_COUNT_DEF DUP (<>)

			;-----------------------------------------------
			; Assorted Multicard declares			บ
			;-----------------------------------------------
NUM_MEM_CARDS	DW   0
NUM_OF_SLOTS	DB	?		;Number of adapter slots RR 8 TB 4 @RH2
WTT_CARD_SLOT	DB	?		;Slot # of the memory card being   @RH2
					; used to map a page		   @RH2


Instance_Entry_Struc	struc		;required  data in first 2 entries	;an000; dms;
	IE_Alloc_Byte	db	?	;instance allocated byte		;an000; dms;
	IE_Saved_DI_Reg dw	?	;saved di register			;an000; dms;
Instance_Entry_Struc	ends		;end struc				;an000; dms;

;-----------------------------------------------------------------------;
;	Table of DOS command processing routine entry points		;
;									;
;	An '*' in the comment area indicates the command is handled     ;
;	by meaningful code.  All other commands simply set a good	;
;	return code and exit back to DOS.				;
;-----------------------------------------------------------------------;
CMD_TABLE LABEL WORD
	DW	OFFSET INIT		; 0 - *Initialization
	DW	OFFSET MEDIA_CHECK	; 1 -  Media check
	DW	OFFSET BLD_BPB		; 2 -  Build BPB
	DW	OFFSET INPUT_IOCTL	; 3 -  IOCTL input
	DW	OFFSET INPUT		; 4 -  Input
	DW	OFFSET INPUT_NOWAIT	; 5 -  Non destructive input no wait
	DW	OFFSET INPUT_STATUS	; 6 -  Input status
	DW	OFFSET INPUT_FLUSH	; 7 -  Input flush
	DW	OFFSET OUTPUT		; 8 -  Output
	DW	OFFSET OUTPUT_VERIFY	; 9 -  Output with verify
	DW	OFFSET OUTPUT_STATUS	;10 - *Output status
	DW	OFFSET OUTPUT_FLUSH	;11 -  Output flush
	DW	OFFSET OUTPUT_IOCTL	;12 -  IOCTL output
	DW	OFFSET DEVICE_OPEN	;13 -  Device OPEN
	DW	OFFSET DEVICE_CLOSE	;14 -  Device CLOSE
	DW	OFFSET REMOVABLE_MEDIA	;15 -  Removable media
	DW	OFFSET INVALID_FCN	;16 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET INVALID_FCN	;17 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET INVALID_FCN	;18 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET GENERIC_IOCTL	;19 - *Generic IOCTL function	 gga		   ;AN003;
	DW	OFFSET INVALID_FCN	;20 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET INVALID_FCN	;21 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET INVALID_FCN	;22 -  Invalid IOCTL function	 gga		   ;AN003;
	DW	OFFSET GET_LOG_DEVICE	;23 -  Invalid IOCTL function	 gga		   ;AN003;
MAX_CMD EQU	($-CMD_TABLE)/2 	;highest valid command follows
	DW	OFFSET SET_LOG_DEVICE	;24 -  Invalid IOCTL function	 gga		   ;AN003;

;-----------------------------------------------------------------------;
;	Table of Expanded Memory Manager routine entry points		;
;-----------------------------------------------------------------------;
FCN_TABLE LABEL WORD
	DW	OFFSET EMM_STATUS	;40 - Get status of memory manager
	DW	OFFSET Q_PAGE_FRAME	;41 - Get segment of page frame
	DW	OFFSET Q_PAGES		;42 - Get number of alloc & unalloc pgs
	DW	OFFSET GET_HANDLE	;43 - Request ID and allocate n pages
	DW	OFFSET MAP_L_TO_P	;44 - Map logical to physical page
	DW	OFFSET DE_ALLOCATE	;45 - Deallocate all pages of ID n
	DW	OFFSET Q_VERSION	;46 - Get version number
	DW	OFFSET SAVE_MAP 	;47 - Save mapping array
	DW	OFFSET RESTORE_MAP	;48 - Restore mapping array
	DW	OFFSET GET_PORT_ARRAY	;49 - Get I/O port array
	DW	OFFSET GET_L_TO_P	;4A - Get logical to physical array
	DW	OFFSET Q_OPEN		;4B - Get number of open ID's
	DW	OFFSET Q_ALLOCATE	;4C - Get pages allocated to ID n
	DW	OFFSET Q_OPEN_ALL	;4D - Get all ID's and pages allocated
	DW	OFFSET GET_SET_MAP	;4E - Group of subfunctions that Get
					;and/or Set the page map

;-------------------------------------------------------------------			 ;GGA
;	these functions were added for LIM 4.0 support					 ;GGA
;-------------------------------------------------------------------			 ;GGA
											 ;GGA
	dw	offset partial_map	; 4F - get/set partial page map 		 ;GGA
	dw	offset map_mult 	; 50 - map/unmap multiple handle pages		 ;GGA
	dw	offset reallocate	; 51 - reallocate pages 			 ;GGA
	dw	offset handle_attrib	; 52 - get/set handle attributes		 ;GGA
	dw	offset handle_name	; 53 - get/set handle name			 ;GGA
	dw	offset handle_dir	; 54 - get handle directory			 ;GGA
	dw	offset alter_and_jump	; 55 - alter page map and jump			 ;GGA
	dw	offset alter_and_call	; 56 - alter page map and call			 ;GGA
	dw	offset exchng_region	; 57 - move/exchange memory region		 ;GGA
	dw	offset address_array	; 58 - Get mappable physical address array	 ;GGA
	dw	offset hardware_info	; 59 - Get extended momory hardware information  ;GGA
	dw	offset alloc_raw	; 5A - allocate raw pages			 ;GGA
	dw	offset alternate_map	; 5B - alternate map register set		 ;GGA
	dw	offset prepare_boot	; 5C - Prepare for WarmBoot			 ;GGA
MAX_FCN EQU	($-FCN_TABLE)/2 	;      highest valid command follows		 ;GGA
	dw	offset enable_os	; 5D - enable/disable OS/E functions		 ;GGA

;-----------------------------------------------------------------------;
;	Data variables go here						;
;-----------------------------------------------------------------------;
PAGE_FRAME_STA	DW	0D000H		;STARTING SEG OF PAGE FRAME
TOTAL_SYS_PAGES DW	1024/16 	;Total number of 16k pages on the
					; memory card(s) that are initially
					; expanded memory.  On PS/2 50 + 60,
					; pages used as extended are subtracted.
TOTAL_EMS_PAGES DW	1024/16 	;Pages left after conventional
					; memory is backed
FREE_PAGES	DW	1024/16 	;Total unallocated pages for EMS use
EM_Ksize	dw	?		;size in Kb of extended memory		;an000; dms;
CARD_STATUS	DW	'OK'            ;STATUS OF THE HARDWARE
					;  DEFAULT='OK'   FAILURE='HW'
MANAGER_STATUS	DW	'OK'            ;STATUS OF THE MEMORY MANAGER
					;  DEFAULT='OK'   FAILURE='SW'
STARTING_BLOCK	DW	0		;number of 4K blocks reserved by pinta
OVERFLOW	DB	0
WARM_START	DB	'N'             ;initially not a warm start
MULTIPLIER	DW	?		;Used for figuring table offsets   @RH1
TEN		DW	10		; via multiplication...not the	   @RH1
SIXTEEN 	DW	16		; most efficient, but flexible	   @RH1
MEMCARD_MODE	DB	XMA1_VIRT	;Flag indicating the type of memory@RH2
					; card being used.  Default to	   @RH2
					; XMA 1 card.
BANKID		DB	?		;Current XMA Bank ID		   @RH1
BLOCKS_PER_PAGE DW	4		;XMA blocks per EMS page (multiply)@RH1
SEG_PER_PAGE	DW	1024		;Segments(16 bytes) per EMS page   @RH1

INTV15	LABEL	DWORD								;an000; dms;
INTV15O DW	?			;offset 				;an000; dms;
INTV15S DW	?			;segment				;an000; dms;

INTV13	LABEL	DWORD								;an004; dms;
INTV13O DW	?			;offset 				;an004; dms;
INTV13S DW	?			;segment				;an004; dms;

PAL_FREE_PTR	DW	PAL_NULL
;-------------------------------------------------------------------
;	define some flags and storage for the enable/disable functions
;-------------------------------------------------------------------

ose_enabled	equ	1		; flags used to enable/disable OS/E fcns	;an000;
ose_disabled	equ	0								;an000;

access_code	dd	0		; access code used by OS/E functions		;an000;
ose_functions	dw	ose_enabled	; OS/E functions 1 = enabled, 0 = disabled	;an000;

;-------------------------------------------------------------------
;	define some storage for the ROM scan logic
;-------------------------------------------------------------------
where_to_start	dw	0a000h		; start ROM scan at A000


;-----------------------------------------------------------------------;
;	INT 15H Interrupt Handler routine				;
;-----------------------------------------------------------------------;

;=========================================================================
; XMA_INT15	: This routine traps the INT 15h requests to perform its
;		  own unique services.	This routine provides 1 INT 15h
;		  service; function 8800h.
;
;	Service - Function 8800h: Obtains the size of EM from the word
;				  value EM_KSize
;			Call With: AX - 8800h
;			Returns  : AX - Kbyte size of EM
;
;=========================================================================
XMA_INT15   PROC								;an000; dms;

	cmp	ah,EM_Size_Get							;an000; dms;function 88h?
	jne	XMA_INT15_Jump							;an000; dms;no - jump to old INT 15h
		mov	ax,cs:EM_KSize						;an000; dms;return size
		clc								;an000; dms;clear CY
		jmp	XMA_INT15_Exit						;an000; dms;exit handler

XMA_INT15_Jump: 								;an000; dms;

		jmp	cs:INTV15						;an000; dms;jump to org. vector

XMA_INT15_Exit: 								;an000; dms;


	iret									;an000; dms;

XMA_INT15   ENDP								;an000; dms;

include I13HOOK.INC								;an004; dms;


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Device "strategy" entry point                                   บ
;บ									บ
;บ	Retain the Request Header address for use by Interrupt routine	บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
STRATEGY PROC	FAR
	MOV	CS:RH_PTRO,BX		;offset
	MOV	CS:RH_PTRS,ES		;segment
	RET
STRATEGY ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	DOS Device "interrupt" entry point                              บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
IRPT	PROC	FAR			;device interrupt entry point
	PUSH	DS			;save all registers Revised
	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
					;BP isn't used, so it isn't saved
	CLD				;all moves forward

	LDS	BX,CS:RH_PTRA		;get RH address passed to "strategy" into DS:BX

	MOV	AL,RH.RHC_CMD		;command code from Request Header
	CBW				;zero AH (if AL > 7FH, next compare will
					;catch that error)

	CMP	AL,MAX_CMD		;if command code is not too high
	JNA	IRPT_CMD_OK		; then handle the command
	MOV	RH.RHC_STA,STAT_CMDERR	;"invalid command" and error
	JMP	IRPT_CMD_EXIT

IRPT_CMD_OK:
	MOV	RH.RHC_STA,STAT_GOOD	;initialize return to "no error"

	ADD	AX,AX			;double command code for table offset
	MOV	DI,AX			;put into index register for JMP

;At entry to command processing routine:
;	DS:BX	= Request Header address
;	CS	= VDISK code segment address
;	AX	= 0

	CALL	CS:CMD_TABLE[DI]	;call routine to handle the command


IRPT_CMD_EXIT:				;return from command routine
					;AX = value to OR into status word
	LDS	BX,CS:RH_PTRA		;restore DS:BX as Request Header pointer
	OR	RH.RHC_STA,STAT_DONE	;add "done" bit to status word
	POP	SI			;restore registers
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	POP	DS

	RET				;far return back to DOS
IRPT	ENDP

include genioctl.inc			; include code for genioctl fcn gga

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Set 'OUTPUT STATUS' entry point                                 บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
OUTPUT_STATUS PROC			;Output status
	LDS	BX,CS:RH_PTRA		;DS:BX as pointer to request header
	MOV	AX,RH.RHC_STA		;get status word
OS1:
	AND	AH,NOT_BUSY		;turn off busy bit
OS2:
	MOV	RH.RHC_STA,AX		;write it back to request header
	RET
OUTPUT_STATUS ENDP


IGNORED_CMDS  PROC
IRPT_CMD_ERROR: 			;CALLed for unsupported character mode commands

MEDIA_CHECK:				;Media check
BLD_BPB:				;Build BPB
INPUT_IOCTL:				;IOCTL input
INPUT:					;Input
INPUT_NOWAIT:				;Non destructive input no wait
INPUT_STATUS:				;Input status
INPUT_FLUSH:				;Input flush
OUTPUT: 				;Output
OUTPUT_VERIFY:				;Output with verify
OUTPUT_FLUSH:				;Output flush
OUTPUT_IOCTL:				;IOCTL output
DEVICE_OPEN:				;Device OPEN
DEVICE_CLOSE:				;Device CLOSE
REMOVABLE_MEDIA:			;Removable media
INVALID_FCN:				; invalid IOCTL function			  ;AN003;
GET_LOG_DEVICE: 			; get logical device				  ;AN003;
SET_LOG_DEVICE: 			; set logical device				  ;AN003;
	      RET
IGNORED_CMDS  ENDP



;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for EMM interrupt handler				บ
;บ									บ
;บ									บ
;บ	The interrupt vector 67H points here.				บ
;บ									บ
;บ	On Entry:							บ
;บ		  The AH register contains the function number and the	บ
;บ		  necessary parameters are passed in registers defined	บ
;บ		  by the Expanded Memory Specification. 		บ
;บ									บ
;บ	On Exit:							บ
;บ		  (AH) = 0 if no error					บ
;บ		  (AH) = error # if error				บ
;บ									บ
;บ		  other register contain information as specified by EMSบ
;บ		  otherwise all registers remain unchanged		บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
EMS_INT67 PROC
	push	bp			;save instance pointer			;an000; dms;
	call	Set_Instance		;set BP to proper instance entry	;an000; dms;
	jc	INT67_Instance_Exit	;not enough instances			;an000; dms;

	mov	cs:[bp].IE_Saved_DI_Reg,di ;save reg in instance table		   ;an000; dms;


	SUB	AH,40H			;adjust to range of fcn table
	CMP	AH,0			;too low?
;	$IF	GE,AND
	JNGE $$IF1
	CMP	AH,MAX_FCN		;too high?
;	$IF	LE
	JNLE $$IF1
	    MOV     DI,OFFSET INT67_EXIT ;get common exit addr
	    PUSH    DI			;put it on stack
	    PUSH    AX			;save ax...al may contain parms
	    XCHG    AH,AL		;adjust
	    XOR     AH,AH		;  for ax
	    ADD     AX,AX		;    to be offset into table
	    MOV     DI,AX		;use di for index into table
	    POP     AX			;recover ax ... parms in al
;At entry to function handler:
;	CS	= INT67 code segment
;	TOP OF STACK is return address, INT67_EXIT

	    JMP     CS:FCN_TABLE[DI]	;call routine handler
;	$ENDIF
$$IF1:
	MOV	AH,EMS_CODE84		;function call out of range



INT67_EXIT:

	mov	di,cs:[bp].IE_Saved_DI_Reg ;save reg in instance table		   ;an000; dms;
	call	Reset_Instance		;deallocte instance entry		;an000; dms;

INT67_Instance_Exit:

	pop	bp			;restore instance pointer		;an000; dms;

	IRET				;end of interrupt 67
EMS_INT67 ENDP



;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for EMM STATUS		      Function 1	บ
;บ									บ
;บ	on entry: (AH) = '40'x                                          บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
EMM_STATUS PROC
	CMP	MANAGER_STATUS,SW_ERROR ;is manager ok?
;	$IF	E			;if no then
	JNE $$IF3
	    MOV     AH,EMS_CODE80	;indicate bad status
	    JMP     ST1 		;exit
;	$ENDIF
$$IF3:
	CMP	CARD_STATUS,HW_ERROR	;is card ok?
;	$IF	E			;if no then
	JNE $$IF5
	    MOV     AH,EMS_CODE81	;indicate bad status
	    JMP     ST1 		;exit
;	$ENDIF
$$IF5:
	XOR	AH,AH			;set good return status
ST1:
	RET				;return to caller
EMM_STATUS ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET PAGE FRAME		      Function 2	บ
;บ									บ
;บ	on entry: (AH) = '41'x                                          บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (BX) = segment address of page frame			บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_PAGE_FRAME PROC
	push	cx				;save regs			;an000; dms;
	push	dx				;				;an000; dms;
	push	si				;				;an000; dms;

	cmp	cs:Map_Count,4			;enough frames? 		;an000; dms;
	jb	Q_Page_Frame_Error_Exit 	;no - exit with error		;an000; dms;

	mov	cx,4h				;loop only 4 times		;an000; dms;
	xor	ax,ax				;page number reference		;an000; dms;
	mov	si,offset cs:Map_Table		;point to map table		;an000; dms;
	mov	bx,cs:[si].Phys_Page_Segment	;set start segment value	;an000; dms;
	mov	dx,bx				;segment reference		;an000; dms;

Q_Page_Frame_Loop:

	cmp	cs:[si].Phys_Page_Number,ax	;page matches reference?	;an000; dms;
	jne	Q_Page_Frame_Error_Exit 	;no - exit with error		;an000; dms;

	cmp	cs:[si].Phys_Page_Segment,dx	;page frame match reference	;an000; dms;
	jne	Q_Page_Frame_Error_Exit 	;no - exit with error		;an000; dms;

	add	si,Type Mappable_Phys_Page_Struct;adjust pointer		;an000; dms;
	add	dx,400h 			;next page frame		;an000; dms;
	inc	ax				;next page			;an000; dms;
	loop	Q_Page_Frame_Loop		;continue loop			;an000; dms;

	xor	ah,ah				;set good return		;an000; dms;
	jmp	Q_Page_Exit			;exit the routine		;an000; dms;

Q_Page_Frame_Error_Exit:

	mov	ah,EMS_Code80			;signal software error		;an000; dms;

Q_Page_Exit:

	pop	si				;restore regs			;an000; dms;
	pop	dx				;				;an000; dms;
	pop	cx				;				;an000; dms;

	RET
Q_PAGE_FRAME ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for QUERY TOTAL & UNALLOCATED PAGES Function 3	บ
;บ									บ
;บ	on entry: (AH) = '42'x                                          บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (BX) = number of pages available in expanded memory	บ
;บ		  (DX) = total number of pages in expanded memory	บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_PAGES PROC

	XOR	AH,AH			;Init good return status
	MOV	BX,CS:FREE_PAGES	;bx gets num unalloc pages
	MOV	DX,CS:TOTAL_EMS_PAGES	;dx gets num total pages
	CMP	BX,DX			;If unalloc <= total then OK
	JNA	Q_PAGES_RET		;Otherwise sumptin's rong
	    MOV     AH,EMS_CODE81	; set that return code
Q_PAGES_RET:
	RET
Q_PAGES ENDP



;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET HANDLE AND ALLOCATE       Function 4	บ
;บ									บ
;บ	on entry: (AH) = '43'x                                          บ
;บ		  (BX) = number of pages to allocate			บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (DX) = handle 					บ
;บ		  AX,DX Revised...all other registers preserved	บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
GET_HANDLE PROC
	PUSH	BX
	PUSH	CX
	PUSH	DI
	PUSH	SI
	PUSH	DS			;save these registers

	PUSH	CS			;get cs
	POP	DS			;into ds

					;Remove test for BX = 0. This is   @RH4
					; valid under LIM 4.0

	cmp	bx,0			;0 page allocate is invalid		;an000; dms;
	jne	GH_OKCount		;0 pages not requested			;an000; dms;
		mov	ah,EMS_Code89	;flag 0 pages requested 		;an000; dms;
		jmp	GH_Exit 	;exit routine				;an000; dms;

GH_OKCount:

	CMP	BX,TOTAL_EMS_PAGES	;Enough total EMS pages?
	JNA	GH_OKTOTAL
	MOV	AH,EMS_CODE87
	JMP	GH_EXIT

GH_OKTOTAL:
	cli				;ints off				;an000; dms;
	CMP	BX,FREE_PAGES		;Enough unallocated pages?
	sti				;ints on				;an000; dms;
	JNA	GH_OKFREE
	MOV	AH,EMS_CODE88
	JMP	GH_EXIT
			;-----------------------------------------------------
			; Search for a free handle			 @RH1 บ
			;-----------------------------------------------------
GH_OKFREE:
	MOV	CX,NUM_HANDLES		;loop counter is #handles
	DEC	CX			;handle 0 reserved for op. sys.   @RH1
	MOV	DX,1			;handle assignment set to 1	  @RH1
	MOV	DI,TYPE H_LOOKUP_STRUC	;init table index to 1st entry	  @RH1
;--------------------------------
	CLI				;interrupts OFF during allocation
;--------------------------------
GH_FREEHSRCH:
	CMP	HANDLE_LOOKUP_TABLE.H_PAGES[DI],REUSABLE_HANDLE
					;Is this handle available?	  @RH1
	JE	GH_HFREE		;yes end search  dx=handle id	  @RH1
	INC	DX			;next handle assignment
	ADD	DI,TYPE H_LOOKUP_STRUC	;next entry in handle lookup	  @RH1
					;repeat for all table entries
	LOOP GH_FREEHSRCH
	    MOV     AH,EMS_CODE85	;no available handles
	    JMP     GH_EXIT		;go to exit					 ;GGA

			;-----------------------------------------------------
			; If here then there's enough pages for request. @RH1 บ
			;   DX = handle #, DI = ptr to hndl lookup entry @RH1 บ
GH_HFREE:

	MOV	CX,NUM_HANDLES		;loop counter
	DEC	CX			;handle 0 reserved for op. sys.    @RH1
					;si = index to hndl lookup tbl	   @RH1
	MOV	SI,TYPE H_LOOKUP_STRUC	; for adding pages (skip 0 entry)  @RH1
	XOR	AX,AX			;clear page counter
	CLC				;clear carry for addition
GH_PAGESUM:
	CMP	HANDLE_LOOKUP_TABLE.H_PAGES[SI],REUSABLE_HANDLE
	JE	GH_PGSUM_BOT		;If handle is free don't add       @RH4
	ADD	AX,HANDLE_LOOKUP_TABLE.H_PAGES[SI]
					;add lengths (pages) of PALs	  @RH1
	ADD	SI,TYPE H_LOOKUP_STRUC	; next entry in handle lookup	  @RH1
GH_PGSUM_BOT:
	LOOP	GH_PAGESUM
	CMP	AX,TOTAL_EMS_PAGES	;pages in handle lookup > total?  @RH1
	JNA	GH_CALCHLUP		;no OK				  @RH1
	    MOV     AH,EMS_CODE80	;software error..we screwed up	  @RH1
	    JMP     GH_EXIT		;go to exit			  @RH1		 ;GGA

GH_CALCHLUP:				;calculate entry in hndl lkup tbl @RH1

	cli						;ints off		;an001; dms;
	mov	cx,bx					;alloc count		;an000; dms;
	call	EMS_Page_Contig_Chk			;do we have contig pgs. ;an001; dms;
	jnc	GH_Alloc				;yes continue process	;an001; dms;
		mov	ah,EMS_Code88			;no  signal error	;an001; dms;
		sti					;ints on		;an001; dms;
		jmp	GH_Exit 			;exit routine		;an001; dms;

GH_Alloc:

	call	EMS_Link_Set				;set up links		;an001; dms;


	sub	Free_Pages,bx		;free = free - requested pages
	mov	Handle_LookUp_Table.H_Pages[di],bx	;page count		;an000; dms;
	mov	Handle_LookUp_Table.H_Pal_Ptr[di],si	;initialize to ptr for	;ac001; dms;
							;  pages
	sti						;ints on		;an001; dms;
	xor	ah,ah					;clear flag		;an000; dms;


GH_EXIT:										 ;GGA

	POP	DS
	POP	SI
	POP	DI
	POP	CX
	POP	BX

	RET
GET_HANDLE ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for MAP LOGICAL TO PHYSICAL PAGE  Function 5	บ
;บ									บ
;บ	on entry: (AH) = '44'x                                          บ
;บ		  (AL) = physical page j				บ
;บ		  (BX) = logical page i 				บ
;บ		  (DX) = handle 					บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ

MAP_L_TO_P PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS			;save these registers
	PUSH	CS			;get cs
	POP	DS			;into ds

	CMP	BX,PAGE_INHIBITTED	;If the log pg = inhibit, ignore   @RH4
	JNE	MLP_HANDLE_CHK		; checking handle ID. Restore PF   @RH4
	MOV	SI,BX			; calls this proc, and a saved pg  @RH4
	JMP	SHORT MLP_GET_SEG	; that has never been mapped will  @RH4
					; have no handle ID		   @RH4

MLP_HANDLE_CHK:
	CMP	DX,NUM_HANDLES-1	;handle within range ?
	JBE	MLP_DXINRANGE
	    MOV     AH,EMS_CODE83	;handle not found
	    JMP     MLP_EXIT		;exit
MLP_DXINRANGE:
	push	ax			;save affected regs			;an000; dms;
	push	dx			;					;an000; dms;
	MOV	AX,DX			;   (DX:AX used in MUL		   @RH1
	MOV	DX,TYPE H_LOOKUP_STRUC	;SI = entry's offset into          @RH8
	MUL	DX			; the handle lookup table	   @RH8
	MOV	SI,AX			;				   @RH1
	pop	dx			;restore affected regs			;an000; dms;
	pop	ax			;					;an000; dms;

	MOV	CX,HANDLE_LOOKUP_TABLE.H_PAGES[SI]    ;CX = handle's pages @RH8
	CMP	CX,REUSABLE_HANDLE		      ;Handle have pages?
	JNE	MLP_DXHASPAGES			      ;Yes next check
	    MOV     AH,EMS_CODE83		      ;No handle not used
	    JMP     MLP_EXIT			      ; set error and exit
MLP_DXHASPAGES:
	CMP	BX,TOTAL_EMS_PAGES     ;Logical pg requested (0 based)	   @RH1
	JB	MLP_BX_LE_TOT	       ; less than or = to total pages?    @RH1
	    MOV     AH,EMS_CODE8A      ;No... logical page out of range
	    JMP     MLP_EXIT	       ;exit
MLP_BX_LE_TOT:
	CMP	BX,CX		       ;Logical page requested <= number   @RH1
	JB	MLP_LP_OK	       ; of pages for this handle?
	    MOV     AH,EMS_CODE8A      ;No...error log. page out of range  @RH1
	    JMP     MLP_EXIT	       ;exit
					;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					;ณ Convert handle's logical page to    ณ
					;ณ  relative page in the EMS pool (SI) ณ
					;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
MLP_LP_OK:					      ;Get this handle's   @RH8
	MOV	DI,HANDLE_LOOKUP_TABLE.H_PAL_PTR[SI]  ; head index to PAL  @RH8
	CMP	BX,0				      ;If 1st pg wanted    @RH8
	JE	MLP_GOT_PHYS_PG 		      ; then we've got it  @RH8
	MOV	CX,BX				      ;Else scan linked PAL@RH8
						      ; for log pg - 1.    @RH8
MLP_SCAN_PAL:					      ; (log p is 0 based) @RH8
	SHL	DI,1				      ;2 bytes per PAL ent
						      ; mult is slow here
	MOV	DI,PAGE_ALLOC_LIST[DI]		      ; This loop will get @RH8
	LOOP	MLP_SCAN_PAL			      ; the index of the   @RH8
MLP_GOT_PHYS_PG:				      ; desired page	   @RH8
	MOV	SI,DI				      ;SI = page on card   @RH8




					;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					;ณ Get seg addr of the phys page (DI)  ณ
MLP_GET_SEG:				;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	XOR	DI,DI			;Clear offset into mappable phys.  @RH4
	MOV	CX,MAP_COUNT		; page table.  Loop for # entries. @RH4
MLP_PP_CHECK:
	CMP	AL,BYTE PTR MAP_TABLE.PHYS_PAGE_NUMBER[DI]	    ;AX = table pp? @RH4
	JE	MLP_PP_OK				   ;Yes..get seg   @RH4
	ADD	DI,TYPE MAPPABLE_PHYS_PAGE_STRUCT	   ;No..check next @RH4
	LOOP	MLP_PP_CHECK				   ; table entry   @RH4
	    MOV     AH,EMS_CODE8B	;If here physical page not found   @RH1
	    JMP     MLP_EXIT		; in mappable phys pg table..Error @RH1
MLP_PP_OK:
	MOV	MAP_TABLE.PPM_LOG_PAGE[DI],BX	   ;Place the logical pg   @RH4
	MOV	MAP_TABLE.PPM_HANDLE[DI],DX	   ; the mappable pp table @RH4
	MOV	DI,MAP_TABLE.PHYS_PAGE_SEGMENT[DI] ;DI= page's PC seg addr @RH1

					;-------------------------------------
					; Map L to P depending on memory card บ
					;-------------------------------------
MLP_VIRTUAL:
	TEST	MEMCARD_MODE,WSP_VIRT	;Using either an XMA 1, XMA/A, or  @RH2
	JZ	MLP_MC_TEST		; XMA Emulator in virtual mode?    @RH2
	CALL	W_EMSPG_XVIRT		;Yes..Map one logical page to
	JMP	MLP_GOODRC		; physical page using 310X regs
					;Else not virtual...use real mode
MLP_MC_TEST:				;If system has multiple cards,	   @RH5
	CMP	NUM_MEM_CARDS,1 	; then adjust absolute EMS page to @RH5
	JNA	MLP_REAL		; its corresponding page on the    @RH5
	CALL	MLP_MCARD_SETUP 	; card to be used		   @RH5
MLP_REAL:
	CMP	MEMCARD_MODE,XMAA_REAL	;XMA/A card (on PS/2 mod 50 or 60) @RH3
	JNE	MLP_HLST		; in real mode (WSP not loaded)?   @RH3
	CALL	W_EMSPG_XREAL		;Map one logical page to physical  @RH2
	JMP	MLP_GOODRC
MLP_HLST:				;If not XMA then MXO
	CALL	W_EMSPG_HLST		;Map one logical page to physical  @RH3
MLP_GOODRC:
	XOR	AH,AH			;Good return status..mapping
					; should always be successful
MLP_EXIT:

	POP	DS		       ;restore these registers
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX

	RET
MAP_L_TO_P ENDP





;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ    Subroutine: WRITE TRANSLATE TABLE FOR EMS PAGE			       ณ
;ณ		  XMA VIRTUAL MODE					       ณ
;ณ									       ณ
;ณ	     This routine will write the Translate Table so that the	       ณ
;ณ	  specified 16K page of 'real' address will be mapped to a             ณ
;ณ	  specified 16K page of XMA physical memory.			       ณ
;ณ	     This routine is called if the XMA card is in 'virtual'            ณ
;ณ	  mode - i.e. bank swapping is active.	The 16 bit 31AX ports	       ณ
;ณ	  are used for setting up the XMA translate table.		       ณ
;ณ	     The XMA 1 card and XMA emulator are always in virtual	       ณ
;ณ	  mode.  The XMA\A card is in virtual mode if bank switching	       ณ
;ณ	  is active (used by the 3270 Workstation Program).		       ณ
;ณ									       ณ
;ณ	  On entry: (DI) is starting segment in PC address space.	       ณ
;ณ			 Must be on 4K boundary else is rounded 	       ณ
;ณ			 down to the nearest 4K.			       ณ
;ณ		    (SI) absolute EMS page number (not handle relative)     RH4ณ
;ณ			 or FFFFh if page is to be inhibitted		    RH4ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

W_EMSPG_XVIRT  PROC
	MOV	DX,IDREG		;Save the current bank ID	   @RH1
	IN	AL,DX			; (bank of the requestor).  Write  @RH1
	MOV	BANKID,AL		; to the trans. table for this bank@RH1

	MOV	AX,DI			;Get the PC seg. addr of the page  @RH1
	XCHG	AL,AH			;Div by 256 (Segments per 4K block)@RH1
	MOV	AH,BANKID		;Join with the bank ID to get the  @RH1
	MOV	DX,TTPOINTER		; ptr to the translate table entry @RH1
	OUT	DX,AX			;Set TT ptr			   @RH1

	MOV	AX,SI			;Get absolute EMS page number	   @RH4
	CMP	AX,PAGE_INHIBITTED	;Is TT entry to be inhibitted?	   @RH4
	JE	VM_TTDATA_OK		;Yes..write the FFFF in AX	   @RH4
	MUL	BLOCKS_PER_PAGE 	;Else convert page to XMA 4K block @RH1
	TEST	MEMCARD_MODE,EMUL_VIRT	;If running on the emulator then   @RH7
	JZ	VM_TTDATA_OK		; turn high order bit of data on   @RH7
	OR	AX,EMUL_TTDATA_ON	; allowing >8M support on emulator @RH7
VM_TTDATA_OK:
	MOV	CX,BLOCKS_PER_PAGE	;Set up one page - loop on blocks  @RH1
	MOV	DX,AIDATA		; per page using the auto inc reg  @RH1
VM_WRITE:
	OUT	DX,AX			;Write TT entry, inc TT ptr	   @RH1
	CMP	AX,PAGE_INHIBITTED	;Inhibit TT entry?
	JE	VM_NEXT_TT		;Yes..don't inc AX
	INC	AX			;Inc block ptr..contiguous blocks  @RH1
VM_NEXT_TT:
	LOOP	VM_WRITE		;Loop for all blocks in a page	   @RH1

	RET
W_EMSPG_XVIRT  ENDP


;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ    Subroutine: WRITE TRANSLATE TABLE FOR EMS PAGE			       ณ
;ณ		  XMA REAL MODE 					       ณ
;ณ									       ณ
;ณ	     This routine performs basically the same functions as	       ณ
;ณ	  the above routine.  It is called if the XMA/A card is in	       ณ
;ณ	  'real' mode (i.e. bank switching not active, planar memory           ณ
;ณ	  is not disabled).  The 8 bit 10X ports are used for setting	       ณ
;ณ	  up the XMA translate table.					       ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
W_EMSPG_XREAL  PROC

	MOV	AL,WTT_CARD_SLOT	;Put the XMA/A card into setup	   @RH2
	OR	AL,SLOT_SETUP		; mode				   @RH2
	OUT	96h,AL			;				   @RH2

	XOR	AL,AL			;Set the translate table ptr by    @RH2
	MOV	DX,RM_TTPTR_HI
	OUT	DX,AL			; dividing the PC seg. addr in DI  @RH2
	MOV	AX,DI
	XCHG	AL,AH			; by 256 (Segments per 4K block).  @RH2
	MOV	DX,RM_TTPTR_LO
	OUT	DX,AL			;High byte always 0..no banking    @RH2

	MOV	AX,SI			;Get absolute EMS page number	   @RH4
	CMP	AX,PAGE_INHIBITTED	;Is TT entry to be inhibitted?	   @RH4
	JE	RM_TTDATA_OK		;Yes..write the FFFF in AX	   @RH4
	MUL	BLOCKS_PER_PAGE 	;Else convert page to XMA 4K block @RH1
RM_TTDATA_OK:
	MOV	CX,BLOCKS_PER_PAGE	;Set up one page - loop on blocks  @RH2
					; per page using the auto inc regs @RH2
RM_WRITE:
	XCHG	AH,AL			;Write TT data high byte first,    @RH2
	MOV	DX,RM_TTDATA_HI 	; then write low byte.	This is    @RH2
	OUT	DX,AL			; not an auto increment port.	   @RH2
	XCHG	AH,AL			;				   @RH2
	MOV	DX,RM_TTDATA_LO 	;				   @RH2
	OUT	DX,AL			;				   @RH1
	CMP	AX,PAGE_INHIBITTED	;Inhibit TT entry?
	JE	RM_NEXT_TT		;Yes..don't inc AX
	INC	AX			;Inc block ptr..contiguous blocks  @RH1
RM_NEXT_TT:
	LOOP	RM_WRITE		;Loop for all blocks in a page	   @RH1

	MOV	AL,0			;Reset the slot ID		   @RH5
	OUT	96h,AL			;				   @RH5
	RET
W_EMSPG_XREAL  ENDP

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ    Subroutine: WRITE TRANSLATE TABLE FOR EMS PAGE			       ณ
;ณ		  Memory Expansion Option (MXO)				       ณ
;ณ									       ณ
;ณ	     This routine is used to map a logical page to a physical	       ณ
;ณ	  page off the MXO card.  MXO has 16K blocks, as opposed	       ณ
;ณ	  to 4K on the XMA.  The 8 bit 10X ports are used for setting	       ณ
;ณ	  up MXO's translate table.  Note that the data in the	               ณ
;ณ	  translate table is only 8 bits, and the high order bit is a	       ณ
;ณ	  0 to inhibit translation (where inhibit = 1 on XMA).		       ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
W_EMSPG_HLST  PROC
	PUSH	CX			;				   @RH3

	MOV	AL,WTT_CARD_SLOT	;Put the MXO card into setup	   @RH3
	OR	AL,SLOT_SETUP		; mode				   @RH3
	OUT	96h,AL			;				   @RH3

	MOV	AX,DI			;Set the MXO translate table	   @RH3
	MOV	CL,10			; ptr by dividing the PC segment   @RH3
	SHR	AX,CL			; addr in DI by 1024		   @RH3
	MOV	DX,H_TTPTR_LO		; (segments per 16K MXO block).	   @RH3
	OUT	DX,AL			;				   @RH3
	XCHG	AL,AH			;				   @RH3
	MOV	DX,H_TTPTR_HI		;				   @RH3
	OUT	DX,AL			;				   @RH3

	MOV	AX,SI			;Get absolute EMS page number	   @RH4
	CMP	AX,PAGE_INHIBITTED	;Is TT entry to be inhibitted?	   @RH4
	JE	HM_TTDATA_INH		;Yes write MXO inhibit pattern	   @RH4
					;Else turn on enable and write pg  @RH3
	OR	AL,H_TT_ENBMASK 	; (no need to convert.. 16K EMS    @RH3
	JMP	SHORT HM_WRITETT	;  page = 16K MXO block)	   @RH3
HM_TTDATA_INH:				;
	MOV	AL,H_TT_INHIBIT 	;AL = MXO TT inhibit data	   @RH3
HM_WRITETT:
	MOV	DX,H_TTDATA		; Write to the 1 MXO TT entry.	   @RH3
	OUT	DX,AL			;				   @RH3
	MOV	AL,0			;Reset the slot ID		   @RH5
	OUT	96h,AL			;				   @RH5

	POP	CX			;				   @RH3
	RET
W_EMSPG_HLST  ENDP

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ    Subroutine: MULTIPLE MEMORY CARD SETUP				       ณ
;ณ									       ณ
;ณ	  This subroutine selects the correct card in a multicard	       ณ
;ณ     system for mapping a physical page.  Given the absolute page	       ณ
;ณ     number within the EMS pool (SI), it finds the card to use for	       ณ
;ณ     this page, and converts SI to the offset of the page within	       ณ
;ณ     this card.  Before this new page is mapped, it may be necessary	       ณ
;ณ     to disable the translate table entry of the card that's                 ณ
;ณ     currently mapped.						       ณ
;ณ									       ณ
;ณ	  On entry: (DI) is starting segment in PC address space.	       ณ
;ณ		    (SI) absolute EMS page number (not handle relative)        ณ
;ณ			 or FFFFh if page is to be inhibitted		       ณ
;ณ									       ณ
;ณ	  On exit:  (DI) is unchanged.					       ณ
;ณ		    (SI) offset of the page within the selected card	       ณ
;ณ			 or FFFFh if page is to be inhibitted		       ณ
;ณ		    WTT_CARD_SLOT = Slot # of the new card to map	       ณ
;ณ		    MEMCARD_MODE  = Flag indicating if XMA/A or MXO	       ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

PG_NEW_CARD_ID	   DW	?		;Holders for the ID and the slot # @RH5
PG_NEW_CARD_SLOT   DB	?		; of the card that will be used    @RH5
					; in the new mapping		   @RH5
MC_TABLE_OFFSET    DW	?		;Holder for offset into the	   @RH5
					; multicard page mapping table	   @RH5

MLP_MCARD_SETUP PROC
	PUSH	AX
	PUSH	CX
					;-------------------------------------
					; Get the ID and slot of the card to  บ
					;  make active.  Convert SI to be     บ
					;  the correct page within this card. บ
					;-------------------------------------
	PUSH	DI				   ;Loop through the mem   @RH5
	XOR	DI,DI				   ; card table to find    @RH5
	MOV	CX,NUM_MEM_CARDS		   ; card used to map the  @RH5
MC_GET_CARD:					   ; absolute page (SI)    @RH5
	CMP	MEM_CARD_TABLE.END_PG_NUM[DI],SI   ;If the last pg this    @RH5
	JAE	MC_FOUND_CARD			   ; card maps <= SI then  @RH5
	ADD	DI,TYPE MEM_CARD_STRUC		   ; use this card	   @RH5
	LOOP	MC_GET_CARD			   ;Else check next card   @RH5
						   ; Note: if SI = FFFF    @RH5
						   ;  the last card is	   @RH5
						   ;  selected.  This is   @RH5
						   ;  OK, since it doesn't @RH5
						   ;  matter which is inh  @RH5
MC_FOUND_CARD:					   ;			   @RH5
	MOV	AX,MEM_CARD_TABLE.CARD_ID[DI]	   ;Save the card ID and   @RH5
	MOV	PG_NEW_CARD_ID,AX		   ; the slot # of the	   @RH5
	MOV	AL,MEM_CARD_TABLE.CARD_SLOT[DI]    ; card used to map	   @RH5
	MOV	PG_NEW_CARD_SLOT,AL		   ; the new page.	   @RH5
	MOV	AX,MEM_CARD_TABLE.START_PG_NUM[DI] ;If SI is not inhibit,  @RH5
	CMP	SI,PAGE_INHIBITTED		   ; convert SI from the   @RH5
	JE	MC_DEACTIVATE			   ; absolute pg number    @RH5
	SUB	SI,AX				   ; to the offset of the  @RH5
						   ; page within this card @RH5

					;-------------------------------------
MC_DEACTIVATE:				; Deactivate (inhibit) the translate  บ
	POP	DI			;  table entry of the current card.   บ
					;-------------------------------------
					; Search for the seg addr in the   @RH5
					;  map phys pg table to get the    @RH5
					;  corresponding entry in the	   @RH5
	PUSH	SI			;  multicard page mapping table    @RH5
	XOR	SI,SI			;SI = offset into map phy pg table @RH5
	XOR	AX,AX			;AX = offset into multic pm table  @RH5
	MOV	CX,MAP_COUNT		;Loop on # phys pgs (incl FE & FF) @RH5
MC_SRCH_MPP:					      ; 		   @RH5
	CMP	MAP_TABLE.PHYS_PAGE_SEGMENT[SI],DI    ;If no segment match @RH5
	JE	MC_CHECK_CUR_PG 		      ; then next entry in @RH5
	ADD	SI,TYPE MAPPABLE_PHYS_PAGE_STRUCT     ; map phys pg tbl &  @RH5
	ADD	AX,TYPE MULTIC_PM_STRUC 	      ; multicard pm table @RH5
	LOOP	MC_SRCH_MPP			      ; 		   @RH5

					;Examine the current card ID and   @RH5
					; slot used for this page	   @RH5
MC_CHECK_CUR_PG:
	MOV	MC_TABLE_OFFSET,AX		       ;Save mc tbl offset @RH5
	MOV	SI,AX				       ; and put it in SI  @RH5
	CMP	MC_PM_TABLE.PG_CARD[SI],NO_CARD        ;If the page is	   @RH5
	JE	MC_MAP_NEW			       ; inhibitted or if  @RH5
	MOV	AL,MC_PM_TABLE.PG_SLOT[SI]	       ; the new page is   @RH5
	CMP	AL,PG_NEW_CARD_SLOT		       ; on the same card  @RH5
	JE	MC_MAP_NEW			       ; as the old page   @RH5
						       ; then dont inhibit @RH5

					;Inhibit TT entry for current card @RH5
	MOV	WTT_CARD_SLOT,AL		       ;Save slot # and ID @RH5
	MOV	AX,MC_PM_TABLE.PG_CARD[SI]	       ; of current card   @RH5
	MOV	SI,PAGE_INHIBITTED		       ;Page = inhibitted  @RH5
	CMP	AX,XMAA_CARD_ID 		       ;If card = XMA/A    @RH5
	JNE	MC_INH_HLST			       ; then inh XMA/A TT @RH5
	CALL	W_EMSPG_XREAL			       ; entry for pg via  @RH5
	JMP	SHORT MC_MAP_NEW		       ; real mode regs    @RH5
MC_INH_HLST:					       ;Else inhibit TT    @RH5
	CALL	W_EMSPG_HLST			       ; entry for MXO     @RH5

					;-------------------------------------
					; Activate (enable) the translate     บ
					;  table entry of the new card.       บ
MC_MAP_NEW:				;-------------------------------------
					    ;Set the multicard page frame  @RH5
					    ; table for the new card	   @RH5
	POP	SI			    ;Restore EMS page		   @RH5
	PUSH	DI			    ; and save pc seg addr.	   @RH5
	MOV	DI,MC_TABLE_OFFSET	    ;				   @RH5
	MOV	AL,PG_NEW_CARD_SLOT	    ;Store slot # of new card in   @RH5
	MOV	MC_PM_TABLE.PG_SLOT[DI],AL  ; multc pm tbl and in variable @RH5
	MOV	WTT_CARD_SLOT,AL	    ; used by map log to phys proc @RH5
	CMP	SI,PAGE_INHIBITTED	    ;If new pg is not inhibitted   @RH5
	JE	MC_NEWID_INH		    ; then set card ID field in    @RH5
	MOV	AX,PG_NEW_CARD_ID	    ; the multicard page mapping   @RH5
	MOV	MC_PM_TABLE.PG_CARD[DI],AX  ; table to new card ID	   @RH5
	JMP	SHORT MC_SET_FLGS	    ;				   @RH5
MC_NEWID_INH:				    ;				   @RH5
	MOV	AX,NO_CARD		    ;Else set card ID as no card   @RH5
	MOV	MC_PM_TABLE.PG_CARD[DI],AX  ;				   @RH5
					    ;............................
					    ;Set flags so main MLP proc    @RH5
					    ; can map the new page	   @RH5
MC_SET_FLGS:				    ;............................. @RH5
	POP	DI			    ;Restore PC seg addr
	CMP	PG_NEW_CARD_ID,XMAA_CARD_ID ;Set the flag that tells	   @RH5
	JNE	MC_MAP_HLST		    ; the main Map Log to P proc   @RH5
	MOV	MEMCARD_MODE,XMAA_REAL	   ; which subroutine to call	  @RH5
	JMP	SHORT MC_END_PROC	    ;At this point,		   @RH5
MC_MAP_HLST:				    ; DI = PC segment addr of page @RH5
	MOV	MEMCARD_MODE,HOLS_REAL	    ; SI = page's offset into card @RH5
MC_END_PROC:				    ; WTT_CARD_SLOT = card slot #  @RH5
	POP	CX			    ; MEMCARD_MODE = flag showing  @RH5
	POP	AX			    ;	if card is XMAA or MXO     @RH5
	RET				    ;				   @RH5
MLP_MCARD_SETUP  ENDP

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for DEALLOCATE PAGES	      Function 6	บ
;บ									บ
;บ	on entry: (AH) = '45'x                                          บ
;บ		  (DX) = handle 					บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  AX Revised...all other registers preserved		บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
DE_ALLOCATE PROC
	PUSH	BX			;save these registers
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS
	PUSH	ES			;				   @RH1

	PUSH	CS			;get this code segment
	POP	DS			;into ds
	PUSH	CS			;Set up ES for shifting (MOVSB)    @RH1
	POP	ES			; the PAL table 		   @RH1

	cmp	dx,0			;handle zero?				;an000; dms;
	jne	D_Check_Handle		;no continue				;an000; dms;
		mov	bx,0		;reallocate to a page count of 0	;an000; dms;
		call	Reallocate	;					;an000; dms;
		jmp	DA_Exit 	;exit routine				;an000; dms;

D_Check_Handle:

	CMP	DX,NUM_HANDLES-1	;handle within range ?
	JBE	D_OKRANGE		;if not then...
	    MOV     AH,EMS_CODE83	;handle not found
	    JMP     DA_EXIT		;exit
D_OKRANGE:				;check if active (valid) handle
	PUSH	DX			;Save handle id 		   @RH1
	MOV	AX,DX			;set up indexing into h lookup	   @RH1
	MOV	DX,TYPE H_LOOKUP_STRUC	;				   @RH8
	MUL	DX			;get handle lookup entry offset    @RH8
	POP	DX			;Restore handle id		   @RH1
	MOV	DI,AX			;Put offset into index reg	   @RH1

	CMP	HANDLE_LOOKUP_TABLE.H_Pages[DI],REUSABLE_HANDLE
					;Handle has pages?		   @RH1
	JNE	D_OKHNDL		;Yes  OK handle
	    MOV     AH,EMS_CODE83	;No handle not in use.	error.
	    JMP     DA_EXIT		;exit
			;-----------------------------------------------------
D_OKHNDL:		; Before deallocation can continue, insure the	 @RH1 บ
			;  page frame map is not saved under this handle @RH1 บ
			;-----------------------------------------------------
	PUSH	DX				 ;Save handle id	   @RH1
	MOV	AX,DX				 ;Get the correct offset   @RH1
	MOV	DX,TYPE H_SAVE_STRUC		 ; into the handle save    @RH8
	MUL	DX				 ; area for this handle    @RH8
	POP	DX				 ;Restore handle id	   @RH1
	MOV	SI,AX				 ;			   @RH1
D_HSAVECHK:
	CMP	HANDLE_SAVE_AREA.PG0_LP[SI],REUSABLE_SAVEA
	JE	D_PAT_UPDATE		;If the 1st entry for this handle  @RH1
	   MOV	   AH,EMS_CODE86	; in the save area is not free
	   JMP	   DA_EXIT		; then in use...exit with error
			;-----------------------------------------------------
			; Update Page Allocation List -  unallocate
D_PAT_UPDATE:

	PUSH	DX				      ;Save handle id	   @RH1



	MOV	CX,HANDLE_LOOKUP_TABLE.H_PAGES[DI]    ;Get the # of pages  @RH1
	MOV	AX,HANDLE_LOOKUP_TABLE.H_PAL_PTR[DI]  ;Load si with ptr    @RH1
	MOV	SI,AX				      ;pass ptr 		;an000; dms;

	push	cx				      ;save loop count		;an000; dms;

	cmp	cx,0					;handle has 0 pages?	;an001; dms;
	je	D_Depat_Exit1				;yes - don't changes ptr;an001; dms;

	mov	ax,cs:PAL_Free_Ptr			;no  - dealloc pages	;an001; dms;
	mov	cs:PAL_Free_Ptr,si			;set free ptr to root of;an001; dms;
							;  handle list
	dec	cx					;don't loop past last pg;an001; dms;

D_DEPAT:

							;this loop scans to
							;the end of the allocated
							;chain

	cmp	cx,0					;end of deallocate?	;an000; dms;
	je	D_Depat_Exit				;yes - exit		;an000; dms;
	shl	si,1					;no - adjust to index	;an001; dms;
	mov	si,Page_Alloc_List[si]			;get new ptr val	;an001; dms;
	dec	cx					;dec loop ctr		;an001; dms;
	jmp	D_DEPAT 				;continue		;an000; dms;

D_DEPAT_EXIT:

	shl	si,1					;adjust to index value	;an001; dms;
	mov	Page_Alloc_List[si],ax			;pt. last page to orig. ;an001; dms;
							;  free ptr.

D_Depat_Exit1:

	pop	cx					;restore loop count	;an000; dms;
	pop	dx					;restore handle 	;an000; dms;

	push	ds					;save regs		;an000; dms;
	push	si					;			;an000; dms;

	mov	ax,cs					;swap segs		;an000; dms;
	mov	ds,ax					;			;an000; dms;
	mov	si,offset cs:Null_Handle_Name		;point to null handle	;an000; dms;
	mov	ax,5301h				;set handle name func	;an000; dms;
	call	Handle_Name				;set the handle name to ;an000; dms;
							;  nulls
	pop	si					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;

	cli						;ints off		;an000; dms;
	add	cs:Free_Pages,cx			;free up page		;an000; dms;
	mov	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;deallocate	;an000; dms;
								;  handle
	sti						;ints on		;an000; dms;

	xor	ah,ah					;clear flag		;an000; dms;

DA_EXIT:

	POP	ES			;				   @RH1
	POP	DS
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX

	RET
DE_ALLOCATE ENDP


;====================================================================
; Deallocate_Chain	- This routine deallocates a page from a
;			  handle and links it to the free list
;
;	Inputs	: SI - PTR to entry to deallocate
;
;	Outputs : SI - PTR to next entry to deallocate
;
;====================================================================

Deallocate_Chain	proc				;deallocate page	;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	cx					;			;an000; dms;

	cli						;ints off		;an000; dms;

	mov	bx,si					;alloc_ptr		;an000; dms;

	mov	ax,si					;get page_ptr		;an000; dms;
	mov	dx,Type Page_Alloc_List 		;get entry size 	;an000; dms;
	mul	dx					;get pointer val	;an000; dms;
	mov	si,ax					;page_ptr		;an000; dms;

	mov	ax,Page_List_Entry			;page_ptr value 	;an000; dms;
	mov	cx,cs:PAL_Free_PTR			;free_ptr		;an000; dms;


	mov	cs:PAL_Free_PTR,bx			;new free_ptr		;an000; dms;
	mov	Page_List_Entry,cx			;new free_ptr value	;an000; dms;
	mov	si,ax					;next page to deallocate;an000; dms;
	sti						;ints on		;an000; dms;

	pop	cx					;restore regs		;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;			;an000; dms;

Deallocate_Chain	endp				;			;an000; dms;

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for QUERY MEMORY MANAGER VERSION  Function 7	บ
;บ									บ
;บ	on entry: (AH) = '46'x                                          บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_VERSION PROC
	MOV	AL,EMM_VERSION		;al get version number
	XOR	AH,AH			;good return code
	RET
Q_VERSION ENDP



;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for SAVE MAPPING CONTEXT	      Function 8	บ
;บ									บ
;บ	on entry: (AH) = '47'x                                          บ
;บ		  (DX) = handle assigned to the interrupt service	บ
;บ			 routine (i.e. save map under this handle).	บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
SAVE_MAP PROC
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS
	PUSH	ES			;save these registers

	PUSH	CS			;get cs
	POP	DS			;into ds
	PUSH	CS			;Get CS into ES (save area is in
	POP	ES			; this segment)

	CMP	DX,NUM_HANDLES-1	;handle within range ?
	JBE	SM_DXINRANGE		;if not then...
	    MOV     AH,EMS_CODE83	;handle not found
	    JMP     SM_EXIT		;exit
SM_DXINRANGE:
	PUSH	DX			;Handle destroyed by MUL	   @RH1
	MOV	AX,DX			;SI = requested handle's           @RH1
	MOV	DX,TYPE H_LOOKUP_STRUC	; offset into the handle	   @RH8
	MUL	DX			; lookup table			   @RH8
	MOV	SI,AX			;				   @RH1
	POP	DX			;Restore handle ID		   @RH1

	CMP	HANDLE_LOOKUP_TABLE.H_Pages[SI],REUSABLE_HANDLE
	JNE	SM_HACTIVE		;If handle is in use (active), ok  @RH1
	    MOV     AH,EMS_CODE83	;else handle not in use; error
	    JMP     SM_EXIT		;exit
SM_HACTIVE:
	MOV	AX,DX			    ;DI = requested handle's       @RH1
	MOV	DX,TYPE H_SAVE_STRUC	    ; offset into the handle	   @RH1
	MUL	DX			    ; save area 		   @RH1
	MOV	DI,AX			    ;Add the table base to	   @RH1
	ADD	DI,OFFSET HANDLE_SAVE_AREA  ; make ES:DI a pointer	   @RH1

					;-------------------------------------
					; Insure save area free for this hndl บ
SM_AREACHECK:				;-------------------------------------
	CMP	[DI].PG0_LP,REUSABLE_SAVEA
	JE	SM_SAVE_OK		;If 1st entry free then OK to save @RH1
	   MOV	   AH,EMS_CODE8D	;Else page map already saved for
	   JMP	   SM_EXIT		; this handle.	Exit with error
SM_SAVE_OK:
	CALL	SAVE_PGFRM_MAP		;Save to area pointed to by ES:DI  @RH1
	XOR	AH,AH			;Set good return code
SM_EXIT:
	POP	ES			;restore these registers
	POP	DS
	POP	SI
	POP	DI
	POP	DX
	RET				;return to caller
SAVE_MAP ENDP

;-----------------------------------------------------------------------;
;	Subroutine:  SAVE PAGE FRAME MAP				;
;									;
;	purpose:  To save the map of the 4 pages within the		;
;		  page frame to a save area pointed to by ES:DI.	;
;		  The handle ID and logical page active within each	;
;		  of the 4 physical pages is saved.  Each is a word	;
;		  value.						;
;	called by:  Save mapping array (Function 8) using a handle ID	;
;		     and our save area. 				;
;		    Get page map (Function 15 subfunction 0) without	;
;		     a handle ID using the application's save area.     ;
;									;
;	on entry: ES:DI points to save area				;
;									;
;	on exit:  All registers preserved				;
;-----------------------------------------------------------------------;
SAVE_PGFRM_MAP PROC
	PUSH	AX			;save these registers
	PUSH	CX
	PUSH	DI
	PUSH	SI
	PUSH	DS

	PUSH	CS			;get this segment into DS
	POP	DS
					;-------------------------------------
					; Read the current handle ID and log  บ
					;  pg #s in the mappable phys pg tableบ
					;-------------------------------------
	CLD				;Set direction for STOSW forward   @RH5
	XOR	SI,SI			;Clear offset into mappable phys.  @RH5
	MOV	CX,map_count		; page table.  Loop for # entries  @RH5
SM_HLP_STORE:					  ;Store the word for the  @RH5
	MOV	AX,MAP_TABLE.PPM_HANDLE[SI]	  ; currently active handle@RH5
	STOSW					  ; and logical page into  @RH5
	MOV	AX,MAP_TABLE.PPM_LOG_PAGE[SI]	  ; the save area at ES:DI @RH5
	STOSW					  ; STOSW moves AX to ES:DI@RH5
	ADD	SI,TYPE MAPPABLE_PHYS_PAGE_STRUCT ;Next entry in mpp table @RH5
	LOOP	SM_HLP_STORE			  ;			   @RH5

	POP	DS			;Recover these registers
	POP	SI
	POP	DI
	POP	CX
	POP	AX
	RET				;return to caller
SAVE_PGFRM_MAP ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for RESTORE MAPPING CONTEXT       Function 9	บ
;บ									บ
;บ	on entry: (AH) = '48'x                                          บ
;บ		  (DX) = handle assigned to the interrupt service	บ
;บ			 routine (i.e. handle map was saved under).	บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
RESTORE_MAP PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS			;save these registers

	PUSH	CS			;Get CS into DS (save area is in
	POP	DS			; this segment)

	CMP	DX,NUM_HANDLES-1	;handle within range ?
	JBE	RM_DXINRANGE		;if not then...
	    MOV     AH,EMS_CODE83	;handle not found
	    JMP     RM_EXIT		;exit
RM_DXINRANGE:
	PUSH	DX			;Handle destroyed by MUL	   @RH1
	MOV	AX,DX			;SI = requested handle's           @RH1
	MOV	DX,TYPE H_LOOKUP_STRUC	; offset into the handle	   @RH1
	MUL	DX			; lookup table			   @RH1
	MOV	SI,AX			;				   @RH1
	POP	DX			;Restore handle ID		   @RH1

	CMP	HANDLE_LOOKUP_TABLE.H_Pages[SI],REUSABLE_HANDLE
	JNE	RM_HACTIVE		;If handle is in use (active), ok  @RH1
	    MOV     AH,EMS_CODE83	;else handle not in use; error
	    JMP     RM_EXIT		;exit
RM_HACTIVE:
	MOV	AX,DX				 ;SI = requested handle's  @RH1
	MOV	DX,TYPE H_SAVE_STRUC		 ; offset into the handle  @RH1
	MUL	DX				 ; save area		   @RH1
	MOV	SI,AX				 ;Add the table base to    @RH1
	ADD	SI,OFFSET HANDLE_SAVE_AREA	 ; make DS:SI a pointer    @RH1

					;-------------------------------------
					; Insure save area used for this hndl บ
RM_AREACHECK:				;-------------------------------------
	CMP	[SI].PG0_LP,REUSABLE_SAVEA	 ;Unused save table entry? @RH1
	JNE	RM_SAVE_OK			 ;No used..OK check next   @RH1
	   MOV	   AH,EMS_CODE8E		 ;Yes error ..no page map
	   JMP	   RM_EXIT			 ; saved. Exit.

					;-------------------------------------
					; Call RESTORE_PGFRM_MAP	      บ
RM_SAVE_OK:				;-------------------------------------
	CALL	RESTORE_PGFRM_MAP	;Restore page frame map
	CMP	AH,0			;Successful?
	JNE	RM_EXIT 		;No  exit

					;-------------------------------------
					; Clear the save area for the handle  บ
					;-------------------------------------
					;DS:SI still ptr to save area  @RH5
	MOV	CX,map_count		;Clear all saved entries       @RH5
RM_CLEAR_SA:				    ;Use an overlay to mark the    @RH5
	MOV	[SI].HSA_LP,REUSABLE_SAVEA  ; save area free - put reusabl @RH5
	ADD	SI,TYPE H_SAVEA_ENTRY	    ; indicator in the log p field @RH5
	LOOP	RM_CLEAR_SA		    ;				   @RH5

RM_EXIT:
	POP	DS			;restore these registers
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	RET				;return to caller
RESTORE_MAP ENDP

;-----------------------------------------------------------------------;
;	Subroutine: RESTORE PAGE FRAME MAP				;
;									;
;	purpose:  To restore the map of the 4 pages within the		;
;		  page frame from a save area pointed to by DS:SI.	;
;		  The save area consists of a handle ID and logical	;
;		  page for each of the 4 physical pages.  Each is a	;
;		  word value.						;
;	called by:  Restore mapping context (Function 9) using a	;
;		     handle ID and our save area.			;
;		    Set page map (Function 15 subfunction 1) without	;
;		     a handle ID using the application's save area.     ;
;									;
;	on entry: DS:SI points to the save area 			;
;									;
;	on exit:  (AX) = Status 					;
;			 All other registers preserved			;
;									;
;-----------------------------------------------------------------------;
RESTORE_PGFRM_MAP PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI

	XOR	DI,DI			;Use for mappable phys page table  @RH5
	MOV	CX,map_count		;Loop for all pages in page frame  @RH5
RP_RSTR_LP:				;				   @RH5
	PUSH	DS				   ;Get the phys page from @RH5
	MOV	AX,MAP_TABLE.PHYS_PAGE_NUMBER[DI]  ; the map phys pg tbl   @RH5
	POP	DS				   ; (only AL is used)	   @RH5
	MOV	DX,[SI] 			   ;DX = Handle ID..inc SI @RH5
	ADD	SI,TYPE PG0_HNDL		   ; by len needed for hnd @RH5
	MOV	BX,[SI] 			   ;BX = Log. page..inc SI @RH5
	ADD	SI,TYPE PG0_LP			   ; by len needed for lp  @RH5
	CALL	MAP_L_TO_P			   ;Call main Map module   @RH5
	CMP	AH,0				   ;If an error occurred   @RH5
	JE	RP_NEXT 			   ; anywhere set software @RH5
	MOV	AH,EMS_CODE80			   ; error and exit	   @RH5
	JMP	SHORT RP_EXIT			   ;Else map next page	   @RH5
RP_NEXT:					   ;Advance offset into    @RH5
	ADD	DI,TYPE MAPPABLE_PHYS_PAGE_STRUCT  ; map phys page table   @RH5
	LOOP	RP_RSTR_LP			   ;Loop for 4 EMS pages   @RH5

RP_EXIT:
	POP	SI
	POP	DI			;Restore entry regs
	POP	DX
	POP	CX
	POP	BX
	RET				;return to caller
RESTORE_PGFRM_MAP ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET EMM HANDLE COUNT	      Function 12	บ
;บ									บ
;บ	on entry: (AH) = '4B'x                                          บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (BX) = number of open (active) EMS handles		บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_OPEN	PROC
	PUSH	CX			;save these registers
	PUSH	SI
	PUSH	DS

	PUSH	CS			;get this segment
	POP	DS			;into ds

	XOR	BX,BX			;clear open handle counter
	XOR	SI,SI			;SI = offset of handle lookup table@RH1
	MOV	CX,NUM_HANDLES		;loop counter = number of handles
QH_CHECKALL:
	CMP	HANDLE_LOOKUP_TABLE.H_Pages[SI],REUSABLE_HANDLE
						     ;Handle have pages?   @RH1
	JE	QH_NEXTH			     ;No..not active..next @RH1
	INC	BX				     ;Else open handle	   @RH1
QH_NEXTH:
	ADD	SI,TYPE H_LOOKUP_STRUC	;Point to next handle lookup entry @RH1
	LOOP	QH_CHECKALL		; and check it out		   @RH1
	XOR	AH,AH			;good return status

	POP	DS			;recover these registers
	POP	SI
	POP	CX
	RET				;return to caller
Q_OPEN	ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET EMM HANDLE PAGES	      Function 13	บ
;บ			 NOTE - CAN HANDLE HANDLE WITH 0 PAGES		บ
;บ	on entry: (AH) = '4C'x                                          บ
;บ		  (DX) = handle id					บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (BX) = number of pages allocated to this handle	บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_ALLOCATE PROC
	PUSH	DX			;save these registers
	PUSH	SI
	PUSH	DS

	PUSH	CS			;get this segment
	POP	DS			;into ds

	CMP	DX,NUM_HANDLES-1	;DX <= Number of handles	   @RH1
	JBE	QP_DXINRANGE		;Yes OK 			   @RH1
	    MOV     AH,EMS_CODE83	;No out of range..error 	   @RH1
	    JMP     Q_ALLOC_EXIT	;exit				   @RH1
QP_DXINRANGE:
	MOV	AX,DX				      ;SI = offset into    @RH1
	MOV	DX,TYPE H_LOOKUP_STRUC		      ; handle lookup tbl  @RH1
	MUL	DX				      ; for the given	   @RH1
	MOV	SI,AX				      ; handle		   @RH1
	MOV	BX,HANDLE_LOOKUP_TABLE.H_Pages[SI] ;Return # of pages	@RH1

	CMP	BX,REUSABLE_HANDLE	; is this one free				 ;AN004;
	JNE	QP_GOOD_RC		; no, must be a real number			 ;AN004;
		mov	ah,EMS_Code83	; this page is not allocated currently		 ;an004; dms;
		XOR	BX,BX		; yes, zero BX (number of pages)		 ;AN004;
		jmp	Q_Alloc_Exit	; exit the routine				 ;an004; dms;
											 ;AN004;
QP_GOOD_RC:										 ;AN004;
	XOR	AH,AH			;good return status
Q_ALLOC_EXIT:
	POP	DS			;recover these registers
	POP	SI
	POP	DX
	RET				;return to caller
Q_ALLOCATE ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET ALL OPEN HANDLES AND PAGES	Function 14	บ
;บ									บ
;บ	on entry: (AH)	= '4D'x                                         บ
;บ		  ES:DI = Points to an array.  Each entry consists of	บ
;บ			  2 words.  The first word is for an active	บ
;บ			  EMS handle and the 2nd word for the number	บ
;บ			  of pages allocated to that handle.  This	บ
;บ			  procedure will fill in the table, but the	บ
;บ			  requestor must supply a large enough array.	บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  (BX) = Number of active EMS handles			บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
Q_OPEN_ALL PROC
	PUSH	CX			;save these registers
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS

	PUSH	CS			;get this segment
	POP	DS			;into ds

	MOV	DI,cs:[bp].IE_Saved_DI_Reg ;restore di to its value on	- gga P1501 ;an004;
					;entry

	XOR	BX,BX			;Init number of active handles	   @RH1
	XOR	DX,DX			; and handle id 		   @RH1
	XOR	SI,SI			;SI = offset into handle lup table @RH1
	MOV	CX,NUM_HANDLES		;Loop for all entries in h lup tbl @RH1
QHP_CHECKALL:
	MOV	AX,HANDLE_LOOKUP_TABLE.H_Pages[SI]	   ;		   @RH1
	CMP	AX,REUSABLE_HANDLE	;If entry is reusable (free),	   @RH1
	JE	QHP_NEXT		; don't count it.  Check next hndl @RH1
	INC	BX			;Else active handle. Inc hndl cnt  @RH1
	MOV	ES: WORD PTR [DI],DX	;Write handle # in the user's area @RH1
	MOV	ES: WORD PTR [DI+2],AX	;Write # of pages in the 2nd word  @RH1
	ADD	DI,4			;Advance ptr to user's area        @RH1
QHP_NEXT:				;Check next entry in h lup table   @RH1
	ADD	SI,TYPE H_LOOKUP_STRUC	;Inc offset into handle lup table  @RH1
	INC	DX			;Next handle ID
	LOOP	QHP_CHECKALL

	XOR	AH,AH			;good return status

	POP	DS			;restore these registers
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	RET				;return to caller
Q_OPEN_ALL ENDP


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for GET/SET PAGE MAP SUBFUNCTIONS	Function 15	บ
;บ									บ
;บ	on entry: (AH) = '4E'x                                          บ
;บ		  (AL) = subfunction number				บ
;บ		  ES:DI = destination save area for Get Subfunction	บ
;บ		  DS:SI = source save area for Set Subfunction		บ
;บ									บ
;บ	on exit:  (AH) = status 					บ
;บ		  all other registers preserved 			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
SUBFCN_TABLE LABEL WORD
	DW	OFFSET GET_SUBFCN	;0 - Put page frame map into ES:DI array
	DW	OFFSET SET_SUBFCN	;1 - Set page frame map from DS:SI array
	DW	OFFSET GET_SET_SUBFCN	;2 - Put page frame map into ES:DI array
					;and Set page frame map from DS:SI array
MAX_SUBFCN EQU	($-SUBFCN_TABLE)/2	;maximum allowable subfunction number
	DW	OFFSET SIZE_SUBFCN	;3 - Return storage requirements of the
					;Get and Set subfunctions
GET_SET_MAP PROC
	MOV	DI,cs:[bp].IE_Saved_DI_Reg ;restore di to its value on
	PUSH	BX			;save bx
	CMP	AL,MAX_SUBFCN		;is subfunctiion number within range?
;	$IF	BE			;do if yes...
	JNBE $$IF86
	    MOV     BX,OFFSET GET_SET_EXIT ;get return address common to all subfcns
	    PUSH    BX			;put it on stack for return
	    XOR     AH,AH		;adjust ax to make it
	    ADD     AX,AX		;     offset into jump table
	    MOV     BX,AX		;get it into bx for jump
;At entry to subfunction handler:
;	CS	= INT67 code segment
;	TOP OF STACK is return address, GET_SET_EXIT

	    JMP     CS:SUBFCN_TABLE[BX] ;call subfunction handler
;	$ENDIF
$$IF86:
					;if subfcn # is out of range then do...
	MOV	AH,EMS_CODE8F		;function call out of range
GET_SET_EXIT:
	POP	BX			;recover bx
	RET				;return to caller
GET_SET_MAP ENDP


	page
;-----------------------------------------------------------------------;
;	Subfunction 0 to GET PAGE MAP		      Function 15/0	;
;									;
;	on entry: (AH) = '43'x                                          ;
;		  (AL) = 0						;
;		  ES:DI = Destination save area 			;
;									;
;	on exit:  (AH) = status 					;
;		  all other registers preserved 			;
;-----------------------------------------------------------------------;
GET_SUBFCN PROC
	PUSH	DI			;save
	PUSH	ES			;save


	CALL	SAVE_PGFRM_MAP		;save page frame map to ES:DI
	XOR	AH,AH			;good return status
	POP	ES			;restore
	POP	DI			;restore
	RET				;return to caller
GET_SUBFCN ENDP


;-----------------------------------------------------------------------;
;	Subfunction 1 to SET PAGE MAP		      Function 15/1	;
;									;
;	on entry: (AH) = '43'x                                          ;
;		  (AL) = 1						;
;		  DS:SI = Source save area				;
;									;
;	on exit:  (AH) = status 					;
;		  all other registers preserved 			;
;-----------------------------------------------------------------------;
SET_SUBFCN PROC
	PUSH	SI			;save
	PUSH	DS			;save
	CALL	RESTORE_PGFRM_MAP	;restore page frame map from DS:SI
	XOR	AH,AH			;good return status
	POP	DS			;restore
	POP	SI			;restore
	RET				;return to caller
SET_SUBFCN ENDP


;-----------------------------------------------------------------------;
;	Subfunction 2 to GET and SET PAGE MAP	      Function 15/2	;
;									;
;	on entry: (AH) = '43'x                                          ;
;		  (AL) = 2						;
;		  ES:DI = destination save area 			;
;		  DS:SI = source save area				;
;									;
;	on exit:  (AH) = status 					;
;		  all other registers preserved 			;
;-----------------------------------------------------------------------;
GET_SET_SUBFCN PROC
	PUSH	DI
	PUSH	SI

	MOV	DI,cs:[bp].IE_Saved_DI_Reg	    ;restore di to its value on
					;entry into irpt handler

	CALL	SAVE_PGFRM_MAP		;save page frame map to ES:DI
	CALL	RESTORE_PGFRM_MAP	;restore page frame map from DS:SI
	XOR	AH,AH			;good return status

	POP	SI
	POP	DI
	RET				;return to caller
GET_SET_SUBFCN ENDP

;-----------------------------------------------------------------------;
;	Subfunction 3 to RETURN SIZE OF SAVE ARRAY    Function 15/3	;
;									;
;	on entry: (AH) = '43'x                                          ;
;		  (AL) = 3						;
;									;
;	on exit:  (AH) = status 					;
;		  (AL) = Number of bytes needed for a GET or SET	;
;		  all other registers preserved 			;
;-----------------------------------------------------------------------;
SIZE_SUBFCN PROC
	MOV	AL,TYPE H_SAVE_STRUC	;get size requirements for save area
	XOR	AH,AH			;good return status
	RET				;return to caller
SIZE_SUBFCN ENDP

;=========================================================================
; Set_Instance		This routine accesses the instance table.
;
;	Inputs	: Instance_Table - Table of instances of reentrancy.
;
;	Outputs : BP - pointer to instance table entry to use
;		  NC - instance table entry found
;		  CY - no instance table entry found
;		  AH - error code on CY
;=========================================================================

Set_Instance	proc				;set the instance table 	;an000; dms;

	cli					;disable interrupts		;an000; dms;
	push	cx				;				;an000; dms;

	mov	bp,offset cs:Instance_Table	;get pointer to instance table	;an000; dms;
	mov	cx,Instance_Count		;number of instances		;an000; dms;

Set_Instance_Loop:

	cmp	cs:[bp].IE_Alloc_Byte,Unallocated;unallocated entry?		 ;an000; dms;
	je	Set_Instance_Found		;open entry			;an000; dms;
	add	bp,Instance_Size		;next instance			;an000; dms;
	loop	Set_Instance_Loop		;continue			;an000; dms;

	mov	ah,EMS_Code80			;not enough instance entries	;an000; dms;
	stc					;signal error			;an000; dms;
	jmp	Set_Instance_Exit		;exit routine			;an000; dms;

Set_Instance_Found:

	mov	cs:[bp].IE_Alloc_Byte,Allocated ;instance allocated		;an000; dms;
	clc					;signal good exit		;an000; dms;

Set_Instance_Exit:

	pop	cx				;restore regs			;an000; dms;
	sti					;turn on interrupts		;an000; dms;

	ret					;return 			;an000; dms;

Set_Instance	endp				;				;an000; dms;

;=========================================================================
; Reset_Instance	This routine accesses the instance table.
;
;	Inputs	: BP - pointer to currently active instance entry
;
;	Outputs : Instance_Table - Deactivated instance entry
;=========================================================================

Reset_Instance	proc

	cli					;turn off interrupts		;an000; dms;
	mov	cs:[bp].IE_Alloc_Byte,Unallocated;deallocate instance		 ;an000; dms;
	sti					;set interrupts 		;an000; dms;

	ret					;return 			;an000; dms;

Reset_Instance	endp				;				;an000; dms;


;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
;บ	Entry point for UNSUPPORTED FUNCTION CALLS			บ
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
UNSUPPORTED PROC

GET_PORT_ARRAY:
GET_L_TO_P:
	RET
UNSUPPORTED ENDP


;=========================================================================
; EMS_Page_Contig_Chk	- This routine will take CX as input, which is
;			  the count of pages needed to satisfy the
;			  Allocate, Allocate Raw, or Reallocate functions.
;			  It will scan the unallocated page list to
;			  determine if there are CX number of contiguous
;			  pages.  When it finds a block of contiguous
;			  pages it will return a pointer in SI pointing
;			  to the first page in the linked list that contains
;			  CX contiguous pages.	If CX contiguous pages are
;			  not found a CY will be returned.
;
;	Inputs	: CX (Pages needed for request)
;
;	Outputs : CY (There are no CX contiguous pages)
;		  NC (There are CX contiguous pages)
;		  SI (Pointer to 1st. page of CX contiguous pages)
;=========================================================================

EMS_Page_Contig_Chk	proc	near			;determine contiguity	;an001; dms;

	push	ax					;save regs		;an001; dms;
	push	bx					;			;an001; dms;
	push	cx					;			;an001; dms;
	push	dx					;			;an001; dms;
	push	di					;			;an001; dms;

;;;;	mov	ax,cs:Free_Pages			;initialize page count	;an001; dms;
	mov	di,cs:PAL_Free_Ptr			;pointer to free list	;an001; dms;
	mov	si,di					;initialize ptr val	;an001; dms;
;;;;	mov	bx,di					;initialize base val	;an001; dms;
;;;;	mov	dx,1					;initialize count val	;an001; dms;

EMS_Page_Contig_Main_Loop:

;;;;	cmp	dx,cx					;at end?		;an001; dms;
;;;;	je	EMS_Page_Found_Contig			;yes - found contig	;an001; dms;

;;;;	shl	di,1					;index value		;an001; dms;
;;;;	mov	si,Page_Alloc_List[di]			;point to next free	;an001; dms;
;;;;	shr	di,1					;ptr value		;an001; dms;
;;;;	dec	di					;see if it is contig	;an001; dms;
;;;;	cmp	si,di					;			;an001; dms;
;;;;	je	EMS_Page_Contig_Loop			;contig - check next	;an001; dms;
;;;;	jmp	EMS_Page_Contig_Init_Loop		;not contig		;an001; dms;

EMS_Page_Contig_Loop:

;;;;	inc	dx					;inc loop counter	;an001; dms;
;;;;	jmp	EMS_Page_Contig_Main_Loop		;continue		;an001; dms;

EMS_Page_Contig_Init_Loop:

;;;;	sub	ax,dx					;adjust pages left cnt	;an001; dms;
;;;;	cmp	ax,cx					;enough left?		;an001; dms;
;;;;	jb	EMS_Page_Not_Contig			;no contig memory	;an001; dms;
;;;;	mov	bx,si					;reinit base val	;an001; dms;
;;;;	mov	di,si					;reinit ptr val 	;an001; dms;
;;;;	mov	dx,1					;reinit count val	;an001; dms;
;;;;	jmp	EMS_Page_Contig_Main_Loop		;continue check 	;an001; dms;

EMS_Page_Not_Contig:

;;;;	stc						;signal not contig	;an001; dms;
;;;;	jmp	EMS_Page_Contig_Exit			;exit routine		;an001; dms;

EMS_Page_Found_Contig:

	clc						;signal contig		;an001; dms;
;;;;	mov	si,bx					;pass ptr to 1st.	;an001; dms;

EMS_Page_Contig_Exit:

	pop	di					;restore regs		;an001; dms;
	pop	dx					;			;an001; dms;
	pop	cx					;			;an001; dms;
	pop	bx					;			;an001; dms;
	pop	ax					;			;an001; dms;

	ret						;return to caller	;an001; dms;

EMS_Page_Contig_Chk	endp				;end proc		;an001; dms;



;=========================================================================
; EMS_Link_Set		- This routine takes the SI returned from
;			  EMS_Page_Cont_Chk and removes CX pages from
;			  the linked list for the new handle.
;
;	Inputs	: SI - Pointer value to the beginning of pages for handle
;		  CX - Count of pages to be allocated
;
;	Outputs : Adjusted unallocated list
;		  SI - Pointer value to beginning of pages for handle
;=========================================================================


EMS_Link_Set	proc	near				;set contig links	;an001; dms;

	push	ax					;save regs		;an001; dms;
	push	bx					;			;an001; dms;
	push	cx					;			;an001; dms;
	push	dx					;			;an001; dms;
	push	di					;			;an001; dms;

;;;;	cmp	si,cs:PAL_Free_Ptr			;at root?		;an001; dms;
;;;;	je	EMS_Link_Set_Up_Root			;yes - set up links	;an001; dms;

;;;;	mov	di,cs:PAL_Free_Ptr			;get first free link	;an001; dms;

EMS_Link_Set_Up_Search_Loop:

;;;;	shl	di,1					;get index value	;an001; dms;
;;;;	cmp	si,Page_Alloc_List[di]			;pointers match?	;an001; dms;
;;;;	je	EMS_Link_Set_Up 			;yes - set up links	;an001; dms;
;;;;	mov	di,Page_Alloc_List[di]			;get next pointer	;an001; dms;
;;;;	jmp	EMS_Link_Set_Up_Search_Loop		;continue		;an001; dms;

EMS_Link_Set_Up:

;;;;	mov	ax,di					;save index value	;an001; dms;
;;;;	mov	di,si					;point to first link	;an001; dms;
;;;;	mov	dx,1					;init loop counter	;an001; dms;

EMS_Link_Set_Up_Loop:

;;;;	cmp	dx,cx					;at end?		;an001; dms;
;;;;	je	EMS_Link_Set_Up_Loop_Exit		;yes - exit		;an001; dms;

;;;;	shl	di,1					;index value		;an001; dms;
;;;;	mov	di,Page_Alloc_List[di]			;next ptr		;an001; dms;
;;;;	inc	dx					;inc counter		;an001; dms;
;;;;	jmp	EMS_Link_Set_Up_Loop			;continue		;an001; dms;

EMS_Link_Set_Up_Loop_Exit:

;;;;	shl	di,1					;index value		;an001; dms;
;;;;	mov	bx,Page_Alloc_List[di]			;get next link		;an001; dms;
;;;;	mov	di,ax					;get orig. link 	;an001; dms;
;;;;	mov	Page_Alloc_List[di],bx			;hook up links		;an001; dms;
;;;;	jmp	EMS_Link_Set_Up_Exit


EMS_Link_Set_Up_Root:

	mov	di,si					;point to first link	;an001; dms;
	xor	dx,dx					;init loop counter	;an001; dms;

EMS_Link_Set_Up_Root_Loop:

	cmp	dx,cx					;at end?		;an001; dms;
	je	EMS_Link_Set_Up_Root_Exit		;yes - exit		;an001; dms;

	shl	di,1					;index value		;an001; dms;
	mov	di,Page_Alloc_List[di]			;next ptr		;an001; dms;
	inc	dx					;inc counter		;an001; dms;
	jmp	EMS_Link_Set_Up_Root_Loop		;continue		;an001; dms;

EMS_Link_Set_Up_Root_Exit:

	mov	cs:PAL_Free_Ptr,di			;new free ptr		;an001; dms;
	jmp	EMS_Link_Set_Up_Exit			;exit routine		;an001; dms;

EMS_Link_Set_Up_Exit:

	pop	di					;restore regs		;an001; dms;
	pop	dx					;			;an001; dms;
	pop	cx					;			;an001; dms;
	pop	bx					;			;an001; dms;
	pop	ax					;			;an001; dms;

	ret						;return to caller	;an001; dms;

EMS_Link_Set	endp					;			;an001; dms;




;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ								     ณ
;ณ	LIM 4.0 functions are kept in a seperate include file,	     ณ
;ณ	LIM40.INC						     ณ
;ณ								     ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
include lim40.inc

Instance_Table	db	Instance_Size*Instance_Count dup(Unallocated)  ;instance table	     ;an000; dms;

RESIDENT:				;last address that must stay resident
PAGE
PAGE

INCLUDE EMSINIT.INC			;Main file for throwaway
					; initialization code
INCLUDE XMA1DIAG.INC			;XMA 1 diagnostics and routines
INCLUDE PS2_5060.INC			;Diagnostics for PS/2 models 50    @RH2
					; and 60.  Support for XMA/A and   @RH2
					; MXO cards	 		   @RH2
INCLUDE XMA2EMS.CL1


TEMP_STACK DB	STACK_SIZE DUP(0)	;RESERVE FOR TEMP STACK
TOP_OF_STACK DB ?			;DURING INITIALIZATION

CSEG	ENDS
	END	START


