; find.inc

        if1
                %out    find.inc
        endif

FileFindBuf     struc
Create_Date     dw      ?
Create_Time     dw      ?
Access_Date     dw      ?
Access_Time     dw      ?
Write_Date      dw      ?
Write_Time      dw      ?
File_Size       dd      ?
FAlloc_Size     dd      ?
Attributes      dw      ?
String_Len      db      ?
File_Name       db      12 dup (?)
FileFindBuf     ends

;
; dta buffer structure
;

dtastr  struc
                db      21 dup (?)
DTAFileAttrib   db      ?
DTAFileTime     dw      ?
DTAFileDate     dw      ?
DTAFileSize     dd      ?
DTAFileName     db      13 dup (?)
dtastr  ends

MaxFinds        equ     8
OpenedHandle    equ     08000h

