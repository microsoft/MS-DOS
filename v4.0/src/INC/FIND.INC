;	SCCSID = @(#)find.asm	1.1 85/04/10
;	SCCSID = @(#)find.asm	1.1 85/04/10
Break	<find first/next buffer>

find_buf    STRUC
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
find_buf_drive	    DB	?		; drive of search
find_buf_name	    DB	11 DUP (?)	; formatted name
find_buf_sattr	    DB	?		; attribute of search
find_buf_LastEnt    DW	?		; LastEnt
find_buf_DirStart   DW	?		; DirStart
find_buf_NetID	    DB	4 DUP (?)	; Reserved for NET
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

find_buf_attr	    DB	?		; attribute found
find_buf_time	    DW	?		; time
find_buf_date	    DW	?		; date
find_buf_size_l     DW	?		; low(size)
find_buf_size_h     DW	?		; high(size)
find_buf_pname	    DB	13 DUP (?)	; packed name
find_buf    ENDS
