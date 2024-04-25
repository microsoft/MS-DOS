BREAK	<EMM control sector layout>

;
; The EMM control sector is a 1024 byte record which ALWAYS occupies the
; very first 1024 bytes of "extra" memory that needs to be managed. Its
; function is to provide a method to allocate available "extra" memory
; to programs which desire to use it and avoid program conflicts that
; would occur if two different programs attempted to use the same piece
; of "extra" memory.
;

;
; The EMM_CTRL structure defines the offsets into the 1024 byte control
; sector of the various fields. The EMM_REC structure defines a sub-structure
; contained within the EMM_CTRL structure which represents a particular
; piece of allocated "extra" memory (an allocation record).
;

; Layout of each EMM record.

EMM_REC 	STRUC
EMM_FLAGS	DW	0
EMM_SYSTEM	DW	0
EMM_BASE	DD	?		; 24 bit address of start of region
EMM_KSIZE	DW	?		; Size of region in kbytes
EMM_REC 	ENDS

; EMM_FLAGS Bits
EMM_ALLOC	EQU	0000000000000001B	; Zero -> record is free
EMM_ISDRIVER	EQU	0000000000000010B	; 1 -> driver is installed
						;      for this region

; EMM_SYSTEM Values
EMM_EMM 	EQU	0			; Allocated to EMM
EMM_MSDOS	EQU	1
EMM_XENIX	EQU	2
EMM_APPLICATION EQU	3

; Layout of EMM control 1024 byte record

EMM_CTRL	STRUC
EMM_VER 	DB	50 DUP(?)
EMM_TOTALK	DW	?		; EXCLUDING the 1k of this record
EMM_AVAILK	DW	?		; Amount of above NOT allocated
		DB	SIZE EMM_REC DUP(?) ; NULL (0th) RECORD
EMM_RECORD	DB	(1024 - 50 - 4 - 10 - (SIZE EMM_REC)) DUP(?)
					  ; EMM_REC structures
EMM_TAIL_SIG	DB	10 DUP(?)
EMM_CTRL	ENDS

EMM_NUMREC	EQU	(1024 - 50 - 4 - 10 - (SIZE EMM_REC)) / (SIZE EMM_REC)


;
; The current initial (no "extra" memory allocated) EMM_CTRL sector is
;
;  EMM_CONTROL	 LABEL	 BYTE
;		   DB	   "MICROSOFT EMM CTRL VERSION 1.00 CONTROL BLOCK     "
;		   DW	   EXTMEM_TOTALK - 1
;		   DW	   EXTMEM_TOTALK - 1
;	   ; NULL 0th record
;		   DW	   EMM_ALLOC + EMM_ISDRIVER
;		   DW	   EMM_EMM
;		   DW	   EXTMEM_LOW + 1024
;		   DW	   EXTMEM_HIGH
;		   DW	   0
;	   ;**
;		   DB	   950 DUP(0)
;		   DB	   "ARRARRARRA"
;
; Where EXTMEM_LOW:EXTMEM_HIGH is the 32 bit address of the first byte
; of the EMM_CTRL sector (first byte of "extra" memory) and EXTMEM_TOTALK
; is the size in K of the available "extra" memory. One is subtracted
; from EXTMEM_TOTALK because the sizes in the EMM_CTRL record DO NOT
; include the 1k taken up by the EMM_CTRL sector.
;
; The reason for the existance of the NULL 0th record is to facilitate
; the computation of EMM_BASE for the first EMM_REC allocation record
; created.
;
; The EMM_REC structures CANNOT be sparse. In other words if one sets
; up a scan of the EMM_REC structures in the EMM_CTRL sector, as soon as
; an EMM_REC structure WITHOUT the EMM_ALLOC bit set in its flag word
; is encountered it is not necessary to scan further because it IS KNOWN
; that all of the EMM_REC structures after the first one with EMM_ALLOC
; clear also have EMM_ALLOC clear. What this means is that EMM_CTRL
; memory CANNOT BE deallocated. Once an EMM_REC structure has its
; EMM_ALLOC bit set, there is NO correct program operation which
; can clear the bit UNLESS it IS KNOWN that the next EMM_REC structure
; has its EMM_ALLOC bit clear or the EMM_REC structure is the last one.
;
;
; USING THE EMM_CTRL SECTOR:
;
;    A program which wishes to use the EMM_CTRL sector to access "extra"
;    memory should work as follows:
;
;	Figure out how much memory you wish to allocate
;
;	Figure out the location and size of the "extra" memory in the system
;
;	IF (the first 1024 bytes of "extra" memory DO NOT contain a valid
;	 EMM_CTRL record determined by checking for the existence of the
;	 correct EMM_VER and EMM_TAIL_SIG strings)
;		Write a correct initial EMM_CTRL sector to the first 1024
;		 bytes of extra memory. Be sure to fill in EMM_TOTALK,
;		 EMM_AVAILK and EMM_BASE in the 0th record.
;
;	Set up a scan of the EMM_REC structures in the EMM_CTRL sector.
;	 NOTE: You can skip the NULL 0th record if you want since it has
;	       known value.
;
;	FOR (i=0;i<EMM_NUMREC;i++)
;		IF ( this EMM_REC has EMM_ALLOC clear)
;			IF ( EMM_AVAILK < amount I want to alloc)
;				ERROR insufficient memory
;			EMM_AVAILK = EMM_AVAILK - amount I want to alloc
;			EMM_FLAGS = EMM_ALLOC + EMM_ISDRIVER
;			EMM_KSIZE = amount I want to alloc
;			EMM_SYSTEM = appropriate value
;			EMM_BASE = EMM_BASE of PREVIOUS EMM_REC +
;				     (1024 * EMM_KSIZE of PREVIOUS EMM_REC)
;			break
;		ELSE
;			address next EMM_REC structure
;
;	IF (i >= EMM_NUMREC)
;		ERROR no free EMM_REC structures
;
;
; You can now see why we need that NUL 0th EMM_REC structure. In order to
; perform this step
;
;	EMM_BASE = EMM_BASE of PREVIOUS EMM_REC +
;		     (1024 * EMM_KSIZE of PREVIOUS EMM_REC)
;
; when the very first EMM_REC is allocated we must have a "previous EMM_REC"
; structure to point at.
;
; The above code is rather simplistic in that all it does is do a simple
; allocation. The EMM_ISDRIVER bit allows us to do some more sophisticated
; things. In particular in the case of a RAMDrive type of program it is
; desirable to "re-find" the same RAMDrive area in "extra" memory when the
; system is re-booted. The EMM_ISDRIVER bit is used to help us do this.
;
; The EMM_ISDRIVER bit means "there is presently a piece of code in the
; system which is using this memory". If we find an EMM_REC structure
; which has its EMM_ALLOC bit set, but the EMM_ISDRIVER bit is clear
; it means that the piece of code that originally allocated
; the memory is gone and we may want to "re-find" this memory by
; setting the EMM_ISDRIVER bit again. A RAMDrive program would have
; slightly different code than the above:
;
;	FOR (i=0;i<EMM_NUMREC;i++)
;		IF ( this EMM_REC has EMM_ALLOC clear)
;			IF ( EMM_AVAILK < amount I want to alloc)
;				ERROR insufficient memory
;			EMM_AVAILK = EMM_AVAILK - amount I want to alloc
;			EMM_FLAGS = EMM_ALLOC + EMM_ISDRIVER
;			EMM_KSIZE = amount I want to alloc
;			EMM_SYSTEM = appropriate value
;			EMM_BASE = EMM_BASE of PREVIOUS EMM_REC +
;				     (1024 * EMM_KSIZE of PREVIOUS EMM_REC)
;			break
;		ELSE
;			IF ((EMM_SYSTEM == my value for EMM_SYSTEM) &&
;			    (EMM_ISDRIVER is clear))
;				deal with differences between amount
;				 I want to allocate and EMM_KSIZE
;				Set EMM_ISDRIVER
;				EMM_BASE is the base address of this piece
;				 of memory and EMM_KSIZE is its size.
;				break
;			address next EMM_REC structure
;
; In this way we "re-find" memory that was previosly allocated (presumably
; by us, or a related program).
;
; NOTE THAT THIS USE OF EMM_ISDRIVER REQUIRES SOME MECHANISM FOR CLEARING
; EMM_ISDRIVER WHEN THE CODE OF INTEREST IS REMOVED FROM THE SYSTEM.
; In the case of a RAMDrive program the code is removed whenever the system
; is re-booted. For this reason a RAMDrive program will need code that is
; invoked whenever a system re-boot is detected. What this code does is
; scan the EMM_REC structures in the EMM_CTRL sector turning off the
; EMM_ISDRIVER bits:
;
;	FOR (i=0;i<EMM_NUMREC;i++)
;		IF ( this EMM_REC has EMM_ALLOC clear)
;			break
;		ELSE IF (EMM_SYSTEM == my value for EMM_SYSTEM)
;			clear EMM_ISDRIVER bit
;		address next EMM_REC
;
; Note that this code clears ALL of the ISDRIVER bits for EMM_SYSTEM
; values of a certain value. This means there is a GLOBAL piece of
; re-boot code for ALL of the programs using a particular EMM_SYSTEM
; value. An alternative is to have each EMM_CTRL user clear the
; EMM_ISDRIVER bits ONLY for those EMM_REC structures that it allocated.
; This requires that the program keep a record of which EMM_REC structures
; it is responsible for:
;
;	FOR each of my EMM_REC structures
;		INDEX this EMM_REC structure in the EMM_CTRL sector
;		Clear EMM_ISDRIVER
;
; NOTE about this step:
;
;	deal with differences between amount
;	 I want to allocate and EMM_KSIZE
;
; in the above code. There are a lot of options here depending on the desired
; behavior. If the NEXT EMM_REC structure has EMM_ALLOC clear, then it may
; be possible for me to grow or shrink the block I found by adjusting
; EMM_KSIZE and EMM_AVAILK. If the NEXT EMM_REC structure has EMM_ALLOC
; set, then I am forced to either adjust the amount I want to allocate
; to match EMM_KSIZE, or skip this EMM_REC without setting EMM_ISDRIVER.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; for rom 1nt15 extended memory interface
emm_int      equ    15h
emm_size     equ    88h
emm_blkm     equ    87h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
