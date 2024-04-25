page	60,120
;      @@04 07/30/86 Fix second APPEND hang		 PTM P0000053
;      @@05 08/13/86 Fix bad parm message		PTM P0000125
;      @@10 08/28/86 Change message for @@05		PTM P0000291
;      @@11 09/10/86 Support message profile and make
;		     msg length variable.	R.G. PTM P0000479
cseg	segment public para 'CODE'
	assume	cs:cseg

	public	bad_append_msg			;@@11
	public	path_error_msg			;@@11
	public	parm_error_msg			;@@11
	public	path_parm_error_msg		;@@11
	public	no_append_msg			;@@11
	public	append_assign_msg		;@@11
	public	append_tv_msg			;@@11
	public	bad_DOS_msg			;@@11
	public	second_append_msg		;@@11

	public	len_bad_append_msg		;@@11
	public	len_path_error_msg		;@@11
	public	len_parm_error_msg		;@@11
	public	len_path_parm_error_msg 	;@@11
	public	len_no_append_msg		;@@11
	public	len_append_assign_msg		;@@11
	public	len_append_tv_msg		;@@11
	public	len_bad_DOS_msg 		;@@11
	public	len_second_append_msg		;@@11

cr	equ	13
lf	equ	10

include appendm.inc

cseg		ends
		end
