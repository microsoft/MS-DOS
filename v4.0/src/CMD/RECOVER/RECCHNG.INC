.xlist
;
;
;REV 1.0
;	
;REV 1.5
;	Added header message ARR
;REV	EKE  9/8/83
;	added code for 2.X, it now quits if trying to recover over a net
;REV	EKE  10/13/83
;	Fixed current directory saving.
;REV	NP   10/17/83
;	Use printf for messages.
;	And now it's an .EXE file.
;REV 2.0
;	MZ  11/1/83
;	Commented the source
;	Used symbols from DOSSYM
;	Fixed for 16-bit fats.
;
;*****************************************************************************
;*									     *
;* Change list to RECOVER modules					     *
;*									     *
;* Lines are tagged ANxxx for new, ACxxx for changed			     *
;* --------------------------------------------------------------------------*
;*  000 - DOS 4.00 Spec additions and DCR's thru unit/function test           *
;*	   Date: 8/3/87    
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  001 - DOS 4.00 PTM P265 - Give 'Can't chkdsk subst drive" when running    *
;*	  hardfile. Using 1 based drive insted of 0			     *
;*	  Date: 8/17/87    
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  002 - DOS 4.00 PTM P251 - Hang when chkdsk default drive. Not setting up  *
;*	  drive fields correctly on default drive			     *
;*	  Date: 8/14/87    
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;*									     *
;*									     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 005 - DOS 4.00 DCR D166 - Enable 128k FAT				     *
;*	 Date: 8/21/87	   
;* procedures changed - calc_fat_addr, readft, wrtft, getfat, setfat, fillfat*
;*	read_disk, read_once, write_disk, write_once, read_file, drive_spec  *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 006 - DOS 4.00 ptm p??? - msg when disk full				     *
;*	 Date: 8/21/87	   
;* procedures changed - main_loop1					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 007 - DOS 4.00 ptm p1682- redirection to file not working		     *
;*	 Date: 10/14/87    
;* procedures changed - recmsg.inc					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 008 - DOS 4.00 ptm p1845- changes current drive			     *
;*	 Date: 10/20/87    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 009 - DOS 4.00 ptm p1850- a:recover c: --> 'insert diskette for drive b'   *
;*	 Date: 10/21/87    
;* procedures changed - recinit.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 010 - DOS 4.00 ptm p1934- no msg displayed for 'recover a:'                *
;*	 Date: 10/22/87    
;* procedures changed - recover.sal, recproc.sal			     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 011 - DOS 4.00 ptm p2020- recover doesnt exec 			     *
;*	 Date: 10/25/87    
;* procedures changed - recexec.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 012 - DOS 4.00 ptm p2224 & p2230 - dbcs handling			     *
;*	 Date: 11/02/87    
;* procedures changed - recover.sal, recdbcs.sal			     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 013 - DOS 4.00 ptm p2264  -  no low memory error checking		     *
;*	 Date: 11/04/87    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 014 - DOS 4.00 ptm p2650  -  doesnt handle c:\file.nam		     *
;*	 Date: 11/24/87    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 015 - DOS 4.00 ptm p2702,2730  -  doesnt report not writing to fat	     *
;*	 Date: 11/30/87    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 016 - DOS 4.00 ptm p2868 - recover files gone 			     *
;*	 Date: 12/10/87    
;* procedures changed - none - recproc.sal was not exported on 10-22-87      *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 017 - DOS 4.00 ptm p3013 - ADD CHECK for carry after name translate	     *
;*	 Date: 12/29/87    
;* procedures changed - recinit.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 018 - DOS 4.00 ptm p2991 - problem with space after drive letter	     *
;*	 Date: 12/29/87    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 019 - DOS 4.00 ptm p3029 - doesn't handle subdirs                          *
;*	 Date:	1/05/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 020 - DOS 4.00 ptm p3042 -						     *
;*	 Date:	1/06/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 021 - DOS 4.00 ptm p3138 - file not found if a:\filename		     *
;*	 Date:	1/22/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 022 - DOS 4.00 ptm p3130 - remove AFS 				     *
;*	 Date:	1/25/88    
;* procedures changed - recexec.sal, recover.mak, recover.arf, recover.skl   *
;*		      - recmsg.inc, recequ.inc, recdata.inc, recinit.sal     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 023 - DOS 4.00 ptm p3136 - cannot write fat on hard file		     *
;*	 Date:	1/25/88    
;* procedures changed - recproc.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 024 - DOS 4.00 ptm p3160 - cannot handle '\' as dbcs second  byte          *
;*	 Date:	1/25/88    
;* procedures changed - recover.sal, recdata.inc			     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 025 - DOS 4.00 ptm p3280 - include basesw for parser			     *
;*	 Date:	1/29/88    
;* procedures changed - recparse.inc					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 026 - DOS 4.00 ptm p3360 - handle control-break			     *
;*	 Date:	2/04/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 027 - DOS 4.00 ptm p3471 - recover drive on >32M			     *
;*	 Date:	2/17/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 028 - DOS 4.00 ptm p3573 - make changes for pathgen of parser and msg ret  *
;*	 Date:	2/19/88    
;* procedures changed - recparse.inc, recdisp.asm			     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 029 - DOS 4.00 ptm p3631 - correct changes made for pathgen of msg ret     *
;*	 Date:	2/26/88    
;* procedures changed - recdisp.asm					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 030 - DOS 4.00 dcr d490  - make get/set media id same as os/2 1.0	     *
;*	 Date:	2/26/88    
;* procedures changed - recinit.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 031 - DOS 4.00 PTM P3923 - DISPLAY INVALID PARMS			     *
;*	 Date:	3/23/88    
;* procedures changed - recinit.sal, recmsg.inc 			     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;* 032 - DOS 4.00 PTM P4387 - remove sf_extclus from source		     *
;*	 Date:	4/18/88    
;* procedures changed - recover.sal					     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									     *
;*****************************************************************************
;* Note: This is file CHKCHNG.INC for updating purposes 		     *
;*****************************************************************************
