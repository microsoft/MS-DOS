;	SCCSID = @(#)exe.asm	1.1 85/04/10
;	SCCSID = @(#)exe.asm	1.1 85/04/10
BREAK <EXEC and EXE file structures>
;
; EXEC arg block - load/go program
;

;
; The following get used as arguments to the EXEC system call.	They indicate
; whether or not the program is executed or whether or not a program header
; gets created.
;
exec_func_no_execute	EQU 1		; no execute bit
exec_func_overlay	EQU 2		; overlay bit

Exec0		STRUC
Exec0_environ	DW	?		; seg addr of environment
Exec0_com_line	DD	?		; pointer to asciz command line
Exec0_5C_FCB	DD	?		; default fcb at 5C
Exec0_6C_FCB	DD	?		; default fcb at 6C
Exec0		ENDS

Exec1		STRUC
Exec1_environ	DW	?		; seg addr of environment
Exec1_com_line	DD	?		; pointer to asciz command line
Exec1_5C_FCB	DD	?		; default fcb at 5C
Exec1_6C_FCB	DD	?		; default fcb at 6C
Exec1_SP	DW	?		; stack pointer of program
Exec1_SS	DW	?		; stack seg register of program
Exec1_IP	DW	?		; entry point IP
Exec1_CS	DW	?		; entry point CS
Exec1		ENDS

Exec3		STRUC
Exec3_load_addr DW	?		; seg address of load point
Exec3_reloc_fac DW	?		; relocation factor
Exec3		ENDS

;
; Exit codes in upper byte
;
Exit_terminate	    EQU     0
Exit_abort	    EQU     0
Exit_Ctrl_C	    EQU     1
Exit_Hard_Error     EQU     2
Exit_Keep_process   EQU     3

;
; EXE file header
;

EXE_file    STRUC
exe_signature	DW  ?			; must contain 4D5A  (yay zibo!)
exe_len_mod_512 DW  ?			; low 9 bits of length
exe_pages	DW  ?			; number of 512b pages in file
exe_rle_count	DW  ?			; count of reloc entries
exe_par_dir	DW  ?			; number of paragraphs before image
exe_min_BSS	DW  ?			; minimum number of para of BSS
exe_max_BSS	DW  ?			; max number of para of BSS
exe_SS		DW  ?			; stack of image
exe_SP		DW  ?			; SP of image
exe_chksum	DW  ?			; checksum  of file (ignored)
exe_IP		DW  ?			; IP of entry
exe_CS		DW  ?			; CS of entry
exe_rle_table	DW  ?			; byte offset of reloc table
exe_iov 	DW  ?			; overlay number (0 for root)
exe_sym_tab	DD  ?			; offset of symbol table in file
EXE_file    ENDS

exe_valid_signature	EQU 5A4Dh
exe_valid_old_signature EQU 4D5Ah

symbol_entry	STRUC
sym_value	DD  ?
sym_type	DW  ?
sym_len 	DB  ?
sym_name	DB  255 dup (?)
symbol_entry	ENDS
