;	SCCSID = @(#)error.asm	1.1 85/04/10
;	SCCSID = @(#)error.asm	1.1 85/04/10
BREAK <Xenix error codes>

;
; XENIX calls all return error codes through AX.  If an error occurred then
; the carry bit will be set and the error code is in AX.  If no error occurred
; then the carry bit is reset and AX contains returned info.
;
; Since the set of error codes is being extended as we extend the operating
; system, we have provided a means for applications to ask the system for a
; recommended course of action when they receive an error.
;
; The GetExtendedError system call returns a universal error, an error
; location and a recommended course of action.	The universal error code is
; a symptom of the error REGARDLESS of the context in which GetExtendedError
; is issued.
;

;
; These are the 2.0 error codes
;
error_invalid_function		EQU	1
error_file_not_found		EQU	2
error_path_not_found		EQU	3
error_too_many_open_files	EQU	4
error_access_denied		EQU	5
error_invalid_handle		EQU	6
error_arena_trashed		EQU	7
error_not_enough_memory 	EQU	8
error_invalid_block		EQU	9
error_bad_environment		EQU	10
error_bad_format		EQU	11
error_invalid_access		EQU	12
error_invalid_data		EQU	13
;**** reserved			EQU	14	; *****
error_invalid_drive		EQU	15
error_current_directory 	EQU	16
error_not_same_device		EQU	17
error_no_more_files		EQU	18
;
; These are the universal int 24 mappings for the old INT 24 set of errors
;
error_write_protect		EQU	19
error_bad_unit			EQU	20
error_not_ready 		EQU	21
error_bad_command		EQU	22
error_CRC			EQU	23
error_bad_length		EQU	24
error_Seek			EQU	25
error_not_DOS_disk		EQU	26
error_sector_not_found		EQU	27
error_out_of_paper		EQU	28
error_write_fault		EQU	29
error_read_fault		EQU	30
error_gen_failure		EQU	31
;
; These are the new 3.0 error codes reported through INT 24
;
error_sharing_violation 	EQU	32
error_lock_violation		EQU	33
error_wrong_disk		EQU	34
error_FCB_unavailable		EQU	35
error_sharing_buffer_exceeded	EQU	36
error_Code_Page_Mismatched	EQU	37    ; DOS 4.00 			;AN000;
error_handle_EOF		EQU	38    ; DOS 4.00 			;AN000;
error_handle_Disk_Full		EQU	39    ; DOS 4.00 			;AN000;
;
; New OEM network-related errors are 50-79
;
error_not_supported		EQU	50
;
; End of INT 24 reportable errors
;
error_file_exists		EQU	80
error_DUP_FCB			EQU	81	; *****
error_cannot_make		EQU	82
error_FAIL_I24			EQU	83
;
; New 3.0 network related error codes
;
error_out_of_structures 	EQU	84
error_Already_assigned		EQU	85
error_invalid_password		EQU	86
error_invalid_parameter 	EQU	87
error_NET_write_fault		EQU	88
error_sys_comp_not_loaded	EQU	90    ; DOS 4.00				;AN000;

BREAK <Interrupt 24 error codes>

error_I24_write_protect 	EQU	0
error_I24_bad_unit		EQU	1
error_I24_not_ready		EQU	2
error_I24_bad_command		EQU	3
error_I24_CRC			EQU	4
error_I24_bad_length		EQU	5
error_I24_Seek			EQU	6
error_I24_not_DOS_disk		EQU	7
error_I24_sector_not_found	EQU	8
error_I24_out_of_paper		EQU	9
error_I24_write_fault		EQU	0Ah
error_I24_read_fault		EQU	0Bh
error_I24_gen_failure		EQU	0Ch
; NOTE: Code 0DH is used by MT-DOS.
error_I24_wrong_disk		EQU	0Fh

; THE FOLLOWING ARE MASKS FOR THE AH REGISTER ON Int 24

Allowed_FAIL			EQU	00001000B
Allowed_RETRY			EQU	00010000B
Allowed_IGNORE			EQU	00100000B
;NOTE: ABORT is ALWAYS allowed

I24_operation			EQU	00000001B	;Z if READ,NZ if Write
I24_area			EQU	00000110B	; 00 if DOS
							; 01 if FAT
							; 10 if root DIR
							; 11 if DATA
I24_class			EQU	10000000B	;Z if DISK, NZ if FAT or char

BREAK <GetExtendedError CLASSes ACTIONs LOCUSs>

; Values for error CLASS

errCLASS_OutRes 	EQU	1	; Out of Resource
errCLASS_TempSit	EQU	2	; Temporary Situation
errCLASS_Auth		EQU	3	; Permission problem
errCLASS_Intrn		EQU	4	; Internal System Error
errCLASS_HrdFail	EQU	5	; Hardware Failure
errCLASS_SysFail	EQU	6	; System Failure
errCLASS_Apperr 	EQU	7	; Application Error
errCLASS_NotFnd 	EQU	8	; Not Found
errCLASS_BadFmt 	EQU	9	; Bad Format
errCLASS_Locked 	EQU	10	; Locked
errCLASS_Media		EQU	11	; Media Failure
errCLASS_Already	EQU	12	; Collision with Existing Item
errCLASS_Unk		EQU	13	; Unknown/other

; Values for error ACTION

errACT_Retry		EQU	1	; Retry
errACT_DlyRet		EQU	2	; Delay Retry, retry after pause
errACT_User		EQU	3	; Ask user to regive info
errACT_Abort		EQU	4	; abort with clean up
errACT_Panic		EQU	5	; abort immediately
errACT_Ignore		EQU	6	; ignore
errACT_IntRet		EQU	7	; Retry after User Intervention

; Values for error LOCUS

errLOC_Unk		EQU	1	; No appropriate value
errLOC_Disk		EQU	2	; Random Access Mass Storage
errLOC_Net		EQU	3	; Network
errLOC_SerDev		EQU	4	; Serial Device
errLOC_Mem		EQU	5	; Memory
