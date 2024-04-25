;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	MACRO definitions for expanded memory manager
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	1. MACRO to save mapping context in case somebody else has
;	   mapped the page registers.
;
save_mapping_context	macro
local	save_agn_m,save_err_m,save_ok_m,save_exit_m
;	
;	the save mapping call for the above board -->
;
;		mov	ah,47h
;		mov	dx,handle
;		int	67h
;
;	on return ax = 0 signifies success
;
;
	push	ax		; save registers
	push	dx
;
;	set up emm registers and execute call to save mapping context
;
save_agn_m:
	mov	dx,cs:[above_pid]		; get emm handle
	mov	ah,above_save_map_pid	; save map call
	int	67h			; call the manager
	or	ah,ah			; is there an error?
	jz	save_ok_m			; if not we are done
;
;	error in saving mapping context, check for error
;
	cmp	ah,above_error_busy	; if the emm manager was busy
	jz	save_agn_m		; we would like to try again
;
;	unrecoverable error, indicate error type in al
;
	pop	dx
	pop	dx			; pop the regs off the stack
;
	mov	al,02h			; drive not ready
	cmp	ah,above_error_cntxt_no_stack	;
	jz	save_err_m
	cmp	ah,above_error_second_save	;
	ja	save_err_m
	mov	al,0ch			; general failure
save_err_m:
	stc
	jmp	short save_exit_m
save_ok_m:
	clc
	pop	dx
	pop	ax			; restore registers
save_exit_m:
	endm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	2. MACRO to restore the mapping context saved earlier
;
restore_mapping_context	macro
local	rest_agn_m, rest_ok_m, rest_exit_m
;
;	the restore above map call -->
;
;		mov	ah,48h
;		mov	dx,handle
;		int	67h
;	ah = 0 is success
;	
;
	push	ax
	pushf
;
rest_agn_m:
	mov	dx,cs:[above_pid]	; get emm handle
	mov	ah,above_restore_map_pid ; restore map call
	int	67h			; call manager
	or	ah,ah			; is there any error
	jz	rest_ok_m			; if not go to finish up
;
;	error condition, check for recoverable error
;
	cmp	ah,above_error_busy	; if manager was busy
	jz	rest_agn_m		; we sure can try again
	cmp	ah,above_error_no_cntxt	;
	jz	rest_ok_m			; ignore invalid pid error
;
;	unrecoverable error
;
	pop	dx
	pop	dx
	mov	al,0ch			; general failure
	stc
	jmp	short rest_exit_m
;
rest_ok_m:
	popf
	pop	ax
rest_exit_m:
;
	endm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	3. MACRO to map a page in the physical page map onto a logical
;	   page.
;
;	the map above page requires
;		mov	ah,44h
;		mov	dx,handle
;		mov	al,physical_page# (0-3)
;		mov	bx,logical_page#
;		int	67H
;	ah = 0 success and this routine zaps ax,dx and bx
;
map_page	macro
local	map_agn_m,map_exit_m,map_fin_m
;
	mov	ah,above_map	; function map page
	mov	dx,cs:[above_pid]	; get emm handle
;
	push	ax
;
map_agn_m:
	pop	ax
	push	ax
	push	bx
	push	dx		; "damn call above_map zaps these registers"
;
	int	67h		; map call
	pop	dx
	pop	bx
;
	or	ah,ah		; is there an error?
	jz	map_fin_m		; if not go to finish up
;
;	error condition - check for recoverable error
;
	cmp	ah,above_error_busy	; if manager was busy
	jz	map_agn_m			; we sure can try again
;
;	unrecoverable error
;	
	pop	ax
	mov	al,02h			; device not ready error
	stc
	jmp	short map_exit_m
;
;	exit point
;
map_fin_m:
	clc
	pop	ax
map_exit_m:
;
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;			OTHER MACROS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	1) MACRO to switch es:di with ds:si
;
src_dest_switch	macro	
;
	push	ds
	push	es
	push	si
	mov	si,di
	pop	di
	pop	ds
	pop	es
;
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
