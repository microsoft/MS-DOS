;	SCCSID = @(#)pdb.asm	1.1 85/04/10
BREAK <Process data block>

;
; Process data block (otherwise known as program header)
;

FilPerProc	    EQU     20

Process_data_block  STRUC
PDB_Exit_Call	    DW	    ?		; INT int_abort system terminate
PDB_block_len	    DW	    ?		; size of execution block
		    DB	    ?
PDB_CPM_Call	    DB	5 DUP (?)	; ancient call to system
PDB_Exit	    DD	    ?		; pointer to exit routine
PDB_Ctrl_C	    DD	    ?		; pointer to ^C routine
PDB_Fatal_abort     DD	    ?		; pointer to fatal error
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
PDB_Parent_PID	    DW	    ?		; PID of parent (terminate PID)
PDB_JFN_Table	    DB	FilPerProc DUP (?)
					; indices into system table
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
PDB_environ	    DW	    ?		; seg addr of environment
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
PDB_User_stack	    DD	    ?		; stack of self during system calls
PDB_JFN_Length	    DW	    ?		; number of handles allowed
PDB_JFN_Pointer     DD	    ?		; pointer to JFN table
PDB_Next_PDB	    DD	    ?		; pointer to nested PDB's
PDB_PAD1	    DB	    14h DUP (?)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
PDB_Call_system     DB	    5 DUP (?)	; portable method of system call
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
PDB_PAD2	    DB	    7h DUP (?)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
Process_data_block  ENDS

PDB_InterCon	EQU	BYTE PTR PDB_PAD1	; 2/12/KK
PDB_Append	EQU	BYTE PTR PDB_PAD1+1	; 2/12/KK
