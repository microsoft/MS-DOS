.xlist
;
;

; CHKDSK	Version 2.0
; Verifies and repairs MS-DOS disk directory.


;REV 1.1	ARR
;     05/21/82	Added rev number
;REV 1.5	NP ARR
;	Mod by NANCYP to report on extents
;	Mod by AARONR to report volume ID
;REV 2.0	ARR
;	Total rewrite for directories
;REV 2.1	ARR
;	Added ^C and INT 24H handlers
;REV 2.2	ARR
;	INTERNATIONAL support
;REV 2.3	NP
;	Mod by NANCYP to use 2.0 system calls
;	and accept pathnames as parameters
;REV 2.4	NP
;	PRINTF incorporated into CHKDSK
;	Modified to run as .EXE file
;REV 3.0	ARR	8/30/83
;	Update for vers 2.5 of DOS
;	16 bit FATS
;REV 3.05	RS     10/11/84
;	Split into CHKDSK2.ASM for on-machine assembly.
;REV 3.20	RS	9/26/85
;	Allow 0F0H as a valid DOS media descriptor byte - used for non-standard
;	media layouts.
;
;*****************************************************************************
;*									     *
;* Change list to CHKDSK  modules					     *
;*									     *
;* Lines are tagged ANxxx for new, ACxxx for changed			     *
;* --------------------------------------------------------------------------*
;*  000 - DOS 4.00 Spec additions and DCR's thru unit/function test          *
;*	   Date: 8/3/87    Developer: MT                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  001 - DOS 4.00 PTM P265 - Give 'Can't chkdsk subst drive" when running   *
;*	  hardfile. Using 1 based drive insted of 0			     *
;*	  Date: 8/17/87    Developer: Mark T.				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  002 - DOS 4.00 PTM P251 - Hang when chkdsk default drive. Not setting up *
;*	  drive fields correctly on default drive			     *
;*	  Date: 8/14/87    Developer: Mark T.				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;*									     *
;*									     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 005 - DOS 4.00 DCR D166 - Enable 128k FAT				     *
;*	 Date: 8/21/87	   Developer: Bruce B.				     *
;* general modifications are: reserve the rest of the program segment for the*
;*	stack, put the fat-table next after the end of the program seg, then *
;*	put the fatmap area next after the end of the fat-table.	     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 006 - DOS 4.00 ptm p097 - change calculation of total disk space	     *
;*	 Date: 8/28/87	   Developer: Bruce B.				     *
;*	 modules - chkinit.sal, chkdsk2.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 007 - DOS 4.00 ptm p816 - files with length zero			     *
;*	 Date: 8/21/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 008 - DOS 4.00 ptm p872 - incorrect media size reported		     *
;*	 Date: 9/10/87	   Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 009 - DOS 4.00 ptm p1151- incorrect date and time			     *
;*	 Date: 9/10/87	   Developer: Bruce B.				     *
;*	 modules - chkdsk1.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 010 - DOS 4.00 ptm p1158- incorrect disk size when disk is full	     *
;*	 Date: 9/10/87	   Developer: Bruce B.				     *
;*	 modules - chkfat.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 011 - DOS 4.00 ptm p817 - cant check files				     *
;*	 Date: 9/24/87	   Developer: Bruce B.				     *
;*	 modules - chkdsk1.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 012 - DOS 4.00 ptm p1223- month and day reversed			     *
;*	 Date: 9/22/87	   Developer: Bruce B.				     *
;*	 modules - chkdsk1.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 013 - DOS 4.00 ptm p1238- not detect filesize <> number of clusters	     *
;*	 Date: 9/25/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal, chkdisk.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*     - DOS 4.00 ptm p1239- hangs when file has invalid ???		     *
;*	 Date: 9/25/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal, chkdisk.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 014 - DOS 4.00 ptm p1240- not detect crosslinked files		     *
;*	 Date: 9/25/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal, chkfat.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*     - DOS 4.00 ptm p1241- hangs when trying to fix lost subdir	     *
;*	 Date: 9/25/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal, chkfat.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*     - DOS 4.00 ptm p1242- hangs when lost subdir found		     *
;*	 Date: 9/25/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal, chkfat.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 015 - DOS 4.00 ptm p1176 - not working for vdisk drives		     *
;*	 Date: 10/1/87	   Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 016 - DOS 4.00 ptm p1436 - not working for full disk with system files    *
;*	 Date: 10/2/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*     - DOS 4.00 ptm p1437 - not working on vdisk			     *
;*	 Date: 10/2/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*     - DOS 4.00 ptm p1447 - chkdsk filenam --> invalid drive spec	     *
;*	 Date: 10/2/87	   Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 017 - DOS 4.00 ptm p1491 - invalid use of common msgs 		     *
;*	 Date: 10/5/87	   Developer: Bruce B.				     *
;*	 modules - chkdsk.skl chkmsg.inc				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 018 - DOS 4.00 ptm p1507 - 'non_dos' instead of 'non-dos'                 *
;*	 Date: 10/6/87	   Developer: Bruce B.				     *
;*	 modules - chkdsk.skl						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 019 - DOS 4.00 ptm p1506 - '0 bytes would be freed'                       *
;*	 Date: 10/6/87	   Developer: Bruce B.				     *
;*	 modules -							     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 020 - DOS 4.00 ptm p1556 - chkdsk allows 2 positional or keyword parms    *
;*	 Date: 10/8/87	   Developer: Bruce B.				     *
;*	 modules - chkparse.inc 					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 021 - DOS 4.00 ptm p1557 - displays invalid drive spec twice		     *
;*	 Date: 10/8/87	   Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 022 - DOS 4.00 ptm p1558 - divide overflow on invalid drive		     *
;*	 Date: 10/8/87	   Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 023 - DOS 4.00 ptm p1559 - abnormal results when int13 is bad 	     *
;*	 Date: 10/8/87	   Developer: Bruce B.				     *
;*	 modules -							     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 024 - DOS 4.00 ptm p1606 - no display of volume serial number 	     *
;*	 Date: 10/12/87    Developer: Bruce B.				     *
;*	 modules - chkdsk2.sal, chkmsg.inc				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 025 - DOS 4.00 ptm p1761 - doesnt work on zerod out cluster for dir	     *
;*	 Date: 10/17/87    Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 026 - DOS 4.00 ptm p1842 - chkdsk accepts 2 filespec parms		     *
;*	 Date: 10/20/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal, chkparse.inc				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 027 - DOS 4.00 ptm p2007 - test case 7 - chkdsk a: /v  (invalid subdirs)  *
;*	 Date: 10/24/87    Developer: Bruce B.				     *
;*	 modules - chkproc.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 028 - DOS 4.00 ptm p2029 - chkdsk cant exec for afs			     *
;*	 Date: 10/26/87    Developer: Bruce B.				     *
;*	 modules - chkexec.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 029 - DOS 4.00 ptm p2104 - chkdsk goes to drive a: on ctl-break	     *
;*	 Date: 10/29/87    Developer: Bruce B.				     *
;*	 modules - chkfat.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 030 - DOS 4.00 ptm p2323 - low memory check, correct free memory report   *
;*	 Date: 11/04/87    Developer: Bruce B.				     *
;*	 modules - chkfat.sal, chkdsk2.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 031 - DOS 4.00 ptm p2495 - incorrect message for drive not ready	     *
;*	 Date: 11/17/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 032 - DOS 4.00 ptm p2648 - unformatted disk displays "invalid device type" *
;*	 Date: 11/24/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 033 - DOS 4.00 ptm p2781 - divide overflow on unformatted diskette	     *
;*	 Date: 12/07/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 034 - DOS 4.00 ptm p2975 - get psp done three times			     *
;*	 Date: 12/20/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal, chkdsk1.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 035 - DOS 4.00 ptm p3007 - chkdsk reports incorrect memory		     *
;*	 Date: 12/28/87    Developer: Bruce B.				     *
;*	 modules - chkinit.sal, chkdsk1.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 036 - DOS 4.00 ptm p3028 - include pathgen into pgm			     *
;*	 Date: 01/12/88    Developer: Bruce B.				     *
;*	 modules - all							     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 037 - DOS 4.00 ptm p3129 - chkdsk fails to build			     *
;*	 Date: 01/14/88    Developer: Bruce B.				     *
;*	 modules - chkdisp.asm						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 038 - DOS 4.00 ptm p3130 - remove AFS from code			     *
;*	 Date: 01/14/88    Developer: Bruce B.				     *
;*	 modules - chkinit.sal, chkequ.inc, chkexec.sal 		     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 039 - DOS 4.00 ptm p3360 - correct addressing of ctl-break handling	     *
;*	 Date: 02/05/88    Developer: Bruce B.	 			     *
;*	 modules - chkproc2.sal 					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 040 - DOS 4.00 ptm p3573 - pathgen parser and msg ret.		     *
;*	 Date: 02/19/88    Developer: Bruce B				     *
;*	 modules - chkdisp.asm, chkparse.inc				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 041 - DOS 4.00 dcr d490  - change get media id call for same as os/2 1.0   *
;*	 Date: 02/26/88    Developer: Bruce B				     *
;*	 modules - chkdata.inc, chkdsk1.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 042 - DOS 4.00 ptm p3735 - chkdsk prints files to stderr, not stdout	     *
;*	 Date: 03/04/88    Developer: Bruce B				     *
;*	 modules - chkmsg.inc						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 043 - DOS 4.00 ptm p3708 - chkdsk prints wrong message for network drive   *
;*	 Date: 03/07/88    Developer: Bruce B				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 044 - DOS 4.00 ptm p3840 - wrong message for newtork filename 	     *
;*	 Date: 03/14/88    Developer: Bruce B				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 045 - DOS 4.00 ptm p3876 - hang when .. entry erased and /f parameter      *
;*	 Date: 03/15/88    Developer: Bruce B				     *
;*	 modules - chkproc.sal, chkdsk2.sal, chkmsg.inc, chkfat.sal	     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 046 - DOS 4.00 ptm p3923?- display invalid parm names 		     *
;*	 Date: 03/21/88    Developer: Bruce B				     *
;*	 modules - chkinit.sal, chkmsg.inc				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 047 - private build only- display lost cluster number		     *
;*	 Date: 03/24/88    Developer: Bruce B				     *
;*	 modules - chkfat.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 048 - DOS 4.00 PTM p4050 - wont recover . and .. entries		     *
;*	 Date: 04/12/88    Developer: Bruce B				     *
;*	 modules - many 						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 049 - DOS 4.00 PTM p4125 - chkdsk prints incorrect user file bytes	     *
;*	 Date: 04/13/88    Developer: Bruce B.				     *
;*	 modules - many 						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 050 - DOS 4.00 PTM p4571 - chkdsk and mem report diff ram under Windows    *
;*	 Date: 05/02/88    Developer: Bruce B.				     *
;*	 modules - chkdsk1.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 051 - DOS 4.00 PTM p4571 - chkdsk does not recover lost clusters into files*
;*	 Date: 05/05/88    Developer: Bruce B.				     *
;*	 modules - chkfat.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 052 - DOS 4.00 PTM p4869 - handle MS ramdrive.sys			     *
;*	 Date: 05/16/88    Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 053 - DOS 4.00 PTM p4924 - oops! do it right this time....		     *
;*	 Date: 05/19/88    Developer: Bruce B.				     *
;*	 modules - chkinit.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 054 - DOS 4.00 PTM p4957 - both chkdsk & mem do avail mem incorrectly     *
;*	 Date: 05/24/88    Developer: Bruce B.				     *
;*	 modules - chkdsk1.sal						     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 055 - DOS 4.00 PTM p5007 - wont handle '\' as 2nd byte of dbcs pair       *
;*	 Date: 06/01/88    Developer: Bruce B				     *
;*	 modules - chkdsk1.sal, chkinit.sal				     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;*****************************************************************************
;* Note: This is file CHKCHNG.INC for updating purposes 		     *
;*****************************************************************************
