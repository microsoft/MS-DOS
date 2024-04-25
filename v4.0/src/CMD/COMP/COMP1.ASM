	page	,132			;
	title	COMP.SAL - COMPARE A PAIR OF FILES
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: COMP1.ASM
;
; DESCRIPTIVE NAME: Compare two files to show they are identical or not.
;
; FUNCTION:  The paths and names of each pair of files is
;	 displayed as the comparing process proceeds.  An
;	 error message will follow the names if:
;	     (1) a file matching the second filename can't be found,
;	     (2) the files are different sizes, or
;	     (3) either path is invalid.
;
;	 During the comparison, an error message will appear for any
;	 location that contains mismatching information in the 2
;	 files.  The message indicates the offset into the files of
;	 the mismatching bytes, and the contents of the 2 bytes
;	 themselves (all in hex).  This will occur for up to 10
;	 mismatching bytes - if more than 10 compare errors are
;	 found, the program assumes that further comparison would be
;	 useless, and ends its compare of the 2 files at that point.
;
;	 If all bytes in the 2 files match, a "Files compare OK"
;	 message will appear.
;
;	 In all cases, after the comparing of 2 files ends, comparing
;	 will proceed with the next pair of files that match the 2
;	 filenames, until no more files can be found that match the
;	 first filename.  You are then asked if you want to compare
;	 any more files.  Replying "N" returns you to the DOS prompt
;	 (such as A>); a reply of "Y" results in prompts for new
;	 primary and secondary filenames.
;
;	 In all compares, COMP looks at the last byte of one of the
;	 files being compared to assure that it contains a valid
;	 end-of-file mark (CTRL-Z, which is the hex character 1A).
;	 If found, no action is taken by COMP.	If the end-of-file
;	 mark is NOT found, COMP produces the message "EOF mark not
;	 found".  This is done because some products produce files
;	 whose sizes are always recorded in the directory as a
;	 multiple of 128 bytes, even though the actual usable data in
;	 the file will usually be a few bytes less than the directory
;	 size.	In this case, COMP may produce "Compare error"
;	 messages when comparing the few bytes beyond the last real
;	 data byte in the last block of 128 bytes (COMP always
;	 compares the number of bytes reflected in the directory).
;	 Thus, the "EOF mark not found" message indicates that the
;	 compare errors may not have occurred in the usable data
;	 portion of the file.
;
;	 Multiple compare operations may be performed with one load
;	 of COMP.  A prompt, "Compare more files (Y/N)?" permits additional
;	 executions.
;
; ENTRY POINT: "START" at ORG 100h, jumps to "INIT".
;
; INPUT: (DOS command line parameters)
;	[d:][path] COMP [d:][path][filenam1[.ext]] [d:][path][filenam2[.ext]]
;
;	 Where
;	 [d:][path] before COMP to specify the drive and path that
;		    contains the COMP command file.
;
;	 [d:][path][filenam1[.ext]] -  to specify the FIRST (or primary)
;		    file or group of files to be compared
;
;	 [d:][path][filenam2[.ext]]  - to specify the SECOND file or group
;		    of files to be compared with the corresponding file
;		    from the FIRST group
;
;	 Global filename characters are allowed in both filenames,
;	 and will cause all of the files matching the first filename
;	 to be compared with the corresponding files from the second
;	 filename.  Thus, entering COMP A:*.ASM B:*.BAK will cause
;	 each file from drive A:  that has an extension of .ASM to be
;	 compared with a file of the same name (but with an extension
;	 of .BAK) from drive B:.
;
;	 If you enter only a drive specification, COMP will assume
;	 all files in the current directory of the specified drive.
;	 If you enter a path without a filename, COMP assumes all
;	 files in the specified directory.  Thus, COMP A:\LEVEL1
;	 B:\LEVEL2 will compare all files in directory A:\LEVEL1 with
;	 the files of the same names in directory B:\LEVEL2.
;
;	 If no parameters are entered with the COMP command, you will
;	 be prompted for both.	If the second parm is omitted, COMP
;	 will prompt for it.  If you simply press ENTER when prompted
;	 for the second filename, COMP assumes *.* (all files
;	 matching the primary filename), and will use the current
;	 directory of the default drive.
;
;	 If no file matches the primary filename, COMP will prompt
;	 again for both parameters.
;
; EXIT-NORMAL: Errorlevel = 0, Function completed successfully.
;
; EXIT-ERROR: Errorlevel = 1, Abnormal termination due to error, wrong DOS,
;	      invalid parameters, unrecoverable I/O errors on the diskette.
;
; EFFECTS: Files are not altered.  A Message will show result of compare.
;
; INTERNAL REFERENCES:
;    ROUTINES: none
;
;    DATA AREAS:
;	PSP - Contains the DOS command line parameters.
;	WORKAREA - Temporary storage
;
; EXTERNAL REFERENCES:
;    ROUTINES:
;	SYSDISPMSG - Uses the MSG parm lists to construct the messages
;		 on STDOUT.
;	SYSLOADMSG - Loads messages, makes them accessable.
;	SYSPARSE - Processes the DOS Command line, finds parms.
;
;    DATA AREAS:
;	 COMPSM.SAL - Defines the control blocks that describe the messages
;	 COMPPAR.SAL - Defines the control blocks that describe the
;		DOS Command line parameters.
;
; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT COMP1,NUL
;
;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.
;
;	 Sample LINK command:
;
;		LINK @COMP.ARF
;
;	 Where the COMP.ARF is defined as:
;
;	 COMP1+
;	 COMPPAR+
;	 COMPP+
;	 COMPSM+
;	 COMP2
;
;	 These modules must be linked in this order.  The load module is
;	 a COM file, to be converted to COM with EXE2BIN.
;
; REVISION HISTORY:
;	     AN000 Version 4.00: add PARSER, System Message Handler,
;		  Add compare of code page extended attribute, if present.
;
; COPYRIGHT: The following notice is found in the OBJ code generated from
;	     the "COMPSM.SAL" module:
;
;	     "The DOS COMP Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft"
;
;PROGRAM AUTHOR: Original written by: Dave L.
;		 3.30 modifications by Russ W.
;		 4.0  modifications by: Edwin M. K.
;		 4.0  modifications by: Bill L.
;****************** END OF SPECIFICATIONS *****************************
	PAGE
;	    $SALUT (4,13,18,36)
	    IF1
		%OUT COMPONENT=COMP, MODULE=COMP1.ASM
	    ENDIF

CSEG	    segment PARA public  'CODE' ;AN000;
	    assume cs:CSEG,ds:CSEG,es:CSEG,ss:CSEG ;AS SET BY DOS LOADER
PSP_HEADER  EQU  $		   ;START OF PROGRAM SEGMENT PREFIX AREA
	    org  02h
MEMORY_SIZE LABEL WORD
	    PUBLIC MEMORY_SIZE

	    org  5Ch
FCB	    LABEL BYTE
	    PUBLIC FCB

	    org  80h
PARM_AREA   LABEL BYTE
	    PUBLIC PARM_AREA

	    org  100h
	    EXTRN INIT:NEAR	   ;"INIT" IS IN COMP2.SAL
START:	    jmp  INIT		   ;DEFINE THE DOS ENTRY POINT

CSEG	    ENDS
	    END  START
