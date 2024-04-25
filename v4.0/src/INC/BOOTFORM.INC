	%OUT BOOTFORM.INC...
;****************************************************************************
;AN000; - Structure of the Extended IBMBOOT record for DOS -. J.K.
;AN001; - D304 Include PHYDRV, CURHD to the header structure	 11/09/87 J.K.
;****************************************************************************

BOOT_SIZE		 EQU	 512
EXT_BOOT_SIGNATURE	 EQU	 41		;Extended boot signature
;
EXT_BPB_INFO		STRUC
EBPB_BYTESPERSECTOR	 DW	 ?
EBPB_SECTORSPERCLUSTER	 DB	 ?
EBPB_RESERVEDSECTORS	 DW	 ?
EBPB_NUMBEROFFATS	 DB	 ?
EBPB_ROOTENTRIES	 DW	 ?
EBPB_TOTALSECTORS	 DW	 ?
EBPB_MEDIADESCRIPTOR	 DB	 ?
EBPB_SECTORSPERFAT	 DW	 ?
EBPB_SECTORSPERTRACK	 DW	 ?
EBPB_HEADS		 DW	 ?
EBPB_HIDDENSECTOR	 DD	 ?
EBPB_BIGTOTALSECTORS	 DD	 ?
EXT_BPB_INFO		ENDS
;
;AN001; EXT_PHYDRV, EXT_CURHD included in the header for OS2.
EXT_IBMBOOT_HEADER	STRUC
EXT_BOOT_JUMP		DB	3 DUP (?)
EXT_BOOT_OEM		DB	8 DUP (?)
EXT_BOOT_BPB		DB	type EXT_BPB_INFO dup (?)
EXT_PHYDRV		DB	80h
EXT_CURHD		DB	0
EXT_BOOT_SIG		DB	EXT_BOOT_SIGNATURE
EXT_BOOT_SERIAL 	DD	?
EXT_BOOT_VOL_LABEL	DB	11 DUP (?)
EXT_SYSTEM_ID		DB	8  DUP (?)
EXT_IBMBOOT_HEADER	ENDS
;
BOOT_SIGNATURE	=     word ptr (BOOT_SIZE-2)

;
;J.K. This is the number of sectors (of size 512 bytes) that will cover
;the size of IBMLOAD program.  IBMBOOT program has to at least read this
;many sectors, and these sectors should be the first cluster and consecutive.
;Make sure IBMBOOT program uses the same value as this.
IBMLOADSIZE	equ	3	;Number of sectors IBMBOOT program should read in.


