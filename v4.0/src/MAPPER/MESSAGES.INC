	page

; Restore Messages 0

MSG0			    equ  0
INSERT_SOURCE_DISK	    equ  1635	       ;925
SOURCE_TARGET_SAME	    equ  1642	       ;932
INVALID_NUM_PARM	    equ  1643	       ;933
INVALID_DRIVE		    equ  1644	       ;934
NO_FILE_TO_RESTORE	    equ  1645	       ;935
INVALID_PARM		    equ  1646	       ;936
LAST_FILE_NOT_RESTORED	    equ  1648	       ;938
SOURCE_NO_BACKUP_FILE	    equ  1649	       ;939
INSUFFICIENT_MEMORY	    equ  8	       ;8
FILE_SEQUENCE_ERROR	    equ  1651	       ;941
FILE_CREATION_ERROR	    equ  1652	       ;942
TARGET_IS_FULL		    equ  1653	       ;943
NOT_ABLE_TO_RESTORE_FILE    equ  1655	       ;945
INVALID_DOS_VER 	    equ  1210	       ;500
FILE_SHARING_ERROR	    equ  1647	       ;937
FILE_WAS_CHANGED	    equ  1638	       ;928
DISK_OUT_OF_SEQUENCE	    equ  1636	       ;926
FILE_IS_READONLY	    equ  1637	       ;927
SYSTEM_FILE_RESTORED	    equ  1639	       ;929
FILES_WERE_BACKUP_ON	    equ  1640	       ;930
RESTORE_FILE_FROM_DRIVE     equ  1634	       ;924
INSERT_TARGET_DISK	    equ  1657	       ;947
FILE_TO_BE_RESTORED	    equ  1641	       ;931
DISKETTE_NUM		    equ  1656	       ;946
INVALID_PATH		    equ  1670	       ;960

		db	' The Microsoft  MS DOS (R) Restore Utility'
		db	' Version 4.00 Copyright 1988 Microsoft  '
		db	' Licensed Material - Property of Microsoft  '
		db	' Author - ** **** '


 msg %MSG0,<"Y N A R I",0dh,0ah>
 Msg %SOURCE_TARGET_SAME,<0dh,0ah,"Source and target drives are the same",0dh,0ah>
 Msg %INVALID_NUM_PARM,<0dh,0ah,"Invalid number of parameters",0dh,0ah>
 Msg %INVALID_PATH,<0dh,0ah,"Invalid path",0dh,0ah>
 Msg %INVALID_DRIVE,<0dh,0ah,"Invalid drive specification",0dh,0ah>
 Msg %NO_FILE_TO_RESTORE,<0dh,0ah,"Warning! No files were found to restore",0dh,0ah>
 msg %INVALID_PARM,<0dh,0ah,"Invalid parameter %s",0dh,0ah>
 Msgstart %INSERT_SOURCE_DISK,<0dh,0ah,"Insert backup diskette %s in drive">
 MsgContinue		 <" %c:",0dh,0ah>
 MsgContinue		 <"Strike any key when ready ",0dh,0ah>
 MsgEnd

 MsgStart %DISK_OUT_OF_SEQUENCE,<0dh,0ah,"Warning! Diskette is out of sequence",0dh,0ah>
 MsgContinue			<"Replace diskette or continue if okay",0dh,0ah>
 MsgContinue			<"Strike any key when ready ",0dh,0ah>
 MsgEnd

 Msg %LAST_FILE_NOT_RESTORED,<0dh,0ah,"The last file was not restored",0dh,0ah>
 Msg %FILES_WERE_BACKUP_ON,<0dh,0ah,"*** Files were backed up %s *** ",0dh,0ah>
 Msg %SOURCE_NO_BACKUP_FILE,<0dh,0ah,"Source does not contain backup files",0dh,0ah>
 Msg %INSUFFICIENT_MEMORY,<0dh,0ah,"Insufficient memory",0dh,0ah>
 MsgStart %FILE_IS_READONLY,<0dh,0ah,"Warning! File %s",0dh,0ah>
 MsgContinue		    <"is a read-only file",0dh,0ah>
 MsgContinue		    <"Replace the file (Y/N)? ",0dh,0ah>
 MsgEnd

 Msg %FILE_SEQUENCE_ERROR,<0dh,0ah,"Restore file sequence error",0dh,0ah>
 Msg %FILE_CREATION_ERROR,<0dh,0ah,"File creation error",0dh,0ah>
 Msg %TARGET_IS_FULL,<0dh,0ah,"Target is full",0dh,0ah>
 Msg %NOT_ABLE_TO_RESTORE_FILE,<0dh,0ah,"*** Not able to restore file ***",0dh,0ah>
 MsgStart %INSERT_TARGET_DISK,<0dh,0ah,"Insert restore target in " >
 MsgContinue		 <"drive %s:",0dh,0ah>
 MsgContinue		 <"Strike any key when ready ",0dh,0ah>
 MsgEnd
 msg %INVALID_DOS_VER,<0dh,0ah,"Incorrect DOS version",0dh,0ah>
 msg %FILE_TO_BE_RESTORED,<0dh,0ah,"%s",0>

 msg %RESTORE_FILE_FROM_DRIVE,<0dh,0ah,"*** Restoring files from drive %s: ***",0>

 Msg %FILE_SHARING_ERROR,<0dh,0ah,"Unrecoverable file sharing error",0dh,0ah>

 MsgStart %SYSTEM_FILE_RESTORED,<0dh,0ah,"System files restored",0dh,0ah>
 MsgContinue			<"Target disk may not be bootable",0dh,0ah>
 MsgEnd

 MsgStart %FILE_WAS_CHANGED,<0dh,0ah,"Warning! File %s",0dh,0ah>
 MsgContinue		    <"was changed after it was backed up",0dh,0ah>
 MsgContinue		    <"Replace the file (Y/N)? ",0dh,0ah>
 MsgEnd
 msg %DISKETTE_NUM,<0dh,0ah,"Diskette: %s",0>

