.xlist
;
;
;*****************************************************************************
;*                                                                           *
;* Change list to FORMAT modules                                             *
;*                                                                           *
;* Lines are tagged ANxxx for new, ACxxx for changed                         *
;* --------------------------------------------------------------------------*
;*  000 - DOS 4.00 Spec additions and DCR's thru unit/function test           *
;*         Date: 8/3/87    Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  001 - DOS 4.00 DCR D146 Add support for /F switch                         *
;*         Date: 8/13/87   Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  002 - DOS 4.00 DCR D166 Add logic to detect that switches entered         *
;*         multiple times, and print error message                           *
;*         Date: 8/13/87   Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  003 - DOS 4.00 PTM P233 Do not allow Cntrl-Break when writing file       *
;*        system out, only during the actual format                          *
;*        Date: 8/14/87    Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  004 - DOS 4.00 PTM P229 Volume serial number displayed in reverse word    *
;*        order from command.com and diskcopy. Reverse order of words        *
;*        Date: 8/17/87    Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  005 - DOS 4.00 DCR D64  Enable for 128k FAT                               *
;*        Date: 8/19/87    Developer: DMS	                             *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  006 - DOS 4.00 PTM P320 Not detecting write protect. Needed to use        *
;*        extended error messages                                            *
;*        Date 8/20/87     Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  007 - DOS 4.00 PTM P170 Straighten out the switch check logic to allow    *
;*        /B with all diskette formats, add /B/S check, and remove /V/B      *
;*        check except for /8 sectored diskettes (old dir and boot record    *
;*        Date 8/21/87     Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  008 - DOS 4.00 PTM P402 Fields that determine switch type not cleared,    *
;*        so switches got checked multiple times, causing error              *
;*        Date 8/23/87     Developer: MT        , DS                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  009 - DOS 4.00 PTM P341 Check to make sure /N entered with /T             *
;*        Date 8/23/87     Developer: MT                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  010 - DOS 4.00 PTM P233 Capture the CTRL-BREAK interrupt and disable      *
;*        it during the writing of the FAT, DIR, and SYSTEM.                 *
;*        Date 8/25/87     Developer: DMS                                    *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  012 - DOS 4.00 DCR 200 If the NumberOfFATs field of the BPB is 0 we need  *
;*        to calculate various values in the BPB to be used by FORMAT.       *
;*        Date 9/10/87    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  013 - DOS 4.00 DCR 208 Set FORMAT in order that the space available it    *
;*        reports is consistent with DIR.                                    *
;*        Date 9/11/87    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  014 - DOS 4.00 PTM 1535 Allow access to a non-formatted disk.             *
;*        Date 10/15/87   Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  015 - DOS 4.00 DCR 390  Multi-Track format of hard media                  *
;*        Date 12/9/87    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  016 - DOS 4.00 DCR 395  SELECT message support.  Use INT 2Fh, function    *
;*        ADC1h to print FORMAT disk prompt from SELECT.                     *
;*        Date 12/14/87   Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  017 - DOS 4.00 PTM 3125 SELECT message support. Disable write protect     *
;*        message under SELECT option.  Addition of exit codes 6 (Drive Not  *
;*        Ready" and 7 (Write Protect).                                      *
;*        Date 1/14/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  018 - DOS 4.00 PTM 3130 Provide for conditional assembly of the /FS:      *
;*        code, since it is not being shipped with DOS 4.00.                  *
;*        Date 1/26/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  019 - DOS 4.00 PTM 3994 FORMAT now has a "heartbeat" when it verifies     *
;*        bad sectors.  By doing so the user knows the FORMAT is still       *
;*        proceeding well.  Without this heartbeat, an AT appears to hang    *
;*        when the sectors are being verified.  This is caused by the slow   *
;*        head resets on an AT.                                              *
;*        Date 3/25/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  020 - DOS 4.00 PTM 4058 When an invalid Volume ID is entered at the       *
;*        volume prompt, FORMAT should go to the next line so that the       *
;*        user can see the invalid volume id.                                *
;*        Date 3/29/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  021 - DOS 4.00 PTM 4081 FORMAT was marking the incorrect cluster as       *
;*        bad under certain situations.  This caused that sector to fail     *
;*        when read or written to.                                           *
;*        Date 3/31/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  022 - DOS 4.00 PTM 4180 FORMAT was not performing an FCB Close after      *
;*        it had done an FCB Create.  This caused the change line counter    *
;*        to go "haywire".  Also a bug was found in the FORMAT retry logic.  *
;*        FORMAT was never entering the retry logic because of a CY flag     *
;*        always existing on entry to the routine.                           *
;*        Date 4/15/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  023 - DOS 4.00 DCR 524 FORMAT must accept a blank or carriage return to   *
;*        allow for a blank volume label.                                    *
;*        Date 4/19/88    Developer: DRM                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  024 - DOS 4.00 PTM 4487 FORMAT trys to get the A: drive when formatting   *
;*        drive B: and then hitting enter for the volume label.  There is a  *
;*        problem with FCB Close but logic was also changed in FORLABEL.SAL  *
;*        to eliminate this condition.                                       *
;*        Date 4/26/88    Developer: DRM                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  025 - DOS 4.00 PTM 4539 FORMAT accesses the default disk instead of the   *
;*        boot disk when the default disk is different than the boot disk.   *
;*        This is incorrect behavior because the user could receive a system *
;*        other than what they wanted.                                       *
;*        Date 4/28/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  026 - DOS 4.00 PTM 4805 FORMAT A: /B gives invalid bad byte count and     *
;*        FORMAT A: /F:160 on an 1.2 Mb drive gives parm error.              *
;*        Date 5/10/88    Developer: DMS                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  027 - DOS 4.00 PTM 4913 FORMAT A: /B displays the serial number of the    *
;*        diskette but never writes it to the diskette.  Format will no      *
;*        display the serial number when formatting with /8.                 *
;*        Date 5/19/88    Developer: DRM                                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  028 - DOS 4.00 PTM 5023 FORMAT puts just the N of NO NAME in the volume   *
;*        label of the boot record.  This is corrected in IBMFOR.SAL by      *
;*        setting up the CX register correctly.                              *
;*        Date 6/09/88    Developer: DRM                                     *
;*****************************************************************************
;* Note: This is file FORCHNG.INC for updating purposes                      *
;*****************************************************************************
.list

