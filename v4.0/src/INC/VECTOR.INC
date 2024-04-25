;	SCCSID = @(#)vector.asm	1.1 85/04/10
BREAK <interrupt definitions>

Asmvar	AltVect

INTTAB		EQU	20H
INTBASE 	EQU	4 * inttab
ENTRYPOINT	EQU	INTBASE+40H

	IF	ALTVECT
ALTTAB	EQU	0F0H
ALTBASE EQU	4 * ALTTAB
	ENDIF

;
; interrupt assignments
;
	IF	NOT ALTVECT
int_abort	    EQU     INTTAB	; abort process
int_command	    EQU     int_abort+1 ; call MSDOS
int_terminate	    EQU     int_abort+2 ; int to terminate address
int_ctrl_c	    EQU     int_abort+3 ; ^c trapper
int_fatal_abort     EQU     int_abort+4 ; hard disk error
int_disk_read	    EQU     int_abort+5 ; logical sector disk read
int_disk_write	    EQU     int_abort+6 ; logical sector disk write
int_keep_process    EQU     int_abort+7 ; terminate program and stay
					; resident
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
int_spooler	    EQU     int_abort+8 ; spooler call
int_fastcon	    EQU     int_abort+9 ; fast CON interrupt
int_IBM 	    EQU     int_abort+10; critical section maintenance
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
	ELSE
int_abort	    EQU     INTTAB	; abort process
int_command	    EQU     int_abort+1 ; call MSDOS
int_terminate	    EQU     ALTTAB	; int to terminate address
int_ctrl_c	    EQU     int_terminate+1 ; ^c trapper
int_fatal_abort     EQU     int_terminate+2 ; hard disk error
int_disk_read	    EQU     int_abort+5 ; logical sector disk read
int_disk_write	    EQU     int_abort+6 ; logical sector disk write
int_keep_process    EQU     int_abort+7 ; terminate program and stay resident
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
int_spooler	    EQU     int_terminate+3 ; spooler call
int_fastcon	    EQU     int_abort+9 ; fast CON interrupt
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
	ENDIF

addr_int_abort		EQU    4 * int_abort
addr_int_command	EQU    4 * int_command
addr_int_terminate	EQU    4 * int_terminate
addr_int_ctrl_c 	EQU    4 * int_ctrl_c
addr_int_fatal_abort	EQU    4 * int_fatal_abort
addr_int_disk_read	EQU    4 * int_disk_read
addr_int_disk_write	EQU    4 * int_disk_write
addr_int_keep_process	EQU    4 * int_keep_process
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
addr_int_spooler	EQU    4 * int_spooler
addr_int_fastcon	EQU    4 * int_fastcon
addr_int_IBM		EQU    4 * int_IBM
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
