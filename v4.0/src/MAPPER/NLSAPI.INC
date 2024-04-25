;      SCCSID = @(#)nlsapi.inc	1.1 86/06/03
SETCOUNTRYINFO      equ     1       ; select country info
SETUCASE            equ     2       ; select uppercase tbl
SETLCASE            equ     3       ; select lowercase tbl
SETUCASEFILE        equ     4       ; select uppercase spec table
SETFILELIST         equ     5       ; select valid file character list
SETCOLLATE          equ     6       ; select collating sequence
SETDBCS             equ     7       ; select double byte char set

MAXLBUFFER          equ     500     ; max size for local buffer

MAXCASEMAP          equ     256     ; max size for ucase table in casemap

MAXDBCS             equ     256     ; max size for dbcs table in casemap

NOT_DBCS_CHAR       equ     0
DBCS_CHAR           equ     1
