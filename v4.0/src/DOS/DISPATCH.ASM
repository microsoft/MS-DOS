;	SCCSID = @(#)dispatch.asm	1.1 85/04/10
;	SCCSID = @(#)dispatch.asm	1.1 85/04/10
;
; Major dispatch code and table for MSDOS 2.X and above.
;
;   Modification history:
;
;	Created: MZ 30 March 1983
;
; The system calls are dispatched to in such a fashion as to have their entire
; register set passed to them except for CS:IP and SS:SP.  This reduces the
; need for retreiving information from the user's stack.
;
; There are also critical sections that need to be observed when running in a
; multitasking environment.  These sections are:
;
;   1	critDisk    any of the disk code that will twiddle the buffer cache
;   2	critDevice  all device drivers
;
;   4	critMem     memory allocation stuff
;   5	critNet     network critical section
;
; The system calls below are noted as to which of these critical sections they
; belong.  The critical sections are noted in the source files by the macros
; EnterCrit and LeaveCrit.
;
; The break-down of the individual system calls into source files is as
; follows (* means done):
;
;   *	handle.asm:	Close, Read, Write, LSeek, XDup, XDup2, FileTimes
;	IOCTL.INC:	IOCTL
;   *	file.asm:	Open, Creat, ChMod, Unlink, Rename, CreateTemp,
;			CreateNew
;   *	srvcall.asm:	$ServerCall
;   *	path.asm:	MkDir, RmDir, ChDir, CurrentDir
;   *	alloc.asm:	$Alloc, $Dealloc, $SetBlock, $AllocOper
;			arena_free_process, arena_next -> LOW LEVEL <-
;			check_signature, Coalesce
;   *	search.asm:	DirSearchFirst, DirSearchNext, FindFirst, FindNext,
;			PackName		 -> LOW LEVEL <-
;   *	proc.asm:	Exec, Exit, Abort, Wait, KeepProcess
;   *	cpmio.asm:	StdConInput, StdConOutput, StdAuxInput, StdAuxOutput,
;			StdPrinterOutput, RawConIO, RawConInput,
;			StdConInputNoEcho, StdConStringInput,
;			StdConStringOutput, StdConInputStatus,
;			StdConInputFlush
;			OUT, BUFOUT, RAWOUT, RAWOUT2	-> LOW LEVEL <-
;   *	fcbio.asm:	FCBOpen, FCBClose, FCBDelete, FCBSeqRead, FCBSeqWrite,
;			FCBCreate, FCBRename, FCBRandomRead, FCBRandomWrite,
;			GetFCBFileLength, GetFCBPosition, FCBRandomReadBlock,
;			FCBRandomWriteBlock
;   *	Time.asm:	GetDate, SetDate, GetTime, SetTime
;   *	Parse.asm:	Parse_file_descriptor, PathParse
;   *	GetSet.asm:	GetInterruptVector, SetInterruptVector,
;			GetVerifyOnWrite, SetVerifyOnWrite, GetDMA, SetDMA,
;			GetVersion, SetCTRLCTrapping, GetDriveFreespace,
;			CharOper, International, SetDefaultDrive,
;			GetDefaultDrive
;   *	Misc.asm:	Sleazefunc, SleazefuncDL, GetDefaultDPB, GetDPB,
;			CreateProcessDataBlock, GetINDOSFlag, GetInVars,
;			SetDPB, DupPDB, DiskReset
;			StrCmp, StrCpy, Ucase		 -> LOW LEVEL <-
;
; STUB MODULES
;	Net.asm 	**** This will get broken down more???
;   *	Share.asm	Share_Check, Share_Violation
;   *	Lock.asm	$LockOper
;			DOS_LOCK,DOS_UNLOCK,Lock_Check, Lock_Violation

; INTERNAL INTERFACE MODULES
;   *	Lock.asm	DOS_LOCK, DOS_UNLOCK   -->> STUBS <<--
;   *	Dinfo.asm	DISK_INFO
;   *	Finfo.asm	GET_FILE_INFO, SET_FILE_ATTRIBUTE
;   *	Create.asm	DOS_CREATE, DOS_CREATE_NEW,
;			Set_Mknd_Err	       --> Low level routine <--
;   *	Dup.asm 	DOS_DUP
;   *	Open.asm	DOS_OPEN,
;			SetBadPathError,       --> Low level routines <--
;			Check_Access_AX, Share_Error, Set_SFT_Mode
;   *	Close.asm	DOS_CLOSE, DOS_COMMIT, DOS_CLOSE_GOT_SFT,
;			Free_SFT	       --> Low level routine <--
;   *	Abort.asm	DOS_ABORT
;   *	ISearch.asm	DOS_SEARCH_FIRST, DOS_SEARCH_NEXT,
;			RENAME_NEXT	       --> Low level routine <--
;   *	Dircall.asm	DOS_MKDIR, DOS_CHDIR, DOS_RMDIR
;   *	Rename.asm	DOS_RENAME
;   *	Delete.asm	DOS_DELETE,
;			REN_DEL_Check	       --> Low level routine <--
;   *	Disk.asm	DOS_READ, DOS_WRITE

; LOW LEVEL MODULES
;   *	Fat.asm 	UNPACK, PACK, MAPCLUSTER, FATREAD_SFT,
;			FATREAD_CDS, FAT_operation
;   *	Ctrlc.asm	--> STD/IBM versions <--
;			FATAL, FATAL1, reset_environment, DSKSTATCHK,
;			SPOOLINT, STATCHK, CNTCHAND, DIVOV, RealDivOv,
;			CHARHARD, HardErr
;   *	Buf.asm 	SETVISIT, ScanPlace, PLACEBUF, PLACEHEAD, PointComp,
;			GETBUFFR, GETBUFFRB, FlushBuf, BufWrite,
;			SKIPVISIT
;   *	Disk.asm	SWAPBACK, SWAPCON, get_io_sft, DirRead, FATSecRd,
;			DskRead, SETUP, BREAKDOWN, DISKREAD, DISKWRITE,
;			FIRSTCLUSTER, DREAD, DWRITE, DSKWRITE,
;			READ_LOCK_VIOLATION, WRITE_LOCK_VIOLATION,
;			SETSFT, SETCLUS, AddRec
;   *	Mknode.asm	BUILDDIR, SETDOTENT, MakeNode, NEWENTRY, FREEENT,
;			NEWDIR, DOOPEN,RENAME_MAKE
;   *	FCB.asm 	MakeFcb, NameTrans, PATHCHRCMP, GetLet, TESTKANJ,
;			NORMSCAN, CHK, DELIM
;   *	Rom.asm 	GET_random_record, GETRRPOS1, GetRRPos, SKPCLP,
;			FNDCLUS, BUFSEC, BUFRD, BUFWRT, NEXTSEC,
;			OPTIMIZE, FIGREC, GETREC, ALLOCATE, RESTFATBYT,
;			RELEASE, RELBLKS, GETEOF
;   *	Dev.asm 	IOFUNC, DEVIOCALL, SETREAD, SETWRITE, GOTDPB,
;			DEVIOCALL2, DEV_CLOSE_SFT, DEV_OPEN_SFT
;   *	Dir.asm 	SEARCH, SETDIRSRCH, GETPATH, ROOTPATH, StartSrch,
;			MatchAttributes, DEVNAME, Build_device_ent,
;			FindEntry, Srch, NEXTENT, GETENTRY, GETENT,
;			NEXTENTRY, GetPathNoSet, FINDPATH
;

; critical section information for the system calls

;   System Call 		      Who takes care of the reentrancy
;   Abort			   0	(flushbuf) DOS_Close
;   Std_Con_Input		   1	DOS_Read
;   Std_Con_Output		   2	DOS_Write
;   Std_Aux_Input		   3	DOS_Read
;   Std_Aux_Output		   4	DOS_Write
;   Std_Printer_Output		   5	DOS_Write
;   Raw_Con_IO			   6	DOS_Read/DOS_Write
;   Raw_Con_Input		   7	DOS_Read
;   Std_Con_Input_No_Echo	   8	DOS_Read
;   Std_Con_String_Output	   9	DOS_Write
;   Std_Con_String_Input	   A	DOS_Read
;   Std_Con_Input_Status	   B	DOS_Read
;   Std_Con_Input_Flush 	   C	DOS_Read
;   Disk_Reset			   D	(FlushBuf, ScanPlace, SkipVisit)
;   Set_Default_Drive		   E	*none*
;   FCB_Open			   F	DOS_Open
;   FCB_Close			  10	DOS_Close
;   Dir_Search_First		  11	DOS_Search_First
;   Dir_Search_Next		  12	DOS_Search_Next
;   FCB_Delete			  13	DOS_Delete
;   FCB_Seq_Read		  14	DOS_Read/DOS_Write
;   FCB_Seq_Write		  15	DOS_Read/DOS_Write
;   FCB_Create			  16	DOS_Create
;   FCB_Rename			  17	DOS_rename
;   Get_Default_Drive		  19	*none*
;   Set_DMA			  1A	*none*
;   Get_Default_DPB		  1F	*none*
;   FCB_Random_Read		  21	DOS_Read/DOS_Write
;   FCB_Random_Write		  22	DOS_Read/DOS_Write
;   Get_FCB_File_Length 	  23	Get_file_info
;   Get_FCB_Position		  24	*none*
;   Set_Interrupt_Vector	  25	*none*
;   Create_Process_Data_Block	  26	*none*
;   FCB_Random_Read_Block	  27	DOS_Read/DOS_Write
;   FCB_Random_Write_Block	  28	DOS_Read/DOS_Write
;   Parse_File_Descriptor	  29	*none*
;   Get_Date			  2A	DEVIOCALL
;   Set_Date			  2B	DEVIOCALL
;   Get_Time			  2C	DEVIOCALL
;   Set_Time			  2D	DEVIOCALL
;   Set_Verify_On_Write 	  2E	*none*
;   Get_DMA			  2F	*none*
;   Get_Version 		  30	*none*
;   Keep_Process		  31	$abort...
;   Get_DPB			  32	*none*
;   Set_CTRL_C_Trapping 	  33	*none*
;   Get_InDOS_Flag		  34	*none*
;   Get_Interrupt_Vector	  35	*none*
;   Get_Drive_Freespace 	  36	Disk_Info
;   Char_Oper			  37	*none*
;   International		  38	*none*
;   MKDir			  39	DOS_MkDir
;   RMDir			  3A	DOS_RmDir
;   CHDir			  3B	DOS_ChDir
;   Creat			  3C	DOS_Create
;   Open			  3D	DOS_Open
;   Close			  3E	DOS_Close
;   Read			  3F	DOS_Read
;   Write			  40	DOS_Write
;   Unlink			  41	DOS_Delete
;   LSeek			  42	*none*
;   CHMod			  43	Get_file_info, Set_File_Attribute
;   IOCtl			  44	DEVIOCALL
;   XDup			  45	*none*
;   XDup2			  46	*none*
;   Current_Dir 		  47	$Current_Dir
;   Alloc			  48	$Alloc
;   Dealloc			  49	$Dealloc
;   Setblock			  4A	$SetBlock
;   Exec			  4B
;   Exit			  4C	$abort...
;   Wait			  4D	*none*
;   Find_First			  4E	DOS_Search_First
;   Find_Next			  4F	DOS_Search_Next
;   Set_Current_PDB		  50	*none*
;   Get_Current_PDB		  51	*none*
;   Get_In_Vars 		  52	*none*
;   SetDPB			  53	*none*
;   Get_Verify_On_Write 	  54	*none*
;   Dup_PDB			  55
;   Rename			  56	DOS_Rename
;   File_Times			  57	*none*
;   AllocOper			  58	*none*
;   GetExtendedError		  59	*none*
;   CreateTempFile		  5A	DOS_Create_New
;   CreateNewFile		  5B	DOS_Create_New
;   LockOper			  5C
;   ServerCall			  5D
;   UserOper			  5E
;   AssignOper			  5F
