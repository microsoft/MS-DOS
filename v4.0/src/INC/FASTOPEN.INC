;
; EXPORT DATE: 9/11
;Equates for FASTOPEN.

;FASTOPEN NAME CACHING Subfunctions
FONC_Look_up	equ	1
FONC_insert	equ	2
FONC_delete	equ	3
FONC_update	equ	4
FONC_purge	equ	5		;reserved for the future use.

;FASTOPEN EXTENT  CACHING Subfunctions
FSK_Open       equ     11					       ;AN000;
FSK_Close      equ     12					       ;AN000;
FSK_Delete     equ     13					       ;AN000;
FSK_Lookup     equ     14					       ;AN000;
FSK_Insert     equ     15					       ;AN000;
FSK_Trunc      equ     16					       ;AN000;

HeaderSize     equ    8        ; size of file header (8 bytes)	       ;AN000;
ExtendSize     equ    8        ; size of extend (8 bytes)	       ;AN000;
Num_Of_Pages   equ    1        ; number of pages		       ;AN000;
Num_Of_Segs    equ    2        ; number of frame segments	       ;AN000;
Stayresident  equ    04ch     ; terminate and stay resident function code


;Equates used in DOS.
FastOpen_Set	       equ     00000001B
FastOpen_Reset	       equ     11111110B
Lookup_Success	       equ     00000010B
Lookup_Reset	       equ     11111101B
Special_Fill_Set       equ     00000100B
Special_Fill_Reset     equ     11111011B
No_Lookup	       equ     00001000B
Set_For_Search	       equ     00010000B	     ;DCR 167


;============= FastOpen Data Structures =====================

Fastopen_Entry	STRUC			;Fastopen Entry pointer in DOS
Fastopen_Entry_size	dw	4	;size of the following
Fastopen_Name_Caching	dd	?
;Fastopen_FatChain_Caching dd	  ?	;reserved for future use
Fastopen_Entry	ENDS
;


CMPCT_DIR_INFO	STRUC			;compact version of Dir Info.
CDI_file_name	db	11 dup (' ')
CDI_file_attr	db	?
CDI_codepage	dw	?
CDI_extcluster	dw	?
CDI_attr2	db	?
CDI_time	dw	?
CDI_date	dw	?
CDI_cluster	dw	?
CDI_filesize	dd	?
CMPCT_DIR_INFO	ENDS
;

ORIG_DIR_INFO	STRUC
ODI_head	db	17 dup (?)
ODI_skip	db	5  dup (0)	;reserved for DOS. FASTOPEN does not
ODI_tail	db	10 dup (?)	;  use ODI_skip part.
ORIG_DIR_INFO	ENDS
;

ODI_head_leng	equ	17
ODI_skip_leng	equ	5
ODI_tail_leng	equ	10
;

FASTOPEN_EXTENDED_INFO	STRUC
FEI_dirpos	db	0
FEI_dirsec	dd	0
FEI_clusnum	dw	0
FEI_lastent	dw	0		; for search first
FEI_dirstart	dw	0		; for search first
FASTOPEN_EXTENDED_INFO	ENDS
;

NAME_RECORD	STRUC
nLRU_ptr	dw	-1
nMRU_ptr	dw	-1		;reverse of nLRU_ptr
nChild_ptr	dw	-1
nSibling_ptr	dw	-1
nBackward_ptr	dw	-1		;points to preceding node
nCmpct_Dir_Info db	size Cmpct_Dir_Info dup (' ')
nExtended_Info	db	size Fastopen_Extended_Info dup (?)
NAME_RECORD	ENDS
;

DRIVE_CACHE_HEADER	STRUC		;drive cache header
DCH_LRU_ROOT	 dw	 0		;Header of the LRU chain of this drive
DCH_MRU_ROOT	 dw	 0		;offset to the last entry of LRU chain
DCH_Child_ptr	 dw	 -1		;the first child in Name cache seg.
DCH_Sibling_ptr  dw	 -1		;points to the next drive cache header
DCH_Drive_letter db	'C'             ;drive letter
DCH_Num_Entries  dw	 0		;Number of entries in the Name cache.
DCH_Name_Buff	 dw	 0		;pointer to name cahe buffer
DRIVE_CACHE_HEADER	ENDS
;





;======== FAST SEEK FUNCTION  DATA  STRUCTURES =======================

DRIVE_HEADER	STRUC		   ; Drive header structure		;AN000;
Drive_Number	     dw     0	   ; drive number			;AN000;
Extent_Count	     dw     0	   ; reserved for debugging
MRU_Hdr_Ptr	     dw     0	   ; pointer to OPEN Queue
Free_ptr	     dw     0	   ; pointer to FREE buffer		;AN000;
Close_Ptr	     dw     0	   ; pointer to CLOSE Queue	     ;AN000;
Buff_Size	     dw     0	   ; cache buffer size including header ;AN000;
Free_Size	     dw     0	   ; size of Free area in bytes
Next_Drv_Hdr_Ptr     dw     0	   ; pointer to next drive header
DRIVE_HEADER   ENDS



FILE_HEADER	STRUC		   ; File header structure		;AN000;
FH_Phys_Clus_Num     dw     0	   ; starting physcial clustnum of file ;AN000;
FH_Refer_Count	     dw     0	   ; reference count			;AN000;
FH_Next_Extn_Ptr     dw     0	   ; pointer to first extent of the file;AN000;
FH_Next_Hdr_Ptr      dw     0	   ; pointer to next file header	;AN000;
FH_MRU_Extn_Ptr      dw     0	   ; pointer to  MRU extent
		     dw     0
		     dw     0
		     dw     0
FILE_HEADER	ENDS							;AN000;



EXTENT_HEADER	STRUC		   ; extend header structure		;AN000;
EH_Logic_Clus_Num    dw     0	   ; starting logical clus num of extent;AN000;
EH_Phys_Clus_Num     dw     0	   ; starting physical clus numof  extnt;AN000;
EH_Count	     dw     0	   ; range of logical clusnum in the extnt
EH_Next_Extn_Ptr     dw     0	   ; pointer to next extent		;AN000;
EH_Prev_Extn_Ptr     dw     0	   ; pointer to previous extent  ;AN000;
EH_Next_LRU_Ptr      dw     0	   ; pointer to next LRU extent
EH_Prev_LRU_Ptr      dw     0	   ; pointer tp previous LRU extent
		     dw     0
EXTENT_HEADER	ENDS



