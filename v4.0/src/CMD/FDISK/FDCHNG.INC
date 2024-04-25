.xlist
;
;
;*****************************************************************************
;*                                                                           *
;* Change list to FDISK modules                                              *
;*                                                                           *
;* Lines are tagged ANxxx for new, ACxxx for changed                         *
;* --------------------------------------------------------------------------*
;*  000 - DOS 4.0 Spec additions and DCR's thru unit/function test           *
;*         Date: 12/31/87  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  001 - DOS 4.0 DCR D468 Add errorlevel 1 on exit if there is no PRIMARY   *
;*         partition and the /Q switch is specified.  This was done for      *
;*         SELECT.                                                           *
;*         Date: 02/06/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  002 - DOS 4.0 PTM P3383 Add logic to use undocumented int 21 to check    *
;*         media to see if it has been formatted or not. CHECK_FORMAT added. *
;*         Date: 02/08/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  003 - DOS 4.0 PTM P3589 Change CONVERT.C to compare for a period in the  *
;*         get_volume_string routine.  It does a find first on the logical   *
;*         drive for the volume name and must copy it without the period.    *
;*         Date: 02/22/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  004 - DOS 4.0 PTM P3744 Change FDISK logic to display and handle a hard  *
;*         file of up to 4,000 MB.                                           *
;*         Date: 03/04/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  005 - DOS 4.0 PTM P3618 Add errorlevel 2 on exit if there is no changes  *
;*         made and the /Q switch is specified.  This was done for           *
;*         SELECT.                                                           *
;*         Date: 02/25/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  006 - DOS 4.0 PTM P3617 Change FDISK to color screens.  This is done for *
;*         SELECT.                                                           *
;*         Date: 02/25/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  007 - DOS 4.0 DCR D490  Change FDISK IOCTL 63 to 66 in FDISK.H.          *
;*         Date: 02/26/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  008 - DOS 4.0 PTM P3698 Logic change for PTM 3618 was bad and had to     *
;*         to be corrected.                                                  *
;*         Also changed FDISK IOCTL 64 to 67 in FDISK.H.                     *
;*         Date: 02/26/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  009 - DOS 4.0 PTM P3938 A variable (temp) in subroutine                  *
;*         write_info_to_disk was not initialized on entry.                  *
;*         Date: 03/22/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  010 - DOS 4.0 PTM P4071 Changed the parsar logic to output the correct   *
;*         error message when parse is not correct.                          *
;*         Date: 03/30/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  011 - DOS 4.0 PTM P4837 When deleting and allocating FDISK logical drives*
;*         FDISK was deleting the wrong drives.                              *
;*         Date: 05/12/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  012 - DOS 4.0 PTM P4835 FDISK had Y and N hard coded for YES and NO.     *
;*         Need to pick up 'Y' and 'N' translations from message file.       *
;*         Date: 05/12/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  013 - DOS 4.0 PTM P4883 FDISK will allow the deletion of a logical       *
;*         drive that has already been deleted.  This error was caused by    *
;*         the logic change of P4837.                                        *
;*         Date: 05/17/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  014 - DOS 4.0 PTM P4953 FDISK displays too many files open error message *
;*         when Cannot FDISK with Network Loaded message should be displayed.*
;*         Date: 05/23/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  015 - DOS 4.0 PTM P5019 FDISK displays Insufficient memory error message *
;*         when Invalid Parameter should be displayed.                       *
;*         Logic has also been added to only get the volume ID of a logical  *
;*         drive by doing a Int 21 11h instead of IOCTL call 0866h.          *
;*         Date: 06/02/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*  016 - DOS 4.0 PTM P5031 FDISK displays the wrong error message with 4    *
;*         partitions allocated on same disk and trying to delete primary    *
;*         partition.                                                        *
;*         Date: 06/06/88  Developer: Dennis M                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*****************************************************************************
;* Note: This is file FDCHNG.INC for updating purposes                       *
;*****************************************************************************
.list

