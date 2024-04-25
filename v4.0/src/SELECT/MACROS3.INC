;;****************************************************************************
;;     Assembler MACROS for use with SELECT.
;;     File: MACROS3.INC
;;     Latest Change Date: July 28, 1987
;;
;; These macros define powerful assembler verbs neccessary for SELECT.
;;
;; Note: Many of the macros make use of an ASCII-N string for passing
;;	 parameters.  The string is defined below.
;;		   DW  count
;;		   DB  "string_variable",?
;;
;;	 COUNT is the length of the string and is a word.
;;	 It is necessary to follow the string with at least one byte for the
;;	 purpose of changing the ASCII-N string to an ASCII-Z string.
;;
;;****************************************************************************
page					;AN000;
;;************************************************************************;;
;;
;;   CHECK_DEFAULT_DRIVE:  Determine if default drive is drive A:
;;
;;   SYNTAX:  CHECK_DEFAULT_DRIVE
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 CY = 0:  Drive A is the default drive
;;	 CY = 1:  Drive A is NOT the default drive
;;
;;   OPERATION:  DOS Function Call 19h is performed to get the default drive.
;;	 If the default drive is not drive A (AL <> 0), the carry flag is set.
;;
;;************************************************************************;;
CHECK_DEFAULT_DRIVE	MACRO			 ;;AN000;
    MOV  AH, 19H				 ;;AN000; Fn. Number for getting current drive
    DOSCALL					 ;;AN000;
    .IF < ZERO AL >				 ;;AN000; Is A the default drive?
	 CLC					 ;;AN000; Yes!
    .ELSE					 ;;AN000;
	 STC					 ;;AN000; No!
    .ENDIF					 ;;AN000;
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   CHECK_DISK:  Check is the specified fixed disk is present.  If disk is
;;	 present, return disk partition status.
;;
;;   SYNTAX:  CHECK_DISK  immed_disk, var_disk, var_status, var_status_2, buffer
;;
;;   INPUT:
;;	 immed_disk = 1: First fixed disk.
;;		    = 2: Second fixed disk.
;;
;;   OUTPUT:
;;	 var_disk = 0: Disk not present.
;;		  = 1: Disk present - No DOS or EDOS partitions
;;		  = 2: Disk present - DOS or EDOS partitions exist
;;	 var_status = 01H: Primary DOS partition exists
;;		    = 02H: Extended DOS partitions exists
;;		    = 04H: Logical drives exist
;;		    = 08H: Free space exists in EDOS partition
;;		    = 10H: Free space exists on disk
;;			       More than one status bit can be set
;;	 var_status_2 = 0: There is no free space in EDOS partition and the
;;			   disk.
;;		      = 1: There is free space in the EDOS partition.
;;		      = 2: There is no EDOS partition, but there is free
;;			   disk space.
;;	 buffer   = Buffer for fixed disk status information.
;;
;;   OPERATION:  A call is performed to the FDISK utility (GET_DISK_STATUS)
;;	 to get the status of the specified fixed disk drive.  The returned
;;	 status information is checked and the memory variables are set as
;;	 specified above.
;;
;;************************************************************************;;
CHECK_DISK	MACRO	IMMED_DISK, VAR_DISK, VAR_STATUS, VAR_STATUS_2, BUFFER ;;AN000;

    LEA  DI, BUFFER				;;AN000;
    MOV  AX, IMMED_DISK 			;;AN000;
    CALL CHECK_DISK_ROUTINE			;;AN000;
    MOV  VAR_DISK, CX				;;AN000;
    MOV  VAR_STATUS, BX 			;;AN000;
    MOV  VAR_STATUS_2, DX			;;AN000;
    ENDM					;;AN000;
;;************************************************************************;;
;;
;;   CHECK_DISKETTE:  Check the type of diskettes attached to the system.
;;
;;   SYNTAX:  CHECK_DISKETTE  var_disk_a, var_disk_b, var_tot, buffer
;;
;;   INPUT:
;;	 buffer  = Buffer for IOCTL
;;
;;   OUTPUT:
;;	 var_disk_a = 0FFH Diskette drive A not present
;;		    = 0 360k diskette (5.25 inch)
;;		    = 1 740K diskette (3.5  inch)
;;		    = 2 1.2M diskette (5.25 inch)
;;		    = 7 1.44M diskette (3.5 inch)
;;	 var_disk_b = 0FFH Diskette drive B not present
;;		    = 0, 1, 2, 7 as defined above for diskette A.
;;	 var_tot    = total number of diskettes attached (1 or 2)
;;
;;   OPERATION:  Interrupt 11H is performed to get equipment status.  The number
;;	 of diskettes attached will be returned as specified above.  A call
;;	 is then made to the IOCTL function of DOS (AH = 44h) to get the type
;;	 of media the disk drives are.	The function returns its data in a
;;	 26 byte buffer, where the second byte contains a description of the
;;	 drive.  The codes are as follows:
;;		0 = 320/360 KB 5-1/4-inch
;;		1 = 5-1/4-inch, 1.2 MB
;;		2 = 3-1/2-inch, 720 KB
;;		3 = 8 inch single density
;;		4 = 8 inch double density
;;		5 = Fixed disk
;;		6 = Tape drive
;;		7 = Other
;;
;;************************************************************************;;
CHECK_DISKETTE	MACRO	VAR_DISK_A, VAR_DISK_B, VAR_TOT, BUFFER ;;AN000;
    INT     11H 				 ;;AN000; See how many diskette drives there are
    .IF < BIT AL NAND DISKETTES_EXIST > 	 ;;AN000; Are there diskettes?
	 MOV	 AX, 0				 ;;AN000; There are no diskettes.
    .ELSE					 ;;AN000;
	 MOV	 CL,6				 ;;AN000; Number of bits to shift
	 SHR	 AL,CL				 ;;AN000; Diskette bits are 6 and 7.  Shift to right
	 MOV	 AH, 0				 ;;AN000; Clear the high byte
	 INC	 AX				 ;;AN000; Make into the actual number of diskettes
	 .IF < AX GT MAX_NUM_DISKETTE > 	 ;;AN000; Are there more then 2 diskette drives?
	      MOV     AX, MAX_NUM_DISKETTE	 ;;AN000; Yes, but we are only concern with two.
	 .ENDIF 				 ;;AN000;
    .ENDIF					 ;;AN000;
    MOV     VAR_TOT, AL 			 ;;AN000; Store the number of diskette drives.
    ;;**********************************************************************
    ;; Examine diskette drive A first.
    ;;**********************************************************************
    MOV   VAR_DISK_A, E_DISKETTE_INV		 ;;AN000;
    MOV   VAR_DISK_B, E_DISKETTE_INV		 ;;AN000;
    MOV   DI, OFFSET VAR_DISK_A 		 ;;AN000;
    .FOR BL = 1 TO VAR_TOT			 ;;AN000;
	 MOV  AX, 440DH 			 ;;AN000;
	 MOV  CX, 0860H 			 ;;AN000;
	 MOV  DX, OFFSET BUFFER 		 ;;AN000;
	 DOSCALL				 ;;AN000;
	 MOV  SI, OFFSET BUFFER + 1		 ;;AN000;
	 MOV  AL, [SI]				 ;;AN000;
	 .IF < AL EQ E_DISKETTE_1200 >		 ;;AN111;JW
	    MOV  AL,E_DISKETTE_360		 ;;AN111;JW
	 .ENDIF 				 ;;AN111;JW
	 .IF < AL EQ E_DISKETTE_1440 >		 ;;AN000;
	      .IF < <WORD PTR [SI+3]> NE E_1440_TRACKS > OR ;;AN000;
	      .IF < <WORD PTR [SI+19]> NE E_1440_SECTORS >  ;;AN000;
		   MOV	AL, E_DISKETTE_INV	 ;;AN000;
	      .else				;yuk- don't have time to get this working on 1.4M drives
		   mov al, e_diskette_720	;so pretend there is no such thing
	      .ENDIF				 ;;AN000;
	 .ENDIF 				 ;;AN000;
	 MOV  [DI], AL				 ;;AN000;
	 MOV  DI, OFFSET VAR_DISK_B		 ;;AN000;
    .NEXT BL					 ;;AN000;
    ;;**********************************************************************
    ;; Check for compatible A: to B: combinations ;AN000;JW
    ;;**********************************************************************
    .IF < VAR_DISK_A eq E_DISKETTE_720 > or	 ;;AN000;JW
    .IF < VAR_DISK_A eq E_DISKETTE_1440 >	 ;;AN000;JW
       .IF < VAR_DISK_B eq E_DISKETTE_360 >	 ;;AN000;JW
	  MOV  VAR_DISK_B, E_DISKETTE_INV	 ;;AN000;JW
	  DEC  VAR_TOT				 ;;AN000;JW
       .ENDIF					 ;;AN000;JW
    .ENDIF					 ;;AN000;JW
    .IF < VAR_DISK_A eq E_DISKETTE_360 >	 ;;AN000;JW
       .IF < VAR_DISK_B eq E_DISKETTE_720 > or	 ;;AN000;JW
       .IF < VAR_DISK_B eq E_DISKETTE_1440 >	 ;;AN000;JW
	  MOV  VAR_DISK_B, E_DISKETTE_INV	 ;;AN000;JW
	  DEC  VAR_TOT				 ;;AN000;JW
       .ENDIF					 ;;AN000;JW
    .ENDIF					 ;;AN000;JW
						 ;;
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   CHECK_VALID_MEDIA:  Check if the diskettes attached will support
;;	 installation of SELECT.  Also, check if install destination will
;;	 be selected by user or determined by SELECT.
;;
;;   SYNTAX:  CHECK_VALID_MEDIA  var_disk_a, var_disk_b, var_tot, var_disk,
;;				 var_def, var_index, var_option
;;
;;   INPUT:
;;	 var_disk_a  =	diskette A presence and type
;;	 var_disk_b  =	diskette B presence and type
;;	 var_tot     =	total number of dikettes
;;	 var_disk    =	0: first fixed disk is not present
;;		     >	0: first fixed disk is present
;;
;;   OUTPUT:
;;	 CY = 0: Success variables are returned as defined below.
;;	 CY = 1: Error - invalid media
;;	 var_def   =  0 use default destination drive
;;		   =  1 default destination drive not applicable
;;	 var_index =  1 default destination is drive C
;;		   =  2 default destination is drive B
;;	 var_option = 1 possible drive B or C
;;		    = 2 possible drive A or C
;;		    = 3 possible drive A or B or C
;;		    = 4 possible drive A or B
;;
;;   OPERATION:  The diskette drive types are checked for valid media type.
;;	 If the diskette media types are valid, a check is made to determine if
;;	 install destination will be user selected or will be determined by
;;	 SELECT.  The following checks are made.
;;
;;	  - if one diskette, return valid media and default destination is A
;;
;;	  - If two diskettes only, return valid and:
;;		if A = B, default = B
;;		if A <> B, default = A
;;		if A and B are mixed 720 and 1.44, destination option is A or B
;;
;;	  - If one diskette and a fixed disk only, return valid media and
;;	    destination option is drive A or C.
;;
;;	  - If two diskettes and a fixed disk, return valid media and:
;;		if A = B, destination option is B or C
;;		if A <> B, destination option is A or C
;;		if A and B are mixed 720 and 1.44, destination option is
;;		  A or B or C
;;
;;************************************************************************;;
CHECK_VALID_MEDIA	MACRO	VAR_DISK_A, VAR_DISK_B, VAR_TOT, VAR_DISK, VAR_DEF, VAR_INDEX, VAR_OPTION ;;AN111;JW

    MOV  AL, VAR_DISK_A 			;;AN111;JW
    MOV  BL, VAR_DISK_B 			;;AN111;JW
    MOV  SI, VAR_DISK				;;AN111;JW
    CALL CHECK_VALID_MEDIA_ROUTINE		;;AN111;JW
    MOV  VAR_DEF, CL				;;AN111;JW
    MOV  VAR_INDEX, DX				;;AN111;JW
    MOV  VAR_OPTION, DI 			;;AN111;JW
    ENDM					;;AN111;JW
;;************************************************************************;;
;;
;;   SCAN_DISK_TABLE:  Scan the specified disk status table from the
;;	 specified index item for specified field and return status information.
;;
;;   SYNTAX:  SCAN_DISK_TABLE	 immed_disk, var_index, var_ref
;;
;;   INPUT:
;;	 immed_disk  = 1: First fixed disk
;;		     = 2: Second fixed disk
;;	 var_index  = Index of the information to return
;;
;;   OUTPUT:
;;	 var_ret       = 0: Success - Index into table is valid
;;		       = 1: Error - Index invalid or end of table
;;	 N_NAME_PART   = Partition name.
;;	 N_SIZE_PART   = Partition size.
;;	 N_STATUS_PART = Partition status
;;	 P_DRIVE_PART  = Drive letter assigned.
;;
;;   OPERATION:
;;	Starts scanning the disk table from the point indicated by var_index
;;	for either the name, status or type.  The table is scanned until either
;;	the desired entry is found, or the end of the table is reached.  If
;;	the end of the table is reached before a marching entry is found, then
;;	var_ret returns 1, else if an entry is found, it returns 0.
;;	If found, var_index will also return the index of the entry.
;;
;;	Note:  The index of the first entry in the table is 1.
;;
;;************************************************************************;;
SCAN_DISK_TABLE MACRO	IMMED_DISK, VAR_INDEX, VAR_RET	;;AN000;

    MOV  CX, IMMED_DISK 			;;AN000;
    MOV  AX, VAR_INDEX				;;AN000;
    CALL SCAN_DISK_TABLE_ROUTINE		;;AN000;
    MOV  VAR_RET, AX				;;AN000;
    ENDM					;;AN000;
;;************************************************************************;;
;;
;;   UPDATE_DISK_TABLE:  Update the specifed disk status table for the
;;	 specified index item.
;;
;;   SYNTAX:  UPDATE_DISK_TABLE  immed_disk, var_index, var_ref
;;
;;   INPUT:
;;	 immed_disk  = 1: First fixed disk
;;		     = 2: Second fixed disk
;;	 var_index   = Index into table
;;
;;   OUTPUT:
;;	 var_ret     = 0: Success - Index into table is valid
;;		     = 1: Error   - Index into table is not valid
;;	 partition name   = N_NAME_PART
;;	 partition size   = N_SIZE_PART
;;	 partition status = N_STATUS_PART
;;	 partition type   = N_TYPE_PART
;;	 drive letter	  = P_DRIVE_PART
;;
;;   OPERATION:  If the index into the disk table is valid, the disk table
;;	 is updated for the specifed index.  Disk status information is obtained
;;	 from pre-defined locations as specified above.
;;
;;************************************************************************;;
UPDATE_DISK_TABLE	MACRO	IMMED_DISK, VAR_INDEX, VAR_REF	;;AN000;

    MOV  CX, IMMED_DISK 			;;AN000;
    MOV  AX, VAR_INDEX				;;AN000;
    CALL UPDATE_DISK_TABLE_ROUTINE		;;AN000;
    MOV  VAR_REF, AX				;;AN000;
    ENDM					;;AN000;
;;************************************************************************;;
;;
;;   GET_PARTITION_SIZE:  Return DOS and EDOS partition size in ASCII-N format.
;;
;;   SYNTAX:  GET_PARTITION_SIZE  var_tot, var_dos, name_dos, name_edos
;;
;;   INPUT:
;;	 var_tot  =  Free disk space
;;	 var_dos  =  Size of DOS partition
;;
;;   OUTPUT:
;;	 name_dos = Size of DOS partition in ASCII-N format.
;;	 name_edos = Size of EDOS partition in ASCII-N format.
;;
;;   OPERATION:  The DOS partition size is converted to ASCII-N format.
;;	 The size of the Extended DOS partition is obtained by subtracting
;;	 the size of DOS partition from the free disk space.  If the size of
;;	 any partition is zero, a zero string length is returned.
;;
;;************************************************************************;;
GET_PARTITION_SIZE	MACRO	VAR_TOT, VAR_DOS, NAME_DOS, NAME_EDOS ;;AN000;
						 ;;
    PUSH VAR_TOT				 ;;AN000; Save the variable
    MOV  AX, VAR_DOS				 ;;AN000; Size of the DOS partition.
    SUB  VAR_TOT, AX				 ;;AN000; Subtract the dos partition size
    WORD_TO_CHAR     VAR_TOT, NAME_EDOS 	 ;;AN000; Convert binay values to ASCII
    WORD_TO_CHAR     VAR_DOS, NAME_DOS		 ;;AN000;
    POP  VAR_TOT				 ;;AN000;
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   CHECK_MACHINE: Return the model byte
;;
;;   SYNTAX:  CHECK_MACHINE mac_type p_flag
;;
;;   INPUT:
;;
;;   OUTPUT:
;;	 mac_type = model byte
;;	 p_flag   = PS2 presence (E_YES, E_NO)
;;
;;   OPERATION:  An INT 15H is executed to return a pointer to the system
;;	 descriptor vector.  The model byte is retrieved from this vector
;;	 and placed in the supplied variable. The ps2 flag is also set.
;;
;;************************************************************************;;
CHECK_MACHINE  MACRO MAC_TYPE, P_FLAG		 ;;AN000;JW
						 ;;
	MOV  AH,0C0H				 ;;AN000; INT 15H system config request
	INT  15H				 ;;AN000; system services
	.IF < nc >				 ;;AN000;
	   MOV	AH,ES: BYTE PTR [BX+2]		 ;;AN000; get the model byte
	.ELSE					 ;;AN000;
	   MOV	AH,00				 ;;AN000;
	.ENDIF					 ;;AN000;
	MOV  MAC_TYPE,AH			 ;;AN000; save the model byte
	MOV  P_FLAG,E_YES			 ;;AN000;
						 ;;
	.IF < AH eq 0 > or			 ;;AN000; if old pc
	.IF < AH eq 0FBH > or			 ;;AN000; if pc XT
	.IF < AH eq 0F9H > or			 ;;AN000; if pc convertible
	.IF < AH eq 0FCH > and			 ;;AN000; if pc AT and
	.IF <<ES:BYTE PTR [BX+3]> le 02 >	 ;;AN000;   sub-model byte le 2
	   MOV	P_FLAG,E_NO			 ;;AN000;     not a ps2
	.ENDIF					 ;;AN000;
	ENDM					 ;;AN000;

INCLUDE  MACROS4.INC				 ;AN000;
