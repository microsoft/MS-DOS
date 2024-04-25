;break <CP/DOS error codes>

;       SCCSID = @(#)error.inc  6.2 86/02/27
;
; CP/DOS calls all return error codes through AX.  If an error occurred then
; the carry bit will be set and the error code is in AX.  If no error occurred
; then the carry bit is reset and AX contains returned info.
;
; Since the set of error codes is being extended as we extend the operating
; system, we have provided a means for applications to ask the system for a
; recommended course of action when they receive an error.
;
; The GetExtendedError system call returns a universal error, an error
; location and a recommended course of action.  The universal error code is
; a symptom of the error REGARDLESS of the context in which GetExtendedError
; is issued.
;

;
; These are the 2.0 error codes
;
no_error                        EQU     0
error_invalid_function          EQU     1
error_file_not_found            EQU     2
error_path_not_found            EQU     3
error_too_many_open_files       EQU     4
error_access_denied             EQU     5
error_invalid_handle            EQU     6
error_arena_trashed             EQU     7
error_not_enough_memory         EQU     8
error_invalid_block             EQU     9
error_bad_environment           EQU     10
error_bad_format                EQU     11
error_invalid_access            EQU     12
error_invalid_data              EQU     13
;**** reserved                  EQU     14      ; *****
error_invalid_drive             EQU     15
error_current_directory         EQU     16
error_not_same_device           EQU     17
error_no_more_files             EQU     18
;
; These are the universal int 24 mappings for the old INT 24 set of errors
;
error_write_protect             EQU     19
error_bad_unit                  EQU     20
error_not_ready                 EQU     21
error_bad_command               EQU     22
error_CRC                       EQU     23
error_bad_length                EQU     24
error_Seek                      EQU     25
error_not_DOS_disk              EQU     26
error_sector_not_found          EQU     27
error_out_of_paper              EQU     28
error_write_fault               EQU     29
error_read_fault                EQU     30
error_gen_failure               EQU     31
;
; These are the new 3.0 error codes reported through INT 24
;
error_sharing_violation         EQU     32
error_lock_violation            EQU     33
error_wrong_disk                EQU     34
error_FCB_unavailable           EQU     35
error_sharing_buffer_exceeded   EQU     36
;
; New OEM network-related errors are 50-79
;
error_not_supported             EQU     50
;
; End of INT 24 reportable errors
;
error_file_exists               EQU     80
error_DUP_FCB                   EQU     81      ; *****
error_cannot_make               EQU     82
error_FAIL_I24                  EQU     83
;
; New 3.0 network related error codes
;
error_out_of_structures         EQU     84
error_Already_assigned          EQU     85
error_invalid_password          EQU     86
error_invalid_parameter         EQU     87
error_NET_write_fault           EQU     88
;
; New error codes for 4.0
;
error_no_proc_slots             EQU     89      ; no process slots available
error_not_frozen                EQU     90
err_tstovfl                     EQU     91      ; timer service table overflow
err_tstdup                      EQU     92      ; timer service table duplicate
error_no_items                  EQU     93      ; There were no items to operate upon
error_interrupt                 EQU     95      ; interrupted system call
error_fixed_vector              EQU     96      ; attempt to set fixed vector
error_vector_used               EQU     97      ; vector set by another process
error_global_limit              EQU     98      ; more than 16 vectors set
error_vector_notset             EQU     99      ; unsetting unallocated vector
error_too_many_semaphores       EQU     100     ; user/sys open sem limit hit
error_sem_already_open          EQU     101     ; attempt to open sem twice
error_sem_is_set                EQU     102     ; non-blk waitsem found it set
error_sem_not_set               EQU     103     ; tried to sig a non-owned sem
error_sem_already_owned         EQU     104     ; tried to wait on owned sem
error_sem_owner_died            EQU     105     ; waitsem found owner died
error_sem_user_limit            EQU     106     ; too many procs have this sem
error_disk_change               EQU     107     ; insert disk b into drive a
error_drive_locked              EQU     108     ; drive locked by another process
error_broken_pipe               EQU     109     ; write on pipe with no reader
;
; New error codes for CP/DOS
;
error_open_failed               EQU     110     ; open/created failed due to
                                                ; explicit fail command
error_buffer_overflow           EQU     111     ; buffer passed to system call
                                                ; is too small to hold return
                                                ; data.
error_disk_full                 EQU     112     ; not enough space on the disk
                                                ; (DOSNEWSIZE/w_NewSize)
error_no_more_search_handles    EQU     113     ; can't allocate another search
                                                ; structure and handle.
                                                ; (DOSFINDFIRST/w_FindFirst)
error_invalid_target_handle     EQU     114     ; Target handle in DOSDUPHANDLE
                                                ; is invalid

error_system_trace              EQU     300     ; system trace error (DosSysTrace)
error_ras_stcp                  EQU     301     ; system trace command processor error
error_ras_createdd              EQU     302     ; error in create dump diskette
error_invalid_procid            EQU     303     ; invalid process id
error_invalid_pdelta            EQU     304     ; invalid priority delta
error_not_descendent            EQU     305     ; not descendent
error_request_notsm             EQU     306     ; requestor not session manager
error_invalid_pclass            EQU     307     ; invalid p class
error_invalid_scope             EQU     308     ; invalid scope
error_invalid_threadid          EQU     309     ; invalid thread id
error_msp_shrink                EQU     310     ; can't shrink - MspSet
error_msp_nomem                 EQU     311     ; no memory - MspAlloc
error_msp_overlap               EQU     312     ; overlap - MspFree
error_msp_badsize               EQU     313     ; bad size parameter - MspAlloc or MspFree
error_msp_badflag               EQU     314     ; bad flag parameter - MspSet
error_msp_badselector           EQU     315     ; invalid MspSegment Selector
error_mr_msg_too_long           EQU     316     ; message too long for buffer
error_mr_mid_not_found          EQU     317     ; message id number not found
error_mr_un_acc_msgf            EQU     318     ; unable to access message file
error_mr_inv_msgf_format        EQU     319     ; invalid message file format
error_mr_inv_ivcount            EQU     320     ; invalid insertion variable count
error_mr_un_perform             EQU     321     ; unable to perform function
error_ts_wakeup                 EQU     322     ; unable to wake up
error_ts_time                   EQU     323     ; time value < 0
error_ts_notimer                EQU     324     ; no times available
error_ts_ticktype               EQU     325     ; tick type not 0 or 1
error_ts_handle                 EQU     326     ; invalid timer handle
error_ts_datetime               EQU     327     ; date or time invalid
error_sys_internal              EQU     328     ; internal system error
error_que_current_name          EQU     329     ; current name does not exist
error_que_proc_not_owned        EQU     330     ; current process does not own queue
error_que_proc_owned            EQU     331     ; current process owns queue
error_que_duplicate             EQU     332     ; duplicate name
error_que_element_not_exist     EQU     333     ; element does not exist
error_que_no_memory             EQU     334     ; inadequate memory
error_que_invalid_name          EQU     335     ; invalid name
error_que_invalid_priority      EQU     336     ; invalid priority parameter
error_que_invalid_handle        EQU     337     ; invalid queue handle
error_que_link_not_found        EQU     338     ; link not found
error_que_memory_error          EQU     339     ; memory error
error_que_prev_at_end           EQU     340     ; previous element was at end of queue
error_que_proc_no_access        EQU     341     ; process does not have access to queues
error_que_empty                 EQU     342     ; queue is empty
error_que_name_not_exist        EQU     343     ; queue name does not exist
error_que_not_initialized       EQU     344     ; queues not initialized
error_que_unable_to_access      EQU     345     ; unable to access queues
error_que_unable_to_add         EQU     346     ; unable to add new queue
error_que_unable_to_init        EQU     347     ; unable to initialize queues
error_vio_register              EQU     348     ; vio register disallowed
error_bvs_parameter             EQU     349     ; invalid parameter supplied
error_scs_call                  EQU     350     ; call issued by other than sm
error_scs_value                 EQU     351     ; value is not for save or restore
error_scs_wait_flag             EQU     352     ; invalid wait flag setting
error_scs_unlock                EQU     353     ; screen not previously locked
error_sm_init                   EQU     354     ; session mgr init failed
error_sm_sgid                   EQU     355     ; invalid screen group id
error_sm_nosg                   EQU     356     ; all screen groups in use
error_kbd_parameter             EQU     357     ; invalid parameter to kbd






;
; error codes for utilities
;

error_invalid_dosver            EQU     1000    ; invalid dos version
error_language_not_supported    EQU     1001    ; language not supported
error_msgfile_bad_format        EQU     1002    ; bad message file format
error_msgfile_bad_mid           EQU     1003    ; message file has bad mid
error_msgfile_outerror          EQU     1004    ; error writing output file
error_msgfile_inperror          EQU     1005    ; error reading input file
error_install_failed            EQU     1006    ; install failed


;
; intercomponent error codes (from 8000H or 32768)
;
error_swapper_not_active        EQU     32768   ; swapper is not active
error_invalid_swapid            EQU     32769   ; invalid swap identifier
error_ioerr_swap_file           EQU     32770   ; i/o error on swap file
error_swap_table_full           EQU     32771   ; swap control table is full
error_swap_file_full            EQU     32772   ; swap file is full
error_cant_init_swapper         EQU     32773   ; cannot initialize swapper
error_swapper_already_init      EQU     32774   ; swapper already initialized
error_pmm_insufficient_memory   EQU     32775   ; insufficient memory
error_pmm_invalid_flags         EQU     32776   ; invalid flags for phys. mem.
error_pmm_invalid_address       EQU     32777   ; invalid address of phys. mem.
error_pmm_lock_failed           EQU     32778   ; lock of storage failed
error_pmm_unlock_failed         EQU     32779   ; unlock of storage failed

;break <Interrupt 24 error codes>

error_I24_write_protect         EQU     0
error_I24_bad_unit              EQU     1
error_I24_not_ready             EQU     2
error_I24_bad_command           EQU     3
error_I24_CRC                   EQU     4
error_I24_bad_length            EQU     5
error_I24_Seek                  EQU     6
error_I24_not_DOS_disk          EQU     7
error_I24_sector_not_found      EQU     8
error_I24_out_of_paper          EQU     9
error_I24_write_fault           EQU     0Ah
error_I24_read_fault            EQU     0Bh
error_I24_gen_failure           EQU     0Ch
error_I24_disk_change           EQU     0Dh
error_I24_wrong_disk            EQU     0Fh
error_I24_Uncertain_media       EQU     10h
error_I24_Char_Call_Interrupted EQU     11h

; THE FOLLOWING ARE MASKS FOR THE AH REGISTER ON Int 24

Allowed_FAIL                    EQU     00001000B
Allowed_RETRY                   EQU     00010000B
Allowed_IGNORE                  EQU     00100000B
;NOTE: ABORT is ALWAYS allowed

I24_operation                   EQU     00000001B       ;Z if READ,NZ if Write
I24_area                        EQU     00000110B       ; 00 if DOS
                                                        ; 01 if FAT
                                                        ; 10 if root DIR
                                                        ; 11 if DATA
I24_class                       EQU     10000000B       ;Z if DISK, NZ if FAT or char

;break <GetExtendedError CLASSes ACTIONs LOCUSs>

; Values for error CLASS

errCLASS_OutRes         EQU     1       ; Out of Resource
errCLASS_TempSit        EQU     2       ; Temporary Situation
errCLASS_Auth           EQU     3       ; Permission problem
errCLASS_Intrn          EQU     4       ; Internal System Error
errCLASS_HrdFail        EQU     5       ; Hardware Failure
errCLASS_SysFail        EQU     6       ; System Failure
errCLASS_Apperr         EQU     7       ; Application Error
errCLASS_NotFnd         EQU     8       ; Not Found
errCLASS_BadFmt         EQU     9       ; Bad Format
errCLASS_Locked         EQU     10      ; Locked
errCLASS_Media          EQU     11      ; Media Failure
errCLASS_Already        EQU     12      ; Collision with Existing Item
errCLASS_Unk            EQU     13      ; Unknown/other

; Values for error ACTION

errACT_Retry            EQU     1       ; Retry
errACT_DlyRet           EQU     2       ; Delay Retry, retry after pause
errACT_User             EQU     3       ; Ask user to regive info
errACT_Abort            EQU     4       ; abort with clean up
errACT_Panic            EQU     5       ; abort immediately
errACT_Ignore           EQU     6       ; ignore
errACT_IntRet           EQU     7       ; Retry after User Intervention

; Values for error LOCUS

errLOC_Unk              EQU     1       ; No appropriate value
errLOC_Disk             EQU     2       ; Random Access Mass Storage
errLOC_Net              EQU     3       ; Network
errLOC_SerDev           EQU     4       ; Serial Device
errLOC_Mem              EQU     5       ; Memory
