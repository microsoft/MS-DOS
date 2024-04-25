	Page 84,132 ;
Title	FASTOPEN

;--------------- INCLUDE FILES -----------------
.xcref
.xlist
debug=0 		  ;this is an equate only for DOSMAC.inc
INCLUDE DOSMAC.inc
.list
.cref
INCLUDE dirent.inc
INCLUDE fastsegs.inc	  ; Cannot declare this in DOS includes
INCLUDE fastopen.inc	  ; This include file also contains DOS equates


CSEG_MAIN   SEGMENT   PARA   PUBLIC 'CODE'       ; Cseg_Seek segment

EXTRN	VECTOR_DELETE:dword	; jump vector inside Cseg_Seek to make
				; a FAR call to FSeek Delete function within
				; the segment

CSEG_MAIN      ENDS


;*****************************************************************************
; ALL FastSeek functions are kept in a seperate segment.  They are accessed
; by a FAR indirect call from the MAIN routine.

; ADDRESSABILTY: DS is for accessing local data in Cseg_Seek segment
;		 ES is for accessing data in the extent cache buffer
;					  in the Cseg_Init segment
;		 On entry, only DS is set, ES is set to Cache segment later
;*****************************************************************************

CSEG_SEEK   SEGMENT   PARA   PUBLIC 'code'
	 assume  cs:cseg_seek,ds:nothing,es:nothing,ss:nothing

PUBLIC	 Seek_name_cache_seg									   ;AN000;
PUBLIC	 Seek_Num_Of_drives
PUBLIC	 Seek_extent_drive_Buff 								   ;AN000;
PUBLIC	 Seek_Total_Ext_Count									   ;AN000;
PUBLIC	 Seek_Total_Name_Count									   ;AN000;
PUBLIC	 Seek_Name_Drive_Buff									   ;AN000;
PUBLIC	 Seek_Name_Cache_Buff									   ;AN000;
PUBLIC	 End_Seek
PUBLIC	 Check_Flag
												   ;AN000;
PUBLIC	 Fk_Open
PUBLIC	 Fk_Close										   ;AN000;
PUBLIC	 Fk_Insert										   ;AN000;
PUBLIC	 Fk_Delete
PUBLIC	 Fk_Lookup										   ;AN000;
PUBLIC	 Fk_Truncate
PUBLIC	 Fk_Purge


;;---------- FASTSEEK LOCAL VARIABLES ---------------------

First_Phys_ClusNum   dw      0		; first phys clus num of file (file id) 	       ;AN000;
Logical_ClusNum      dw      0		; logical cluster num to be searched					     ;AN000;
Physical_ClusNum     dw      0		; physical clus num of above logical clus num								;AN000;
Extent_buff_Ptr      dw      0		; starting offset of extent cache			   ;AN000;
drv_id		     db      -1 	; drive id of last fastseek function
func_cod	     db      0		; function code

Cur_Hdr_Ptr	     dw      0		; address of current header				  ;AN000;
Cur_Extn_Ptr	     dw      0		; address of current extent				 ;AN000;
New_Extn_Ptr	     dw      0		; address of area where new extent will be created
New_Hdr_Ptr	     dw      0		; address of area where new header will be created	   ;AN000;
Prev_Hdr_Ptr	     dw      0		; address of previous header				  ;AN000;
Prev_Extn_Ptr	     dw      0		; address of previous extent				   ;AN000;

Prev_MRU_Extn_Ptr    dw      0		; address of previous MRU extent			       ;AN000;
LRU_Prev_Hdr	     dw      0		; address of previous hdr to the LRU header			  ;AN000;
LRU_Prev_Extent      dw      0		; address of previous extent to LRU extent							     ;AN000;
LRU_Extent	     dw      0		; address of LRU extent 				  ;AN000;
LRU_Hdr 	     dw      0		; address of LRU header 				  ;AN000;

Drive_Hdr_Ptr	     dw      0		; address of drive header of current drive				   ;AN000;
From_FreeBuff	     dw      0		; 1 = if call from Free_Buff routine					   ;AN000;
Hdr_Flag	     dw      0		; 1 = current header is the only
					; remaining header in Queue
Extn_Flag	     dw      0		; 1 = current extent is the only			   ;AN000;;AN000;
					; remaining extent under this header
Fully_Flag	     dw      0		; 1= cluster fully found in extent			   ;AN000;;AN000;
					; 0= cluster partially found
Find_Flag	     dw      0		; # = specifies the relative location of the new cluster							 ;AN000;
Open_Queue_Flag      dw      0		; 1 = if open queue is empty							     ;AN000;
Free_Flag	     dw      0		; Free area Type: 0 - continuous			    ;AN000;
					;		  1 - non-continuous
Queue_Type	     dw      0		; Queue Type:  0 - Open Queue				   ;AN000;
					;	       1 - Close Queue
phys_num	     dw      0		; ** for queue analyser
logic_num	     dw      0		; ** for queue analyser


; Following data area is initialized during initialization
Check_Flag		     dw      0
Seek_name_cache_seg	     dw      Cseg_Init	     ; Seg ID of Ccahe buffer
Seek_Num_Of_drives	     dw      0		     ; number of drives 			   ;AN000;
Seek_Total_Name_Count	     dw      0		     ; total name count
Seek_Total_Ext_Count	     dw      0		     ; total extent count
Seek_Name_Drive_Buff	     dw      0		     ; starting address of name drive buffers		;AN000;
Seek_Name_Cache_Buff	     dw      0		     ; starting address of name cahe buffers		;AN000;
Seek_extent_drive_Buff	     dw      0		     ; starting address of extent			;AN000;
						     ; cache in the cache buffer




;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; PROCEDURE: FK_OPEN
;
; FUNCTION: Create and initialize a file header  using	the  starting
;	    Physical  Cluster  number (file id) of the file.
;
;	    If the file header already exist in the OPEN Queue, then increase
;	    the file reference count by one and make the header
;	    MRU header.
;
;	    If header is not found in the OPEN Queue, then check to
;	    see if it exists in the CLOSE Queue.  If found in the
;	    CLOSE Queue, move the header and the extents to the top of
;	    OPEN Queue and make the header MRU header.
;
;	    If the header is not found in both Queues, create  a new
;	    header at the top of the OPEN Queue and initialize with the
;	    given first physical cluster number.
;
;	    If not enough space for new header in OPEN Queue, find the
;	    LRU header and Last Exetent in the CLOSED Queue. Delete this
;	    extent and use the space for the new header.  If none in
;	    CLOSE Queue, find the LRU header and the LRU extent in the
;	    OPEN Queue.  Delete this extent and use this space.
;
;
; INPUT:   CX = First Physical Cluster Number of the file
;	   DL = Drive ID
;
;
; OUTPUT:  Created a new file header. If header already exist, then the file
;	   reference count is incremented by one.
;
; ROUTINES REFERENCED: Find_File_Header, Find_Drive_Header
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;-------------------------------------------------------------------------------


FK_OPEN    PROC    FAR

       push   cs			 ; establish addressability				   ;AN000;
       pop    ds			 ; DS --> code segment					   ;AN000;
       assume ds:Cseg_Seek									   ;AN000;
       mov    es, Seek_Name_Cache_Seg	 ; setup cache buff segment			   ;AN000;
       assume es:Cseg_Init		 ; ES --> cache buffer segment				   ;AN000;
       mov    First_Phys_Clusnum,cx	 ; save physical cluster number 			       ;AN000;
       mov    func_cod,al

;-------------------------------------------------------------------------------
; Search for Drive header in the cache buffer using Drive ID in DL
;-------------------------------------------------------------------------------
       CALL   FIND_DRIVE_HEADER 	 ; get drive buffer Header				   ;AN000;
					 ; DI-->drive header
       jnc    open_Search_Header	 ; header found - check for file header      ;AN000;
       jmp    open_exit 		 ; drive header not found - exit			 ;AN000;

;------------------------------------------------------------------------------
; Check if both OPEN and CLOSE Queues are empty.  If empty, create a new
; file header at the top of OPEN Queue.  If there are headers, search OPEN
; queue.  If found, increment file count by one.  If not found, check if
; the  file header exists in  CLOSE Queue.  If found, move header to the
; top of the OPEN Queue.
;------------------------------------------------------------------------------
Open_Search_Header:
       inc    es:[di].Extent_Count	 ; increment sequence count ( DEBUG)
       mov    ax,es:[di].Buff_Size	 ; total buffer size equal				   ;AN000;
       cmp    es:[di].Free_Size,ax	 ; to current free area 				   ;AN000;
       jne    Search_Open_List		 ; yes, check OPEN and CLOSE Queues			   ;AN000;
					 ; for header
       jmp    Open_Make_Hdr		 ; no, make new header					   ;AN000;


;------------------------------------------------------------------------------
; Search for  header in the OPEN Queues. If found, increment file reference
; count by one.
;------------------------------------------------------------------------------

Search_Open_List:
       mov   cx,First_Phys_Clusnum	 ; CX = first phys clus number				   ;AN000;
       mov   si,es:[di].MRU_Hdr_Ptr								   ;AN000;
       cmp   si, -1			 ; Any header in OPEN Queue ??				   ;AN000;
       je    Open_Chk_Close_list	 ; none, check CLOSE Queue				   ;AN000;

       CALL  FIND_FILE_HEADER		 ; search header in OPEN Queue				 ;AN000;
       jc    Open_chk_CLOSE_list	 ; if not found check in CLOSE Queue			   ;AN000;

;------------------------------------------------------------------------------
; Found in the OPEN Queue. Now, increment the file reference count by one
; and also make the header MRU header. If header found is LRU header then
; make previous header LRU header. If header is not LRU header, connect
; previous header to next header. If the header is the first header in the
; Queue, dont make it to MRU header since it is already at the top of Queue.
;------------------------------------------------------------------------------
					 ; DI-->Header found
       inc  es:[di].FH_refer_Count	 ; increment file reference count			;AN000;
       cmp   Hdr_Flag, 1		 ; current header Single header ??			;AN000;
       jne   Open_Chk_Last_Hdr		 ; No, Check for last header				;AN000;
       clc				 ; make sure caary is clear
       jmp   Open_Exit			 ; yes, exit						;AN000;

Open_Chk_Last_Hdr:
       cmp   Hdr_Flag, 3		 ; current header LRU header ?? 			;AN000;
       jne   Open_Join_Gap		 ; no, close the gap					;AN000;

Mark_Previous_Hdr:			 ; yes - mark previous hdr
       mov   si, Prev_Hdr_Ptr									   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,-1     ; yes, Mark previous Hdr LRU hdr			   ;AN000;

; Make current Hdr  MRU header. No need to close the gap
       CALL  MAKE_MRU_HEADER		 ; move header to top of Queue				   ;AN000;
       clc				 ; make sure caary is clear
       jmp   Open_Exit			 ; then EXIT						   ;AN000;


;-----------------------------------------------------------------------------
; Comes here if current header is first of many headers or in between a previous
; and next header. Make current header MRU header and close the gap.
;-----------------------------------------------------------------------------
Open_Join_Gap:
					 ; DI-->Current header
       cmp   Hdr_Flag, 2		 ; current Header First Hdr in Queue ?? 		   ;AN000;
       jne   Open_Make_MRU_Hdr		 ; no, jump						   ;AN000;
       clc				 ; MAKE SURE caary is clear
       jmp   Open_Exit			 ; yes, no need to make MRU hdr, or			   ;AN000;
					 ; or close the gap

Open_Make_MRU_Hdr:			 ; header is between 1st and last headers
       CALL  MAKE_MRU_HEADER		 ; move header to top of Queue				    ;AN000;

       clc				 ; make sure caary is clear
       jmp   Open_exit			 ; then EXIT						   ;AN000;


;------------------------------------------------------------------------------
; Look for a header in the CLOSE Queue.  If found, move file header and
; and extents (if any) to top of OPEN Queue. If not found in the CLOSE
; queue, create a new header at the top of OPEN queue.
;------------------------------------------------------------------------------
Open_Chk_Close_List:
       mov    di,drive_Hdr_Ptr		 ; DI-->current drive header				   ;AN000;
       cmp    es:[di].CLOSE_Ptr,-1	 ; anything in CLOSE Queue ??				   ;AN000;
       jne    open_search_hdr		 ; if any, search CLOSE Queue				   ;AN000;
       jmp    open_make_hdr		 ; if none, make a new header				   ;AN000;


;------------------------------------------------------------------------------
; CLOSE Queue is not empty, next search  for header in the CLOSE Queue using
; starting physical cluster number of the file.
;------------------------------------------------------------------------------
Open_Search_Hdr:			 ;
       mov   si,es:[di].Close_Ptr	 ; SI-->first header in the				;AN000;
					 ; in the CLOSE  Queue					   ;AN000;
       mov   cx,First_Phys_Clusnum	 ; CX = first phys clus number				   ;AN000;
       CALL  FIND_FILE_HEADER		 ; find file header in CLOSE Queue			    ;AN000;
					 ; DI-->header found
       jnc   open_chk_only_hdr		 ; if found, check only header				   ;AN000;
       jmp   short open_make_hdr	 ; if not, make a new header				   ;AN000;

;------------------------------------------------------------------------------
; Found header in the CLOSE Queue. Check if the header found is the single HDR
; in the CLOSE Queue, If single header, then, mark the CLOSE Queue as empty
; before copy the this header to the OPEN Queue.
;------------------------------------------------------------------------------
Open_Chk_only_Hdr:			 ;
       cmp   Hdr_flag, 1		 ; Only Header in the CLOSE Queue??				   ;AN000;
       jne   Open_chk_Last_header	 ; if not check header is LRU header			       ;AN000;

       mov   di,Drive_Hdr_Ptr		 ; only header in the CLOSE Queue			   ;AN000;
       mov   es:[di].Close_Ptr,-1	 ; mark CLOSE Queue as empty				   ;AN000;
       jmp   short Open_Move_Hdr	 ; then move header to OPEN Queue			   ;AN000;

;------------------------------------------------------------------------------
; Current header is not the only header in the CLOSE Queue. Now check if the
; current header is the LRU header in CLOSE Queue.  If true, mark previous
; header as LRU header before moving it from from CLOSE Queue to OPEN queue.
;------------------------------------------------------------------------------
Open_Chk_Last_Header:			 ;
       cmp   Hdr_Flag, 3		 ; Current header last header ??			   ;AN000;
       jne   Open_Close_gap		 ; no, close the gap before move it			;AN000;
					 ; to OPEN Queue
       mov   si, Prev_Hdr_Ptr									   ;AN000;
       mov   es:[si].Fh_Next_Hdr_Ptr,-1  ; yes, mark the previous hdr as last			   ;AN000;
       jmp   short open_move_Hdr	 ; header then move to the top of			   ;AN000;
					 ; OPEN Queue

;------------------------------------------------------------------------------
; Close the gap in the CLOSE Queue.
;------------------------------------------------------------------------------
Open_Close_Gap:
       mov   Queue_Type, 1		 ; set flag to indicate CLOSE Queue			   ;AN000;
       CALL  JOIN_PREV_TO_NEXT		 ; join previous header to next header			   ;AN000;

;------------------------------------------------------------------------------
; Now move the current header from CLOSE Queue to top of OPEN Queue
;------------------------------------------------------------------------------
Open_Move_Hdr:
       mov   si,Cur_Hdr_Ptr		 ; SI-->Current header					;AN000;
       mov   di,drive_Hdr_Ptr		 ; DI-->drive header					;AN000;

;------------------------------------------------------------------------------
;Update the file refernce count to 1 before move header to OPEN Queue
;------------------------------------------------------------------------------
       mov   es:[si].FH_Refer_Count, 1	    ; set refernce count = 1				   ;AN000;
       mov   ax,es:[di].MRU_Hdr_Ptr	    ; address of current MRU header			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax     ; connect new header to the 			   ;AN000;
					    ; current MRU header
       mov   es:[di].MRU_Hdr_Ptr,si	    ; make the header MRU header			   ;AN000;
       clc											   ;AN000;
       jmp   short open_exit		    ; then exit.					      ;AN000;

;------------------------------------------------------------------------------
; If header is not found in both OPEN  and CLOSE Queues, then make a new
; header in the next available free area and initialize the new header and
; make it MRU header (mov it to the top of the OPEN Queue).
; If no free space to create a new header, get space from CLOSE Queue.
; If none in CLOSE Queue, then get space from from OPEN Queue. See the
; Procedure (Find_Free_Buffer )
;------------------------------------------------------------------------------
Open_Make_Hdr:

       CALL   MAKE_NEW_HEADER		 ; create new header					   ;AN000;
       clc											   ;AN000;

Open_exit:
       CALL   Check_it
       ret				 ; return						   ;AN000;

Fk_Open   endp







;--------------------------------------------------------------------------
; PROCEDURE: FK_CLOSE
;
; FUNCTION:  Search for the header on OPEN Queue.  If the header is found,
;	     decrement the file reference count by one.  If the resultant
;	     count is zero, then move the header and the extents under it
;	     to the CLOSE Queue.  If not, make the header MRU header in the
;	     OPEN Queue.
;
; INPUT:     DL = Drive Number
;	     CX = First Physical Cluster Number of the file
;
; OUTPUT:    Moved the file header and the extents to the close Queue
;
; ROUTINES REFERENCED:	Find_File_Header, Find_Drive_Header
;
; REVISION HISTORY:  New  (5/87)
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;---------------------------------------------------------------------------

FK_CLOSE    PROC   FAR
												   ;AN000;
; Search for Drive header in the Cache buffer using Drive ID in DL
       push   cs			 ; establish addressability				   ;AN000;
       pop    ds			 ; DS --> code segment					   ;AN000;
       assume ds:Cseg_Seek									   ;AN000;
       mov    es, Seek_Name_Cache_Seg	 ; setup cache buff segment register			   ;AN000;
       assume es:Cseg_Init		 ; ES --> cache buffer segment				   ;AN000;
       mov    First_Phys_Clusnum, CX	 ; save phys cluster number				   ;AN000;
       mov    func_cod,al

       CALL   FIND_DRIVE_HEADER 	 ; search for drive header
					 ; DI-->Current drive buffer
       jnc    Close_search_hdr		 ; found, search for file header			   ;AN000;
       clc				 ; MAKE SURE carry is clear
       jmp    Close_Exit		 ; not found, error					   ;AN000;

;--------------------------------------------------------------------------
; Search for file header in the OPEN Queue using given physical cluster number
;--------------------------------------------------------------------------
Close_Search_Hdr:
       inc    es:[di].Extent_Count	 ; increment sequence coutn (DEBUG)
       mov   si,es:[di].MRU_Hdr_Ptr	 ; SI-->first header in OPEN Queue			   ;AN000;
       mov   cx,First_Phys_Clusnum	 ; CX = First phys clus num				   ;AN000;
       CALL  FIND_FILE_HEADER		 ; find the header in OPEN Queue
					 ; DI-->header found					;AN000;
       jnc   Close_Chk_Last_Hdr 	 ; jump if header found 				   ;AN000;
       clc				 ; clear carry							      ;AN000;
       jmp   short close_exit		 ; headr not found - exit					    ;AN000;

;--------------------------------------------------------------------------
; Check if the header found is the only header in the OPEN  Queue. If true
; go and decrement file reference count by one.
;--------------------------------------------------------------------------
Close_Chk_Last_Hdr:
       cmp   Hdr_Flag, 1		 ; Only header in the Queue ??				      ;AN000;
       je    Dec_Ref_Count		 ; yes -  decrement count, if count =0			     ;AN000;
					 ; then move to the top of CLOSE Queue
       cmp   Hdr_Flag, 3		 ; no - Last Header in the CLOSE Queue??			;AN000;
       jne   Close_Join_Hdr		 ; no, close gap					   ;AN000;
       mov   si,Prev_Hdr_Ptr		 ; make the previous header LRU Hdr			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr, -1    ; mark previous hdr 				   ;AN000;
       jmp   short Dec_Ref_Count	 ; decrement count and move to				   ;AN000;
					 ; CLOSE Queue

;--------------------------------------------------------------------------
; Connect previous header to next header to close the gap in OPEN Queue
;--------------------------------------------------------------------------
Close_Join_Hdr:
       mov   si,Cur_Hdr_Ptr		 ; SI-->Current header
       dec   es:[si].FH_Refer_Count	 ; decrement fiel refernce count
       cmp   es:[si].FH_Refer_Count,0	 ; count = 0 ??
       jne   Close_Make_MRU		 ; no - make current header MRU header

       mov   Queue_Type, 0		 ; else set flag to indicate OPEN Queue 			;AN000;
       CALL  JOIN_PREV_TO_NEXT		 ; close gap before move to CLOSE queue 					    ;AN000;
       jmp   short move_to_Close_List	 ; move header to CLOSE queue

;--------------------------------------------------------------------------
; Decrement the reference count by one.  If count = 0, then move the header to
; the top of CLOSE Queue.  Else, dont move to CLOSE queue, since the file has
; have multiple open before.  In this case make the header MRU header in the
; OPEN queue.
;--------------------------------------------------------------------------
Dec_Ref_Count:
       mov   si,Cur_Hdr_Ptr		  ; SI-->Current header 				;AN000;
       dec  es:[si].FH_Refer_Count	  ; decrement refernece count				   ;AN000;
       cmp  es:[si].FH_Refer_Count,0	  ; reference count = 0 ??				   ;AN000;
       je   Move_to_Close_List		  ; yes, move header to CLOSE Queue			   ;AN000;

;--------------------------------------------------------------------------
; Else, move current Header to top of OPEN Queue.  Move to the top of the queue
; only if the header is not the first header in the queue.
;--------------------------------------------------------------------------
Close_Make_MRU:
       cmp   Prev_Hdr_Ptr,-1		 ; first header in the Queue ?? 			   ;AN000;
       je    Dont_Move_To_Top		 ; yes, dont move to top				   ;AN000;

       CALL  MAKE_MRU_HEADER		 ; move header to top of queue				   ;AN000;

Dont_Move_To_Top:
       clc											   ;AN000;
       jmp   short Close_Exit		   ; exit						     ;AN000;


;--------------------------------------------------------------------------
; Move header to the top  of the CLOSE Queue. If the header is the only header
; header in the OPEN Queue, mark OPEN Queue empty.
;--------------------------------------------------------------------------
Move_To_Close_List:
       mov    si,Cur_Hdr_Ptr		    ; SI-->Cur_Hdr_Ptr					   ;AN000;
       cmp    hdr_flag,1		    ; single header in the Queue ??			      ;AN000;
       jne    Join_To_Close_List	    ; no, move header to CLOSE queue			       ;AN000;
       mov    di,Drive_Hdr_Ptr									   ;AN000;
       mov    es:[di].MRU_Hdr_Ptr, -1	    ; else mark OPEN Queue empty			      ;AN000;

Join_To_Close_List:
       mov    di,Drive_Hdr_Ptr		    ; DI-->current drive header 			      ;AN000;
       mov    ax,es:[di].Close_Ptr	    ; connect current header to the			   ;AN000;
       mov    es:[si].FH_Next_Hdr_Ptr,ax    ; previous first hdr in CLOSE queue 		   ;AN000;
       mov    es:[di].Close_Ptr,si	    ; make the current header first
					 ; header in the CLOSE queue
       clc											   ;AN000;

Close_Exit:
       CALL   Check_it
       ret				 ; return						   ;AN000;

FK_CLOSE   ENDP






;------------------------------------------------------------------------
;
; PROCEDURE: FK_DELETE
;
; FUNCTION:  Delete a specific header and extents under the header
;	     and release the buffers to the FREE pool
;
;	     Search OPEN Queue for file header. If found, delete header and
;	     extents and release the buffer to FREE area.  If not found in OPEN
;	     queue, search CLOSE Queue.  If found, delete header and extents
;	     under the header and release the area to FREE area.
;
; INPUT:   CX = First Physical Cluster Number of the file
;	   DL = drive id
;
; OUTPUT:  The file header and the extents are deleted
;
; ROUTINES REFERENCED:	Find_File_Header, Find_Drive_Header
;
; REVISION HISTORY:  New  (5/87)
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;-------------------------------------------------------------------------

FK_DELETE   PROC   FAR

       push   cs			 ; establish addressability				   ;AN000;
       pop    ds			 ; DS --> code segment					   ;AN000;
       assume ds:Cseg_Seek									   ;AN000;
       mov    es, Seek_Name_Cache_Seg	 ; setup cache buff segment register			   ;AN000;
       assume es:Cseg_Init		 ; ES --> cache buffer segment				   ;AN000;
       mov    First_Phys_Clusnum,cx	 ; save phys cluster number				   ;AN000;
       mov    func_cod,al

;--------------------------------------------------------------------------
; If the delete call is from Free_Buff, then go straight to file header
; search. Else usual delete request from DOS
;--------------------------------------------------------------------------
       cmp    From_FreeBuff,1		 ; call from Free_Buff routine ??
       je     Del_Search_Close_List	 ; yes - find file header in CLOSE queue

;--------------------------------------------------------------------------
; Search for Drive Cache buffer using Drive ID in DL
;--------------------------------------------------------------------------
       CALL   FIND_DRIVE_HEADER 	 ; get drive buffer					   ;AN000;
       jnc    Delete_search_hdr 	 ; found, search for file header			   ;AN000;
       jmp    Delete_Exit		 ; not found, error					   ;AN000;

;--------------------------------------------------------------------------
; Search for a header in the OPEN  Queue using given physical cluster  number
;--------------------------------------------------------------------------
Delete_Search_Hdr:
       inc    es:[di].Extent_Count	 ; ;***;
       mov   si,es:[di].MRU_Hdr_Ptr	 ; SI-->first header in the				;AN000;
					 ; in the OPEN queue					  ;AN000;
       cmp   si, -1			 ; any header in OPEN Queue ??				   ;AN000;
       je    Del_search_Close_list	 ; none, search CLOSE queue				   ;AN000;
       mov   cx,First_Phys_Clusnum	 ; CX = first phys clus number				   ;AN000;
       CALL  FIND_FILE_HEADER		 ; find the header in OPEN queue			  ;AN000;
       jnc   Del_Open_Last_Hdr		 ; if found, jump					   ;AN000;


;--------------------------------------------------------------------------
; Not found in OPEN queue. Search in CLOSE queue
;--------------------------------------------------------------------------
Del_Search_Close_List:
       mov   di,Drive_Hdr_Ptr									   ;AN000;
       mov   si,es:[di].Close_Ptr	 ; SI-->first header in the				;AN000;
					 ; in the CLOSE queue
       cmp   si, -1			 ; anything in CLOSE Queue ??				   ;AN000;
       jne   Del_scan_close_list	 ; yes, jump						   ;AN000;
       clc				 ; none, header not found				   ;AN000;
       jmp   delete_exit		 ; exit 						   ;AN000;

Del_Scan_Close_List:
       mov   cx,First_Phys_Clusnum	 ; CX = first phys clus number				   ;AN000;
       CALL  FIND_FILE_HEADER		 ; find the header in CLOSE queue			   ;AN000;
												   ;AN000;
       jnc   Del_Close_last_hdr 	 ; if found, chk if this header 			   ;AN000;
					 ; is the last header in CLOSE queue
       clc				 ; else, set header not found				   ;AN000;
       jmp   delete_exit		 ; and then exit					   ;AN000;


;-------------------------------------------------------------------------
; Header found in CLOSE queue. Check header found is the only single
; header left in the queue.
;-------------------------------------------------------------------------
Del_Close_Last_Hdr:
       cmp   Hdr_Flag, 1		 ; Single Header in CLOSE Queue ??			   ;AN000;
       jne   Del_Chk_LRU_Hdr		 ; no, check for LRU header				   ;AN000;

;--------------------------------------------------------------------------
; Yes, single header in the queue, make CLOSE_PTR empty before delete the
; header from the queue.
;--------------------------------------------------------------------------
       mov  di,Drive_Hdr_Ptr									   ;AN000;
       mov  es:[di].Close_Ptr, -1	 ; mark CLOSE_Ptr as empty				   ;AN000;
       jmp  short delete_Free_Buff	 ; release the deleted header				   ;AN000;

Del_Chk_LRU_Hdr:
       cmp   Hdr_Flag, 3		 ; Last Header in the CLOSE Queue ??			   ;AN000;
       jne   Del_Join_Hdr		 ; no, close gap					   ;AN000;
       mov   si,Prev_Hdr_Ptr		 ; make the previous header LRU Hdr			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr, -1    ; mark previous hdr 				   ;AN000;
       jmp   short delete_Free_Buff	 ; release the deleted header				   ;AN000;

;--------------------------------------------------------------------------
; Connect previous header to next header to close the gap in CLOSE Queue
;--------------------------------------------------------------------------
Del_Join_Hdr:
       mov   Queue_Type, 1		 ; set flag to indicate CLOSE Queue			   ;AN000;
       CALL  JOIN_PREV_TO_NEXT		 ; close gap						   ;AN000;
												   ;AN000;
       jmp   short Delete_Free_Buff	 ; release header to FREE area				   ;AN000;



;-------------------------------------------------------------------------
; Header found in OPEN queue. Check header found is the only single
; header left in the queue.
;-------------------------------------------------------------------------
Del_Open_Last_Hdr:
       cmp   Hdr_Flag, 1		 ; Single Header in OPEN Queue??			   ;AN000;
       jne   Del_Chk_Opn_LRU_Hdr	 ; no, check for LRU header				   ;AN000;

;--------------------------------------------------------------------------
; Yes, single header in the queue, mark OPEN Queue  empty before delete
;--------------------------------------------------------------------------
; the header from the queue.
       mov  di,Drive_Hdr_Ptr									   ;AN000;
       mov  es:[di].MRU_Hdr_Ptr, -1	 ; mark OPEN Queue as empty				   ;AN000;
       jmp  short delete_Free_Buff	 ; release the delete header				   ;AN000;

Del_Chk_OPN_LRU_Hdr:
       cmp   Hdr_Flag, 3		 ; Last Header in the CLOSE Queue ??			   ;AN000;
       jne   Del_Opn_Join_Hdr		 ; no, close gap					   ;AN000;
       mov   si,Prev_Hdr_Ptr		 ; make the previous header LRU Hdr			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr, -1    ; mark previous hdr 				   ;AN000;
       jmp   short Delete_Free_Buff	 ; release header to FREE area				   ;AN000;

;--------------------------------------------------------------------------
; Connect previous header to next header to close the gap in OPEN queue
;--------------------------------------------------------------------------
Del_Opn_Join_Hdr:
       mov   Queue_Type, 0		 ; set flag to indicate OPEN Queue			   ;AN000;
       CALL  JOIN_PREV_TO_NEXT		 ; close gap						   ;AN000;
												   ;AN000;

;----------------------------------------------------------------------------
; Header and extends found.  Mark the beginning of this free area with "-2".
; Connect this header to the FREE area. Mark all extnts under this header
; and chain them together through the 4th word. Connect the last extent to
; the OLD free area. This process will effectively release the header to the
; FREE area.  Finally update the FREE area size in the Drive header.
;
; NOTE:  The deleted buffers have size same as the size of a header or extent.
;	 Each buffers first location contains a marker (-2) to indicate that
;	 the buffer is a discontinuous buffer.	Each discontinuos buffer is
;	 connected to the next discontinuous buffer through the 4TH word.
;---------------------------------------------------------------------------

Delete_Free_buff:
       mov   di,Drive_Hdr_Ptr		 ; SI-->drive header					;AN000;
       mov   si,Cur_Hdr_Ptr		 ; DI-->current header					;AN000;

;-------------------------------------------------------------------------
; Put (-2) in the beginning of the released area to indicate that this is
; a discontinuous free area. Each Free area is 8 bytes which is same size
; as an extent or header.
;-------------------------------------------------------------------------
       mov   ax,-2										   ;AN000;
       mov   es:[si], ax									   ;AN000;
       cmp   es:[si].FH_Next_Extn_Ptr, -1   ; any extents under this header ??			   ;AN000;
       jne   del_look_extent		 ; yes, jump						   ;AN000;

;-------------------------------------------------------------------------
; There is no extents under this header.  Connect relased header to the
; Free area and update Free area size in drive header before exit.
;-------------------------------------------------------------------------
       mov   si,Cur_Hdr_Ptr		 ; SI-->Current Header					;AN000;
       mov   di,Drive_Hdr_Ptr		 ; DI-->Drive Header					;AN000;
       mov   ax,es:[di].Free_Ptr	    ; connect current header				   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr, ax    ; to the Free AREA					   ;AN000;
       mov   es:[di].Free_Ptr,si								   ;AN000;
       mov   cx, SIZE File_Header	 ; start with file header size				   ;AN000;
       mov   di,Drive_Hdr_Ptr									   ;AN000;
       add   es:[di].Free_Size,cx	    ; update free area size				   ;AN000;
       clc				    ; make sure caary is clear
       jmp   short Delete_Exit		    ; Then exit 					      ;AN000;


;-------------------------------------------------------------------------
; Yes, one or more extents under this header.  Connect the header to the
; the first extent through 4th word (FH_Next_Hdr_Ptr). Subsequent free
; extents are connected through the 4th word (EH_Next_Extn_Ptr). Next calculate
; the size of the header and possible extendta and update the free area
; size in the drive header.
;-------------------------------------------------------------------------
Del_Look_Extent:
       mov   si,Cur_Hdr_Ptr		    ; SI-->Current Header				      ;AN000;
       mov   ax, -2			    ; mark header as discontinuous			       ;AN000;
       mov   es:[si],ax 		    ; free area  (12/28)				   ;AN000;
       mov   cx, SIZE File_Header	    ; start with file header size			   ;AN000;

       mov   ax,es:[si].FH_Next_Extn_Ptr    ; AX-->first extent under this hdr			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax     ; connect this header to first extnt		    ;AN000;
					    ; through the 4th word				   ;AN000;
       mov   si,ax			    ; SI-->First extent 				   ;AN000;
       mov   ax, -2			    ; mark first extent as discontinous 		   ;AN000;
       mov   es:[si],ax 		    ; free area 					   ;AN000;

Delete_Loop:
       add   cx, SIZE Extent_Header	    ; add size of extent				   ;AN000;
       cmp   es:[si].EH_Next_Extn_Ptr, -1   ; current extent last extent ?					  ;AN000;
       je    Del_Update_Free_Size	    ; yes - jump  (12/28)				    ;AN000;
       mov   ax,es:[si].EH_Next_Extn_Ptr    ; get pointer to next extent			   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax     ; connect curr ext to next extent			   ;AN000;
       mov   si,ax			    ; SI-->next extent							     ;AN000;
       mov   ax, -2			    ; mark subsequent extents as			   ;AN000;
       mov   es:[si],ax 		    ; discontinuous free areas				   ;AN000;
       jmp   Delete_Loop		    ; adding the size until last extent 		   ;AN000;

Del_Update_Free_Size:
       mov   di,Drive_Hdr_Ptr									   ;AN000;
       add   es:[di].Free_Size,cx	    ; update free area in drive header			   ;AN000;
												   ;AN000;
; At this point SI-->Last extent
       mov   di,Drive_Hdr_Ptr		    ; DI-->drive header 				;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax     ; connect last extent under this			   ;AN000;
					    ; header to the Free area
       mov   ax,Cur_Hdr_Ptr		    ; AX-->Current header							;AN000;
       mov   es:[di].Free_Ptr,ax	    ; connect header being deleted to			   ;AN000;
					    ; the free pool				     ;AN000;
Delete_Exit:
       clc
       cmp    check_flag,0
       jne    open_chk_Que
       clc
       ret
Open_Chk_Que:
       CALL  Check_it
       ret				    ; exit						   ;AN000;

FK_DELETE   ENDP








;--------------------------------------------------------------------------
; PROCEDURE: FK_INSERT
;
; FUNCTION:  Search for a specific  extent  using the starting physical
;	     cluster  number  and  the given  logical  cluster number.
;	     Insert  the given	physical  cluster number in the extent
;	     indexed by the given logical cluster number. If extent is
;	     not found, create a new extent. If free space is not
;	     available, take free space free CLOSE or OPEN Queue.
;
; INPUT    DL = drive number
;	   CX = First Physical Cluster Number of the file
;	   BX = Logical Cluster Number
;	   DI = Physical Cluster Number
;
; OUTPUT:  Physical cluster number is inserted.  If extent is not found,
;	   a new file is created
;
; ROUTINES REFERENCED:	Find_File_Header,  Find_Extent, Find_LRU_Header
;
; REVISION HISTORY:  New  (5/87)
;
;------------------------------------------------------------------------

FK_INSERT   PROC   FAR
	push   cs			    ; Establish addressability				     ;AN000;
	pop    ds			    ; DS --> code segment				     ;AN000;
	assume ds:Cseg_Seek									   ;AN000;
	mov    es, Seek_Name_Cache_Seg	    ; setup cache buff segment register 		     ;AN000;
	assume es:Cseg_Init		    ; ES --> cache buffer segment			     ;AN000;

	mov   first_phys_clusNum,cx	    ; save cluster numbers				     ;AN000;
	mov   Logical_ClusNum,bx								   ;AN000;
	mov   Physical_ClusNum,di								   ;AN000;
	mov    func_cod,al

; Search for Drive Cache buffer using Drive ID in DL
       CALL   FIND_DRIVE_HEADER 	    ; get drive buffer					      ;AN000;
       jnc    Insert_Search_Hdr 	    ; found, search for file header			      ;AN000;
       jmp    Insert_Exit		    ; not found, error					      ;AN000;

;--------------------------------------------------------------------------
; If there are no free buffers and there is only a single header in the
; OPEN queue then there is no headers in the CLOSE queue, then the new
; clusters wont be insterted. This is because, file header should not consume
; its own extent if no free space is available.
;--------------------------------------------------------------------------
Insert_Search_Hdr:
       inc    es:[di].Extent_Count	    ; increment sequence count (DEBUGGING)
       mov   si,es:[di].MRU_Hdr_Ptr	    ; SI-->first header in OPEN queue		     ;AN000;
       cmp   es:[si].FH_Next_Hdr_Ptr, -1    ; only one header in OPEN queue??
       je    insert_chk_buff		    ; yes - check free buffer
       jmp   short insert_Inc_count	    ; no - go and insert clusters

Insert_Chk_Buff:
       cmp   es:[di].Free_Size, 0	    ; any free buffers ??
       jne   Insert_Inc_Count		    ; yes - go insert clusters
       cmp   es:[di].Close_Ptr, -1	    ; any headers in close queue?? (1/7/88   ;AN000;
       jne   Insert_Inc_Count		    ; yes - go insert clusters
       clc				    ; no - dont insert clusters
       jmp   Insert_Exit		    ; exit

insert_Inc_Count:
       mov   si,es:[di].MRU_Hdr_Ptr	    ; SI-->first header in the OPEN queue			  ;AN000;
       mov   cx,first_phys_clusnum	    ; CX = physical cluster number			      ;AN000;
       CALL  FIND_FILE_HEADER		    ; find the header in OPEN queue			      ;AN000;
					    ; DI-->Header
       jc    Insert_Make_Hdr		    ; header not found, make new header 		      ;AN000;
       jmp   Insert_Find_extent 	    ; header is found, now go and			      ;AN000;
					    ; search for the extent

;--------------------------------------------------------------------------
; If header not found, create a new header in the free area and connect it
; to the top of the OPEN queue.  Mark the new header with no extents. Insert
; the first logical and physical cluster number into the header.  At this
; point CX=First Physical Cluster number.
;--------------------------------------------------------------------------
Insert_Make_Hdr:
       CALL  MAKE_NEW_HEADER		    ; make a new header at the top			      ;AN000;
					    ; top of the queue
;--------------------------------------------------------------------------
; Now the header is created, next create an extent and put both logical and
; physical cluster number in the extent. The new extent should be
; created at the bottom end of the current queue, except if AX =3,
; then the new extent will be created between current and previous extent.
; Use Find_Free_Buffer to check the free space.
;--------------------------------------------------------------------------
       CALL  FIND_FREE_BUFFER		    ; get free area for new extent			      ;AN000;
       jnc   ins_save_addrs1		    ; found, jump					      ;AN000;
       jmp   Insert_Exit		    ; if free area found is its own			      ;AN000;
					    ; header, exit
Ins_Save_Addrs1:
       mov   di,Drive_Hdr_Ptr		    ; DI-->Drive header 				      ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Extn_Ptr,ax		    ; save new extent address				      ;AN000;
       CALL  UPDATE_FREE_AREA		    ; update Free area					      ;AN000;

       mov   di,Drive_Hdr_Ptr		    ; DI-->Drive header 				      ;AN000;
       mov   ax,New_Extn_Ptr		    ; beginning of new extent				      ;AN000;
       mov   si,Cur_Hdr_Ptr		    ; SI-->Current header				      ;AN000;
       mov   es:[si].FH_Next_Extn_Ptr,ax    ; connect current header to adj CHAIN		   ;AN000;
       mov   es:[si].FH_MRU_EXTN_Ptr,ax     ; connect current header to LRU chain		   ;AN000;
       mov   si,New_Extn_Ptr		    ; SI-->New extent
       mov   bx,Logical_ClusNum 								   ;AN000;
       mov   es:[si].EH_Logic_Clus_Num,bx   ; insert logical  clus num					   ;AN000;
       mov   cx,Physical_ClusNum								   ;AN000;
       mov   es:[si].EH_Phys_Clus_Num,cx    ; insert physical clus num			      ;AN000;
       mov   es:[si].EH_Count,0 	    ; set initial count = 0							;AN000;

;--------------------------------------------------------------------------
; Make new extent LRU extent
;--------------------------------------------------------------------------
       mov   es:[si].EH_Next_Extn_Ptr, -1   ; mark no next extent in sorted chain
       mov   es:[si].EH_Prev_Extn_Ptr, -1   ; mark no previous extent in sorted chain		  ;AN000;
       mov   es:[si].EH_Next_LRU_Ptr, -1    ; mark no next extent in MRU-LRU chain		   ;AN000;
       mov   es:[si].EH_Prev_LRU_Ptr, -1    ; mark no previous extent in MRU-LRU chain
       clc				    ;
       jmp   Insert_Exit		    ; exit			      ;AN000;

;--------------------------------------------------------------------------
; Header found, Check to see any extent under this header.  If not create
; new extent. If there are extents, search for the relative position of the
; given cluster number among the extents under current header.
;--------------------------------------------------------------------------
Insert_Find_Extent:
       mov  di,Cur_Hdr_Ptr		    ; DI-->Current header
       mov  si,es:[di].FH_Next_Extn_Ptr     ; SI-->first extent under current hdr			   ;AN000;
       cmp  si,-1			    ; any extent under this header ?			      ;AN000;
       jne  Find_relative_location	    ; yes, Find relative location of the
					    ; given cluster numbers				      ;AN000;

; Else create new  extent under the current header.
       CALL  FIND_FREE_BUFFER		    ; get free area for new extent			      ;AN000;
       jnc   ins_save_addrs2		    ; found, jump					      ;AN000;
       jmp   Insert_Exit		    ; else free area found is its own			      ;AN000;
					    ; header, *** ERROR **** exit
Ins_save_addrs2:
       mov   di,Drive_Hdr_Ptr		    ; DI-->Drive header 				      ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Extn_Ptr,ax		    ; save new extent address				      ;AN000;

       CALL  UPDATE_FREE_AREA		    ; update Free area pointers 			      ;AN000;

       mov   di,Drive_Hdr_Ptr		    ; DI-->Drive header pointer 			      ;AN000;
       mov   ax,New_Extn_Ptr									   ;AN000;
       mov   si,Cur_Hdr_Ptr		    ; SI-->Current header				      ;AN000;
       mov   es:[si].FH_Next_Extn_Ptr,ax    ; connect  new extent to header			  ;AN000;
       mov   es:[si].FH_MRU_EXTN_Ptr,ax
       mov   si,New_Extn_Ptr		    ;### next extent start in the free_ptr			 ;AN000;
       mov   bx,Logical_ClusNum 								   ;AN000;
       mov   es:[si].EH_Logic_Clus_Num,bx   ; insert logical					   ;AN000;
       mov   cx,Physical_ClusNum								   ;AN000;
       mov   es:[si].EH_Phys_Clus_Num,cx    ; insert physical cluster numbe			   ;AN000;
       mov   es:[si].EH_Count,0 	    ;							   ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,-1    ; mark this extent as last extent			   ;AN000;
       mov   es:[si].EH_Next_LRU_Ptr,-1     ; ### mark this extent as last extent		       ;AN000;
       mov   es:[si].EH_Prev_Extn_Ptr,-1    ; mark there is no prev extent			   ;AN000;
       mov   es:[si].EH_Prev_LRU_Ptr,-1     ; mark there is no prev LRU extent
       jmp   Insert_Make_MRU		    ; make current header MRU header			   ;AN000;


;--------------------------------------------------------------------------
; Check if the given cluster number will be continuous to either High or Low
; end of any extent under current header or should create a new extent
; If not, check whether a new extent for the cluster is to be created
; between current and previous extent - Current and next extent or new
; extent at the bottom of the queue.
;--------------------------------------------------------------------------
Find_Relative_Location:
       CALL FIND_CLUSTER_LOCATION	   ; find relative position  of new extent		    ;AN000;
       jnc  chk_continuity		   ; position found			    ;AN000;
       clc				   ; clusters already exist in an extent.
       jmp  Insert_exit 		   ; return to DOS					   ;AN000;

;--------------------------------------------------------------------------
; Extent found.  Check for LOW end contiguous. If true insert in the current
; extent and update the count
;--------------------------------------------------------------------------
Chk_continuity:
       cmp  find_flag,1 		   ; LO end contiguous to current extent?		     ;AN000;
       jne  Insert_chk_HI		   ; no - check high end contiguous						    ;AN000;
       mov  si,Cur_Extn_Ptr		   ; yes - insert and update				    ;AN000;
       mov  cx,Logical_ClusNum		   ; save new logical and pysical			     ;AN000;
       mov  es:[si].EH_Logic_Clus_Num,cx   ; cluster numbers as first clusters			   ;AN000;
       mov  cx,Physical_ClusNum
       mov  es:[si].EH_Phys_Clus_Num,cx 							   ;AN000;
       inc  es:[si].EH_Count		   ; update extent range count				     ;AN000;
       mov  di,Drive_Hdr_Ptr		   ; DI-->drive header
       cmp  es:[di].Free_Ptr,0		   ; any free buffer ??
       je   Chk_low_MRU 		   ; no - make current extent MRU extent
       jmp   Insert_Make_MRU		   ; yes - make current header MRU header			   ;AN000;

Chk_Low_MRU:
       mov   Cur_Extn_Ptr, si
       CALL  Make_MRU_Extent		   ; Move extent next to current header
       jmp   Insert_Make_MRU		   ; Make current header MRU header			     ;AN000;

;--------------------------------------------------------------------------
; Check if clusters are  high end contiguous to current extent.  If true
; increment count and then make the extent MRU extent only if no free
; buffer is available.
;--------------------------------------------------------------------------
Insert_Chk_HI:
       cmp  find_flag,2 		   ; HI end contiguous to current extent?		     ;AN000;
       jne  Insert_chk_between		   ; no, jump						     ;AN000;
       mov  si,Cur_Extn_Ptr		   ; SI-->Current extent				  ;AN000;
       inc  es:[si].EH_Count		   ; increment the cluster range count			     ;AN000;
       mov  di,Drive_Hdr_Ptr		   ; DI-->current drive header
       cmp  es:[di].Free_Ptr,0		   ; any free buffers ??
       je   Chk_Hi_MRU			   ; no - make current extent MRU extent
       jmp   Insert_Make_MRU		   ; yes - current header MRU header			      ;AN000;

Chk_Hi_MRU:
       mov   Cur_Extn_Ptr, si		   ; SI -->extent to be MRU
       CALL  Make_MRU_Extent		   ; move extent next to current header
       jmp   Insert_Make_MRU		   ; Make current header MRU header			     ;AN000;


;--------------------------------------------------------------------------
; Check to see the cluster number belongs to a new extent between current
; and Previous extent or header. If not it belongs to a new extent at the
; bottom end of the queue.
;--------------------------------------------------------------------------
Insert_Chk_Between:
       cmp   find_flag,3		  ; between current and previous exts?? 		    ;AN000;
       je    Connect_prev_next		  ; yes, jump						    ;AN000;

       cmp   find_flag,5		  ; between current and next extents??			    ;AN000;
       jne   Connect_to_end		  ; no, create new extent at bottom			    ;AN000;
					  ; bottom of the queue
       jmp   Connect_cur_next		  ; yes create new extent between			    ;AN000;
					  ; current and next extent

;--------------------------------------------------------------------------
; No, make new extent at the BOTTOM of the queue.
;--------------------------------------------------------------------------
CONNECT_TO_END: 			  ; At this point  SI-->Last extent in queue							      ;AN000;
       CALL  FIND_FREE_BUFFER		  ; Check for free area 				     ;AN000;
       jnc   ins_save_addrs3									   ;AN000;
       jmp   Insert_Exit		  ; if free area found is its own			    ;AN000;
					  ; header, *** ERROR *** exit
Ins_Save_Addrs3:
       mov   di,Drive_Hdr_Ptr									   ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Extn_Ptr,ax		  ; save new extent address				    ;AN000;
       CALL  UPDATE_FREE_AREA		  ; update Free_Ptr and Free_Size			    ;AN000;

       mov   ax,New_Extn_Ptr									   ;AN000;
       mov   di,Cur_Extn_Ptr		  ; SI-->Current extent 				    ;AN000;
       cmp   ax, di			  ; If free area got is  the last
       jne   Use_Cur_Extent		  ; last extent itself then use previous extent
       mov   di, Prev_Extn_Ptr		  ; SI-->Previous extent

Use_Cur_extent:
       mov   es:[di].EH_Next_Extn_Ptr,ax    ; connect new extent to current or previous extent	  ;AN000;
       mov   si,New_Extn_Ptr		    ; next extent start in the free_ptr 		   ;AN000;
       mov   es:[si].EH_Prev_Extn_Ptr, di   ; set previous extent address
       mov   bx,Logical_ClusNum 								   ;AN000;
       mov   es:[si].EH_Logic_Clus_Num,bx   ; insert logical					   ;AN000;
       mov   cx,Physical_ClusNum								   ;AN000;
       mov   es:[si].EH_Phys_Clus_Num,cx    ; insert physical cluster numbe			   ;AN000;
       mov   es:[si].EH_Count,0 	    ; initial cluster range

; Make new extent last extent in the sorted chain
       mov   es:[si].EH_Next_Extn_Ptr, -1   ; mark as Last extent of the queue			   ;AN000;
; make the new extent MRU extent in the MRU_LRU chain
       mov   di,Cur_Hdr_Ptr		    ; DI-->Current header
       mov   ax,es:[di].FH_MRU_Extn_Ptr     ; AX-->Previous MRU extent
       mov   es:[si].EH_NEXT_LRU_Ptr,ax     ; connect previous to  current extent
       mov   es:[si].EH_Prev_LRU_Ptr, -1    ; mark no previous LRU extent			   ;AN000;
       mov   es:[di].FH_MRU_Extn_Ptr,si     ; make current extent MRU extent
       mov   di,ax
       mov   es:[di].EH_Prev_LRU_Ptr,si     ; connect previous to  current extent
       jmp   Insert_Make_MRU		    ; make current header MRU header
												   ;AN000;


;--------------------------------------------------------------------------
; Make new extent between current and previous extents. If no previous extent
; connect the new extent to the current header.
;--------------------------------------------------------------------------
CONNECT_PREV_NEXT:
       CALL  FIND_FREE_BUFFER		 ; get free area for new extent 			   ;AN000;
       jnc   Prev_Next_Update		 ; found, jump						   ;AN000;
       jmp   Insert_Exit		 ; if free area found is its own			   ;AN000;
					 ; header, **ERROR** exit
Prev_Next_Update:
       mov   di,Drive_Hdr_Ptr		 ; DI-->Drive header					   ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Extn_Ptr,ax		 ; save new extent address				   ;AN000;
												   ;AN000;
       CALL  UPDATE_FREE_AREA		 ; update Free_Ptr and Free_Size			   ;AN000;

       mov   di,Drive_Hdr_Ptr		 ; DI-->Drive Header					   ;AN000;
       cmp   Prev_Extn_Ptr, -1		 ; Any previous extents ??				   ;AN000;
       jne   join_to_Prev_Extn		 ; yes - connect new extent to previous 	     ;AN000;
					 ; extent
; No, connect new extent to header
       mov   si,Cur_Hdr_Ptr		 ; SI-->current header					   ;AN000;
       mov   di,New_Extn_Ptr									   ;AN000;
       mov   ax,es:[si].FH_Next_Extn_Ptr ; AX-->first extent under header
       mov   es:[di].EH_Next_Extn_Ptr,ax ; connect new extent to this extent
       mov   es:[si].FH_Next_Extn_Ptr, di    ; connect new extent to cur hdr		   ;AN000;
       mov   es:[di].EH_Prev_Extn_Ptr, -1    ; address of previous extent (-1) since header
       mov   bx,Logical_Clusnum 	    ;							   ;AN000;
       mov   es:[di].EH_Logic_Clus_Num,bx   ; insert logical clus num				 ;AN000;
       mov   cx,Physical_Clusnum								   ;AN000;
       mov   es:[di].EH_Phys_Clus_Num,cx    ; insert physical cluster numbe			   ;AN000;
       mov   es:[di].EH_Count,0 	    ; set count 					   ;AN000;
       mov   si,ax			    ; SI-->previous MRU extent
       mov   es:[si].EH_Prev_Extn_Ptr,di    ; set prev extent of prev MRU extent

; Make the new extent MRU extent
       mov   si,Cur_Hdr_Ptr		    ; SI-->current header				      ;AN000;
       mov   ax,es:[si].FH_MRU_EXTN_Ptr     ; AX-->MRU extent under header
       mov   di,New_Extn_Ptr		    ; SI-->current header				      ;AN000;
       mov   es:[di].EH_Next_LRU_Ptr,ax     ; connect new extent to current extent
       mov   es:[di].EH_Prev_LRU_Ptr, -1    ; mark no previous LRU extent			   ;AN000;
       mov   es:[si].FH_MRU_Extn_Ptr,di     ; connect new extent to header
       mov   si,ax
       mov   es:[si].EH_Prev_LRU_Ptr,di     ; connect previous to  current extent
       Jmp   Insert_Make_MRU		    ; make current header MRU hdr			   ;AN000;

; Connect new extent to previous extent
Join_To_Prev_Extn:
       mov   si,New_Extn_Ptr		    ; SI-->New extent, connect new to			   ;AN000;
       mov   ax,Cur_Extn_Ptr		    ; connect previous extent				      ;AN000;
       cmp   si,ax			    ; new extent is created from
       je    join_set_adj		    ; current extent ??

       mov   si,Prev_Extn_Ptr		    ; no - SI-->Previous extent 				   ;AN000;
       mov   ax,New_Extn_Ptr		    ; connect new extent to		     ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,ax    ; previous extent					   ;AN000;
       mov   ax,Cur_Extn_Ptr
       jmp   short Join_Set_Next	    ; current extent

Join_set_adj:				    ; yes -
       mov   si,Prev_Extn_Ptr		    ; no - SI-->Previous extent 				   ;AN000;
       mov   bx,es:[si].EH_Next_Extn_Ptr    ; get next extent address
       mov   ax,New_Extn_Ptr		    ; connect new extent to		     ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,ax    ; previous extent					   ;AN000;
       mov   ax, bx			    ; extent to next extent
       mov   Cur_Extn_Ptr,bx		    ; change current extent

Join_set_Next:				    ; from current extent
       mov   si,New_Extn_Ptr		    ; SI-->New extent, connect new to			   ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,ax    ; current extent					   ;AN000;
       mov   bx,Logical_Clusnum 	    ; then save cluster numbers 			   ;AN000;
       mov   es:[si].EH_Logic_Clus_Num,bx   ; insert logical					   ;AN000;
       mov   cx,Physical_Clusnum								   ;AN000;
       mov   es:[si].EH_Phys_Clus_Num,cx    ; insert physical cluster numbe			   ;AN000;
       mov   es:[si].EH_Count,0 	    ;							   ;AN000;
       mov   ax, Prev_Extn_Ptr
       mov   es:[si].EH_Prev_Extn_Ptr,ax    ; connect previous to  current extent
       mov   di, Cur_Extn_Ptr		    ; setup previous extent link of
       mov   es:[di].EH_Prev_Extn_Ptr,si    ; current extent

; Make the new extent MRU extent
       mov   si,Cur_Hdr_Ptr		    ; SI-->current header				      ;AN000;
       mov   ax,es:[si].FH_MRU_EXTN_Ptr     ; AX-->MRU extent under header
       mov   di,New_Extn_Ptr		    ; SI-->current header				      ;AN000;
       mov   es:[di].EH_Next_LRU_Ptr,ax     ; connect new extent to current extent
       mov   es:[di].EH_Prev_LRU_Ptr, -1    ; mark no previous LRU extent			   ;AN000;
       mov   es:[si].FH_MRU_Extn_Ptr,di     ; connect new extent to header
       mov   si,ax
       mov   es:[si].EH_Prev_LRU_Ptr,di     ; connect previous to  current extent
       Jmp   short Insert_Make_MRU	    ; make current header MRU hdr			   ;AN000;



;--------------------------------------------------------------------------
; Make new extent between current and next extents. If no next extent
; connect the new extent to the end of queue.
;--------------------------------------------------------------------------
CONNECT_CUR_NEXT:
       mov   si,Cur_Extn_Ptr		 ; current extent					   ;AN000;
       cmp   es:[si].EH_Next_Extn_Ptr,-1    ; any next extent ??				   ;AN000;
       jne   join_to_next_extn		 ; yes, join to next extent				   ;AN000;
       jmp   Connect_To_End		 ; make new extent at the bottom of			   ;AN000;
					 ; the current queue
Join_To_Next_Extn:
       CALL  FIND_FREE_BUFFER		 ; Find free area					   ;AN000;
       jc    Insert_Exit		 ; if free area found is its own			   ;AN000;
					 ; header, exit
       mov   di,Drive_Hdr_Ptr									   ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Extn_Ptr,ax		 ; save new extent address				   ;AN000;

       CALL  UPDATE_FREE_AREA		 ; update Free_Ptr and Free_Size			   ;AN000;
												   ;AN000;
       mov   si,Cur_Extn_Ptr		 ; SI-->Current extent
       mov   DX,es:[si].EH_Next_Extn_Ptr    ; DI-->Next extent					   ;AN000;
       mov   ax,New_Extn_Ptr									   ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,ax    ;connect new extent to cur extent			   ;AN000;

       mov   si,New_Extn_Ptr		    ; SI-->New extent, connect new ext			   ;AN000;;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,DX    ; to next  extent					   ;AN000;
       mov   ax, Cur_Extn_Ptr		    ; AX = address of current extent
       mov   es:[si].EH_Prev_Extn_Ptr, ax   ; save address of previous extent
       mov   bx,Logical_Clusnum 	    ; then save cluster numbers 			   ;AN000;
       mov   es:[si].EH_Logic_Clus_Num,bx   ; insert logical					   ;AN000;
       mov   cx,Physical_Clusnum								   ;AN000;
       mov   es:[si].EH_Phys_Clus_Num,cx    ; insert physical cluster numbe			   ;AN000;
       mov   es:[si].EH_Count,0 	    ; set cluster range 				   ;AN000;
       mov   di,DX			    ; setup prev extent link of the
       mov   es:[di].EH_Prev_Extn_Ptr,si    ; next extent

; Make the new extent MRU extent
       mov   si,Cur_Hdr_Ptr		    ; SI-->current header				      ;AN000;
       mov   ax,es:[si].FH_MRU_EXTN_Ptr     ; AX-->MRU extent under header
       mov   di,New_Extn_Ptr		    ; SI-->current header				      ;AN000;
       mov   es:[di].EH_Next_LRU_Ptr,ax     ; connect new extent to current extent
       mov   es:[di].EH_Prev_LRU_Ptr, -1    ; mark no previous LRU extent			   ;AN000;
       mov   es:[si].FH_MRU_Extn_Ptr,di     ; connect new extent to header
       mov   si,ax
       mov   es:[si].EH_Prev_LRU_Ptr,di     ; connect previous to  current extent


;--------------------------------------------------------------------------
; Make the Current header MRU header. If the header is MRU header, then
; dont make the header MRU header.
;--------------------------------------------------------------------------
Insert_Make_MRU:
       cmp   Prev_Hdr_Ptr, -1		    ; first header ??					      ;AN000;
       jne   Ins_mru_hdr		    ; no, make MRU header				      ;AN000;
       clc				    ; make sure caary is clear
       jmp   short insert_exit		    ; yes, exit 					      ;AN000;

Ins_MRU_Hdr:
       CALL  MAKE_MRU_HEADER		    ; move header to top of OPEN Queue			      ;AN000;
       clc				    ; make sure caary is clear

Insert_exit:
       CALL  Check_it			    ; analyse the queue (debugging)
       ret				    ; EXIT						   ;AN000;

FK_INSERT   ENDP








;-------------------------------------------------------------------------
; PROCEDURE: FK_LOOKUP
;
; FUNCTION:  Search through the OPEN Queue for a specific Header and
;	     extent.  If header is not found, create a new header and
;	     make it MRU header.  Else search for a specific extent which
;	     contains the logical cluster number.  If the extent is not
;	     found, return partial information from previous extent or
;	     header.  If extent is found, return physical cluster number
;	     corresponds to the given logical cluster number.
;
; INPUT:     DL = drive number
;	     CX = First Physical Cluster Number of the file
;	     BX = Logical Cluster NUmber
;
; OUTPUT:    If Carry = 0   Fully Found
;	       DI = Physical Cluster Number indexed by es:[BX]
;	       BX = Physical Cluster Number indexed by es:[BX-1]
;
;	     If Carry = 1   Partially Found
;	       BX = Last logical cluster number in previous extent
;	       DI = Last Physical Cluster Number indexed by es:[Last logic clus]
;
;	     If header not found, a new header will be created.  In this case
;	       BX = First Logical Cluster number (0)
;	       DI = First Physical Cluster number of the header created
;
; NOTE:     The clusters are fully found if the logical cluster has
;	    continuity to the previous logical cluster in the same
;	    extent or previous extent or previous header.
;
; ROUTINES REFERENCED: Find_File_Header, Find_Extent, Find_Drive_Header
;
; REVISION HISTORY:  New  (5/87)
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;---------------------------------------------------------------

FK_LOOKUP   PROC   FAR		   ; on entry DS = seg ID of INIT

       push   cs			 ; establish addressability				   ;AN000;
       pop    ds			 ; DS --> code segment					   ;AN000;
       assume ds:Cseg_Seek									   ;AN000;
       mov    es, Seek_Name_Cache_Seg	 ; setup cache buff segment register			   ;AN000;
       assume es:Cseg_Init		 ; ES --> cache buffer segment				   ;AN000;
       mov    First_Phys_Clusnum,cx	 ; save phys cluster number				   ;AN000;
       mov    Logical_ClusNum,bx
       mov    func_cod,al

;--------------------------------------------------------------------------
; Search for Drive header in the Cache buffer using Drive ID in DL
;--------------------------------------------------------------------------
       CALL   FIND_DRIVE_HEADER 	 ; Search for drive header				   ;AN000;
       jnc    Look_search_hdr		 ; found, search for file header			   ;AN000;
       jmp    Look_Exit 		 ; not found, error					   ;AN000;

;--------------------------------------------------------------------------
; Search for a header in the OPEN  Queue using given physical cluster number
;--------------------------------------------------------------------------
Look_Search_Hdr:
       inc    es:[di].Extent_Count	 ; ;***;
       mov   si,es:[di].MRU_Hdr_Ptr	 ; SI-->first header in the				;AN000;
					 ; in the OPEN Queue
       mov   cx,First_Phys_Clusnum	 ; CX = Physical Cluster number 			   ;AN000;
       CALL  FIND_FILE_HEADER		 ; find the header in CLOSE Queue
												   ;AN000;
       jnc   Look_Find_extent		 ; if found, find extent under this header
					 ; else create a new header				   ;AN000;
;--------------------------------------------------------------------------
; If the header is not found, create a new header at the top of OPEN queue.
; Insert physical cluster number and set next header and first extent pointers
; Return partially found information.
;--------------------------------------------------------------------------
       pushf				 ; save carry set
       CALL  MAKE_NEW_HEADER		 ; Make a new header at the top of the queue		   ;AN000;
       xor   bx,bx			 ; BX = First Logical cluster number		   ;AN000;
       mov   di, First_Phys_Clusnum	 ; DI = First physical cluster number
       popf				 ; carry should be set
       jmp   Look_exit			 ; exit 						   ;AN000;


;--------------------------------------------------------------------------
; If the header is found, next search for the extent that contains the
; logical and physical cluster numbers. DI--> current header
;--------------------------------------------------------------------------
Look_Find_Extent:
       cmp   es:[di].FH_Next_Extn_Ptr,-1 ; any extent under this header ??			   ;AN000;
       jne   look_search_extent 	 ; yes, search for right extent 			   ;AN000;

       xor   bx,bx			 ; no, return partial info from header			   ;AN000;
       mov   di,es:[di].FH_Phys_Clus_Num ; DI = first phys clus num				   ;AN000;
       push  di 			 ;							   ;AN000;
       push  bx 			 ; BX = 1st logc clus num = 0				   ;AN000;
       mov   fully_flag, 0		 ; set partially found flag				   ;AN000;
       jmp   look_make_MRU_hdr		 ; move header to top of the OPEN queue 		   ;AN000;


;--------------------------------------------------------------------------
; Search for cluster numbers in extents starting from 1st extent.
;--------------------------------------------------------------------------
Look_Search_Extent:
       mov   si,es:[di].FH_Next_Extn_Ptr    ; SI-->first extent under curr hdr			   ;AN000;
       mov   Cur_Extn_Ptr,si		    ; save it						   ;AN000;
       mov   cx,Logical_ClusNum 	    ; CX = logic clus num to search for 		   ;AN000;
       mov   Prev_Extn_Ptr, -1		    ; reset flags					   ;AN000;
       mov   Extn_Flag, 0		    ;							   ;AN000;
       cmp   cx,es:[si].EH_Logic_Clus_Num   ; 1st logic clus num in the 			   ;AN000;
       jl    Look_proc_less

Look_Loop1:
       cmp   cx,es:[si].EH_Logic_Clus_Num   ; 1st logic clus num in the 			   ;AN000;
					    ; current extent matches ??
       je    Look_Proc_First		    ; yes, process 1st extent case			   ;AN000;
       mov   ax,es:[si].EH_Logic_Clus_Num   ; else check subsequent extents
       add   ax,es:[si].EH_Count	    ; last logic clus num in cur extent 		   ;AN000;
       cmp   cx,ax			    ; extent found in the cur extent ??
       jg    Look_Next_Extn		    ; no,try next extent				   ;AN000;;AN000;;AN000;
       jmp   Look_Extn_within		    ; yes, process current extent			   ;AN000;

Look_Next_Extn: 			    ;
       mov   ax,es:[si].EH_Next_Extn_ptr    ; get address of next extent			   ;AN000;
       cmp   ax,-1			    ; is this last extent ??				   ;AN000;
       je    Look_last_done		    ; yes, get partial					   ;AN000;

       mov   Prev_Extn_Ptr,si		    ; save previous extent address			   ;AN000;
       mov   si,ax										   ;AN000;
       mov   Cur_Extn_Ptr,si		    ; save current extent address			   ;AN000;
       cmp   cx,es:[si].EH_Logic_Clus_Num   ; logic clus num in cur extent ??			   ;AN000;
       jge   Look_Loop1 		    ; may be!!, check it out				   ;AN000;

       jmp   Look_Proc_Prev		    ; else get partial info from			   ;AN000;
					    ; previous extent
;-------------------------------------------------------------------------
; There are no further extents.  In this case partially found. Return last
; logical and physical clusters of the last extent.
;-------------------------------------------------------------------------
Look_Last_Done:
      mov   si,Cur_Extn_Ptr	       ; SI-->Previous extent					   ;AN000;
      mov   bx,es:[si].EH_Logic_Clus_Num  ; DI = first logic clus num ofprevext 		   ;AN000;
      mov   di,es:[si].EH_Phys_Clus_Num   ; BX = first logic clus num ofprevext 		   ;AN000;
      add   di,es:[si].EH_Count        ; DI = last phys clus number in extent			   ;AN000;
      add   bx,es:[si].EH_Count        ; BX = last logic clus number in extent			   ;AN000;
      push  di			       ; last logical cluster number				   ;AN000;;AN000;
      push  bx			       ; last physical cluster number				   ;AN000;
      mov   fully_flag,0	       ; partially found case					   ;AN000;
      jmp   Look_Make_MRU_Hdr	       ; make current header MRU header 			   ;AN000;



;--------------------------------------------------------------------------
; Less than starting logical cluster of first extent.  In this case return
; header info as partially found.
;--------------------------------------------------------------------------
Look_Proc_Less:
      xor   bx,bx		       ; BX = logical cluster number = 0			   ;AN000;
      mov   ax,es:[di].FH_Phys_Clus_Num 							   ;AN000;
      push  ax			       ; first phys clus of current hdr 			   ;AN000;
      push  bx			       ; first logic clus (0) of cur hdr			   ;AN000;
      mov   fully_flag,0	       ; partially found case					   ;AN000;
      jmp   Look_Make_MRU_Hdr	       ; make current header MRU header 			   ;AN000;



;--------------------------------------------------------------------------
; If first logical cluster number of the current extent matches with the given
; logical cluster number, see if previous logical cluster in previous header
; or extent is contiguous. If true, fully found. I this case return
; BX = first physical cluster of cuurent extent and DI = first physical
; cluster number of header if it is a header or last physical cluster number
; of previous extent.  If this is not true, partially found case. In this case,
; return BX = last logical cluster number  and DI = last physical cluster number
; from the previous extent.  If no previous extent, then return DI = first
; physical cluster and BX = 0  from the header
;
; NOTE:     The clusters are fully found if the logical cluster has
;	    continuity to the previous logical cluster in the same
;	    extent or previous extent or previous header.
;--------------------------------------------------------------------------
Look_Proc_First:
      mov   si,Cur_Extn_Ptr	       ; SI-->current extent					   ;AN000;
      mov   di,Cur_Hdr_Ptr	       ; DI-->current header					   ;AN000;
      cmp   Prev_Extn_Ptr, -1	       ; any previous extent ?? 				   ;AN000;
      jne   look_get_prev_extent       ; yes, get from previous extent				   ;AN000;

;--------------------------------------------------------------------------
; No, look for current header logical cluster number continuity
;--------------------------------------------------------------------------
      mov   ax,es:[si].EH_Logic_Clus_Num   ; AX = First physical cluster number 		   ;AN000;
      dec   ax				   ; of current extent					   ;AN000;
      cmp   ax,0		       ; continuity to first logical clus num			   ;AN000;
				       ; of current header which is (0)
      jne   Look_first_partial	       ; no, partially found					   ;AN000;


; Yes, fully found
      mov   bx,es:[si].EH_Phys_Clus_Num   ; BX = First physical cluster number			   ;AN000;
					  ; current extent
      mov   ax,es:[di].FH_Phys_Clus_Num   ; AX = First physical cluster number			   ;AN000;
					  ; of current header
      push  bx			       ; BX = 1st phys clus of current extent			   ;AN000;
      push  ax			       ; AX = 1st phys clus of prev header			   ;AN000;
      mov   fully_flag,1	       ; FULLY found case					   ;AN000;
      jmp   Look_Make_MRU_Hdr	       ; mov cur header to top of the Queue			   ;AN000;


Look_First_Partial:
      xor   bx,bx		       ; BX = logical cluster number = 0			   ;AN000;
      mov   ax,es:[di].FH_Phys_Clus_Num 							   ;AN000;
      push  ax			       ; first phys clus of current hdr 			   ;AN000;
      push  bx			       ; first logic clus (0) of cur hdr			   ;AN000;
      mov   fully_flag,0	       ; partially found case					   ;AN000;
      jmp   short Look_Make_MRU_Hdr    ; make current header MRU header 			   ;AN000;


;--------------------------------------------------------------------------
; Get last physical and logical cluster number of the previous extent
;--------------------------------------------------------------------------
Look_Get_Prev_Extent:
      mov   di,Prev_Extn_Ptr	       ; DI-->Previous extent					   ;AN000;
      mov   ax,es:[si].EH_Logic_Clus_Num   ; AX = First logical cluster number			   ;AN000;
      dec   ax				   ; of current extent					   ;AN000;
      mov   bx,es:[di].EH_Logic_Clus_Num  ; continuity to last logical clus num 		   ;AN000;
      add   bx,es:[di].EH_Count 	  ; of previous extent ??				   ;AN000;
      cmp   ax,bx										   ;AN000;
      jne   Look_first_partial2 	  ; no, partially found 				      ;AN000;

; Fully found case
      mov   bx,es:[si].EH_Phys_Clus_Num   ; BX = First physical cluster number			   ;AN000;
      mov   ax,es:[di].EH_Phys_Clus_Num   ; AX = Last physical cluster number			   ;AN000;
      add   ax,es:[di].EH_Count 	  ; from previous extent				   ;AN000;
      push  bx				  ; BX = 1st phys clus num from cur extn		      ;AN000;
      push  ax				  ; AX = last phys clus num from prev extn		      ;AN000;
      mov   fully_flag,1		  ; FULLY found case					      ;AN000;
      jmp   short Look_Make_MRU_Hdr	  ; mov current header to top of OPEN que		      ;AN000;


Look_First_Partial2:
      mov   bx,es:[di].EH_Logic_Clus_Num  ; BX = First Logical cluster number			   ;AN000;
					  ; of current extent
      add   bx,es:[di].EH_Count 	  ; BX = Last Logic clus from prev extn 		   ;AN000;
      mov   ax,es:[di].EH_Phys_Clus_Num   ; AX = First physical cluster number			   ;AN000;
					  ; of previous extent
      add   ax,es:[di].EH_Count 	  ; last phys clus num of prev extent			   ;AN000;
      push  ax				  ;  AX = last phys clus of prev extent 		      ;AN000;
      push  bx				  ;  BX = last logic clus of prev extent		      ;AN000;
      mov   fully_flag,0		  ; partially found case				      ;AN000;
      jmp   short Look_Make_MRU_Hdr	  ; make current header MRU header			      ;AN000;



;----------------------------------------------------------------------------
; If the given cluster number matches with any logic cluster number starting
; from 2nd and above, then fully found.  Return BX=Phys clus num[log_clusnum]
; and DI=Phys clus num[log_clusnum-1]
;----------------------------------------------------------------------------
Look_Extn_Within:
      mov   si,Cur_Extn_Ptr	       ; SI-->Current extent					   ;AN000;
      sub   cx,es:[si].EH_Logic_Clus_Num							   ;AN000;
      mov   di,es:[si].EH_Phys_Clus_Num   ; DI = first phys clus num of 			   ;AN000;
					  ; current extent
      add   di,cx		       ; DI = Phys clus num [logic clus num]			   ;AN000;
      mov   bx,di		       ;							   ;AN000;
      dec   bx			       ; BX = Phys clus num [logic clus num -1] 		   ;AN000;
      push  di			       ; DI = Phys clus num [logic clus num]			   ;AN000;
      push  bx											   ;AN000;
      mov   fully_flag,1	       ; fully found case					   ;AN000;
      jmp   short Look_Make_MRU_Hdr    ; make current header to top of OPEN Que 		   ;AN000;


;--------------------------------------------------------------------------
; Given extent is above the upper limit of the current extent, but lower than the
; next extent.	In this case, cluters are partially found.  Return BX = last
; logical cluster number of the previous extent and DI = last physical cluster
; number of the previous extent.
;----------------------------------------------------------------------------
Look_Proc_Prev:
      mov   si,Prev_Extn_Ptr		  ; SI-->Previous extent				   ;AN000;
      mov   bx,es:[si].EH_Logic_Clus_Num  ; DI = first logic clus num of prev			   ;AN000;
					  ; extent
      mov   di,es:[si].EH_Phys_Clus_Num   ; BX = first phys clus num of prev			   ;AN000;
					  ; extent
      add   di,es:[si].EH_Count 	; DI = last phys clus number in extent			   ;AN000;
      add   bx,es:[si].EH_Count 	; BX = last logic clus number in extent
      push  di				; save clusters to return				   ;AN000;
      push  bx											   ;AN000;
      mov   fully_flag,0		; partially found case					   ;AN000;

;----------------------------------------------------------------------------
; Move the current header to the top of the OPEN queue
;----------------------------------------------------------------------------
Look_Make_MRU_Hdr:
       cmp   Prev_Hdr_Ptr,-1		; first header in the Queue ??				   ;AN000;
       je    Look_Dont_Move_To_Top	; yes, dont move to top 				  ;AN000;

       CALL   MAKE_MRU_HEADER									   ;AN000;

Look_Dont_Move_To_Top:
       cmp  fully_flag, 0		; fully found ??					   ;AN000;
       je   Look_set_carry		; no, partially found					   ;AN000;
       clc				; fully found						   ;AN000;
       jmp  short Look_Restore		; restore registers							      ;AN000;

Look_Set_Carry:
       stc				; set flag for partially found								 ;AN000;

Look_restore:
       pop  bx				; restore values to be reurned
       pop  di				; to DOS

Look_Exit:
       nop
       CALL   Check_it
       ret				; exit

FK_LOOKUP   endp







;----------------------------------------------------------------
; PROCEDURE: Fk_Truncate
;
; FUNCTION:  Using the given physical and logical clutser numbers,
;	     find the extent which contains the given cluster number.
;	     Delete all clusters folloing the given cluster and the
;	     subsequent extents and free the buffers.
;
; INPUT:   CX = First Physical Cluster Number of the file
;	   BX = Logical Cluster Number
;	   DL = Drive number
;
; OUTPUT:  CY = 0   Extents are truncated
;
;	   CY = 1   Extent no found   DI = 0
;
; ROUTINES REFERENCED:	Find_File_Header, Find_Extent
;
; REVISION HISTORY:  New  (5/87)
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;---------------------------------------------------------------

Fk_TRUNCATE   PROC   FAR

       push   cs			 ; establish addressability				   ;AN000;
       pop    ds			 ; DS --> code segment					   ;AN000;
       assume ds:Cseg_Seek									   ;AN000;
       mov    es, Seek_Name_Cache_Seg	 ; setup cache buff segment register			   ;AN000;
       assume es:Cseg_Init		 ; ES --> cache buffer segment				   ;AN000;
       mov    First_Phys_Clusnum,cx	 ; save phys cluster number				   ;AN000;
       mov    Logical_ClusNum,bx								   ;AN000;
       mov    func_cod,al

;--------------------------------------------------------------------------
; Search for Drive Cache buffer using Drive ID in DL
;--------------------------------------------------------------------------
       CALL   FIND_DRIVE_HEADER 	 ; get drive buffer					   ;AN000;
       jnc    Trunc_search_hdr		 ; if found, search for file header			   ;AN000;
       jmp    Trunc_Exit		 ; if not found, error					   ;AN000;
												   ;AN000;
;--------------------------------------------------------------------------
; Search for a header in the OPEN Queue using given physical clusternum
;--------------------------------------------------------------------------
Trunc_Search_Hdr:
       inc    es:[di].Extent_Count	 ; ;***;
       mov   si,es:[di].MRU_Hdr_Ptr    ; SI-->first header in the				;AN000;
				       ; in the OPEN Queue
       mov   cx,First_Phys_Clusnum     ; CX = Physical Cluster number				   ;AN000;

       CALL  FIND_FILE_HEADER	       ; find file header in OPEN Queue 			   ;AN000;
       jnc   Trunc_Find_extent	       ; if found, get extent					   ;AN000;

;--------------------------------------------------------------------------
; If the header is not found, create a new header and make it as MRU header
; insert first physical cluster number in the header
;--------------------------------------------------------------------------
       CALL  MAKE_NEW_HEADER		; make new header					   ;AN000;
       clc											   ;AN000;
       jmp   Trunc_exit 		; exit							   ;AN000;


;--------------------------------------------------------------------------
; Header is found.  Next search for the extent which contains the
; given logical cluster number.
;--------------------------------------------------------------------------
Trunc_Find_Extent:			;							   ;AN000;
       mov  Cur_Hdr_Ptr,di		; save current pointer					   ;AN000;
       mov  si,es:[di].FH_Next_Extn_Ptr    ; SI-->first extent in the				;AN000;
					; current header
       cmp  si, -1			; any extent under this header ??			   ;AN000;
       je   trunc_no_extent		; none, exit						   ;AN000;
       mov  cx,Logical_Clusnum		; CX = given logical cluster number			   ;AN000;

       CALL FIND_EXTENT 		; find the extent					   ;AN000;
       jnc  Trunc_shrink_extent 	; found extent ??					   ;AN000;

Trunc_No_Extent:			; extent not found
       xor  di,di			; no, return DI = 0					   ;AN000;
       clc				; clear carry
       jmp  Trunc_exit			; exit							   ;AN000;



;--------------------------------------------------------------------------
; Found extent.  Shrink the current extent and delete all subsequent extents.
; If the given logic clus num is the first cluster number in current extent,
; then delete the current extent and the subsequent ones.
;	  DI--->Extent found (starting extent)
;--------------------------------------------------------------------------
Trunc_Shrink_Extent:
       mov  bx,Logical_Clusnum									   ;AN000;
       cmp  bx,es:[di].EH_Logic_Clus_Num  ; first logic cluster match ??			   ;AN000;
       jne  shrink_cur_extent		  ; no, shrink current extent				   ;AN000;

;--------------------------------------------------------------------------
; First logical clus num matched. mark previous header or extent as last
;	  DI--->Extent found (starting extent)
;--------------------------------------------------------------------------
       mov  si,es:[di].EH_Prev_Extn_Ptr   ; SI-->Previous extent				   ;AN000;
       cmp  si, -1			  ; any previous extent ??				   ;AN000;
       je   trunc_no_prev		  ; no, jump						   ;AN000;
       mov  es:[si].EH_Next_Extn_Ptr,-1   ; mark previous extent as last extn			   ;AN000;
       mov  si,di			  ; save the current extent ptr 			   ;AN000;
       mov  cx, 0			  ; CX = buffer release counter 			   ;AN000;
       jmp  trunc_more			  ; release successive extents				   ;AN000;

;--------------------------------------------------------------------------
; Previous one is header. Mark so that there is no extents under it
;--------------------------------------------------------------------------
Trunc_No_Prev:
       mov  si,Cur_Hdr_Ptr		  ; get current header					   ;AN000;
       mov  es:[si].FH_Next_Extn_Ptr,-1   ; mark header for no extent				;AN000;
       mov  es:[si].FH_MRU_Extn_Ptr, -1
       mov  si,di			  ; save the current extent ptr 			   ;AN000;
       mov  cx, 0			  ; CX = buffer release counter 			   ;AN000;;AN000;
       jmp  short trunc_more		  ; release the extent					   ;AN000;


Shrink_Cur_Extent:
       sub  bx,es:[di].EH_Logic_Clus_Num  ; compute the amount to shrunk			   ;AN000;
       dec  bx											   ;AN000;
       mov  es:[di].EH_Count,bx 	  ; save it in count to shrink extent			   ;AN000;

;--------------------------------------------------------------------------
; Mark the current extent as the last extent and delete subsequent extents.
;--------------------------------------------------------------------------
       mov  si,es:[di].EH_Next_Extn_Ptr   ; SI-->Next extent					   ;AN000;
       cmp  si,-1			  ; current extent last extent ??			   ;AN000;
       jne  Trunc_Last_extent
       jmp  Trunc_Make_MRU_Hdr		  ; YES, In this case no subsequent			   ;AN000;
					  ; extents left to delete.
Trunc_Last_Extent:
       mov  es:[di].EH_Next_Extn_Ptr, -1  ; NO, mark last extent				   ;AN000;
       xor  cx,cx										   ;AN000;

;--------------------------------------------------------------------------
; Remove extents and release the buffer
;      SI--->Current extent
;--------------------------------------------------------------------------
Trunc_More:
       push  si 			 ; save the beginning of first				   ;AN000;
					 ; extent to be deleted
TRUNC_LOOP:				 ; loop for subsequent extents
       mov   ax, -2			 ; mark current extent as free				   ;AN000;
       mov   es:[si],ax 		 ; discontinuous free areas				   ;AN000;
       add   cx, SIZE Extent_Header	 ; add size of extent					   ;AN000;

       mov   ax,es:[si].EH_Next_LRU_Ptr  ; AX = address of Next LRU extent
       cmp   ax, -1			 ; any next LRU extent??
       jne   Trunc_Set_Next_LRU 	 ; yes - there is a next LRU extent

;-----------------------------------------------------------------------------
;  No - this is the LRU extent
;-----------------------------------------------------------------------------
       mov   di,es:[si].EH_Prev_LRU_Ptr  ; no - DI=address of previous LRU extent
       cmp   di, -1			 ; any prev LRU extent ??
       je    Trunc_Mark_Prev_Hdr	 ; no - previous is header
       mov   es:[di].EH_Next_LRU_Ptr, -1 ; yes - mark previous extnt LRU extent
       jmp   short Trunc_Chk_Next_ext	 ; no - check next adj extent

Trunc_Mark_Prev_Hdr:
       mov   di, Cur_Hdr_Ptr		 ; DI = address of current header
       mov   es:[di].FH_Next_Extn_Ptr,-1   ; mark header for no extent				 ;AN000;
       mov   es:[di].FH_MRU_Extn_Ptr, -1
       jmp   short Trunc_Chk_Next_Ext		 ; look for next extent

;-----------------------------------------------------------------------------
; There is a next LRU extent	AX-->Next_LRU_Extent
;-----------------------------------------------------------------------------
Trunc_Set_Next_LRU:
       mov   di,es:[si].EH_Prev_LRU_Ptr  ; DI = address of previous LRU extent
       cmp   di, -1			 ; any previous LRU extent ??
       jne   Trunc_Set_Prev_LRU 	 ; yes - connect prev LRU to Next LRU

       mov   di, Cur_Hdr_Ptr		 ; DI = address of current header
       mov   es:[di].FH_MRU_Extn_Ptr, ax   ; Connect next LRU extent to Hdr
       push  si 			 ; save current extent
       mov   si,ax
       mov   es:[si].EH_Prev_LRU_Ptr, -1  ; mark no previous extent
       pop   si 			 ; resetore current extent
       jmp   short Trunc_Chk_Next_Ext


Trunc_Set_Prev_LRU:			  ; DI-->Previous LRU extent
       mov   es:[di].EH_Next_LRU_Ptr,ax   ; connect previous LRU to Next LRU extent
       push  si 			  ; save Current extent
       mov   si,ax			  ; SI-->Next LRU extent
       mov   es:[si].EH_Prev_LRU_Ptr, di  ; set previous LRU header address
       pop   si 			  ; get current extent


Trunc_Chk_Next_Ext:			 ; SI-->Current extent
       mov   ax,es:[si].EH_Next_Extn_Ptr ; AX-->next extent					   ;AN000;
       cmp   ax, -1			 ; last extent ?					;AN000;
       je    Trunc_Update_Free_Size	 ; yes, jump						   ;AN000;

       mov   es:[si].FH_Next_Hdr_Ptr,ax  ; connect freed buffers togther			   ;AN000;
       mov   si,ax			 ; SI-->next extent					   ;AN000;
       jmp   Trunc_Loop 		 ; delete next extent					   ;AN000;

;-------------------------------------------------------------------------
; Update free size in the File header and connect the FREE_Ptr to the first
; extent released and connect the old Free_Ptr to end of the last extent
;      SI--->Current extent
;-------------------------------------------------------------------------
Trunc_Update_Free_Size: 		 ; SI-->Last extent released
       mov   di,Drive_Hdr_Ptr		 ; DI-->Drive header					   ;AN000;
       add   es:[di].Free_Size,cx	 ; update free area in drive header			   ;AN000;

Trunc_Join_Free_Area:
; At this point SI-->Last extent
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   es:[si].EH_Next_Extn_Ptr,ax ; connect last extent under this			   ;AN000;
					 ; header to the Free area				   ;AN000;
       pop   ax 			 ; beginning of truncated extent			   ;AN000;
       mov   es:[di].Free_Ptr,ax	 ; connect current extent to				   ;AN000;
					 ; the beginning of truncated extent

;--------------------------------------------------------------------------
; Make the Current header MRU header ( move current header to top of current Q)
;--------------------------------------------------------------------------
Trunc_make_MRU_Hdr:
      cmp   Prev_Hdr_Ptr,-1		 ; first header in the Queue??				   ;AN000;
      jne   Trunc_move_Hdr
      clc
      jmp   short Trunc_Exit		 ; yes, dont move to top				   ;AN000;

Trunc_move_Hdr:
      CALL  MAKE_MRU_HEADER		 ; move header to TOP of the Queue			   ;AN000;
      clc

Trunc_Exit:
      CALL  Check_it
      ret				 ; return						   ;AN000;

FK_TRUNCATE	ENDP








;-----------------------------------------------------------------------------
; Procedure:  PURGE_BUFFERS
;
; Function:   Reset both extent and name cache buffers of a specific
;	      drive id
;
; Input:      DL = drive ID
;
; Output:     Buffers are initialized
;
; REVISION HISTORY:  New  (5/87)
;
; COPYRIGHT:  "MS DOS 4.00 Fastopen Utility"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Property of Microsoft  "
;
;-----------------------------------------------------------------------------

FK_PURGE   PROC    FAR	       ; Purge Cache buffers

       push   cs
       pop    ds			  ; DS=Code seg id used for addressing
       ASSUME  ds:Cseg_Seek		  ; local variables				      ;AN000;

       mov    si,Seek_Extent_Drive_Buff   ; SI-->beginning of extent drive			   ;AN000;
       mov    es,Seek_Name_Cache_Seg	  ; ES = addressability to Cseg_Init			   ;AN000;
       ASSUME  es:Cseg_Init		  ;							   ;AN000;
       mov    cx,Seek_Num_Of_drives	  ; number of drives

Main_Loop2:				  ; ES:SI-->cache buffer
       mov    ax,es:[si].Drive_Number	  ; get drive id
       cmp    al,dl			  ; drive id found ??
       je     purge_buffer		  ; yes - purge drive id buffer
       mov    ax, size Drive_Header	  ; ax size of drive heder
       add    ax, es:[si].Buff_Size	  ; ax = offset to next header
       add    si,ax			  ; (2/11)SI-->next drive header			      ;AN000;
       LOOP   main_loop2		  ; try next header

Purge_Buffer:				  ; SI-->drive header
       mov    es:[si].MRU_Hdr_Ptr,-1	  ; Make OPEN  QUEUE empty				   ;AN000;
       mov    es:[si].CLOSE_Ptr,-1	  ; Make CLOSE QUEUE empty				   ;AN000;
       mov    cx,es:[si].BUFF_size	  ; drive extent cache size				   ;AN000;
       mov    es:[si].FREE_Size,cx	  ; set drive free buffer size				       ;AN000;
       mov    ax,si
       add    ax, size Drive_Header	  ; ax = size of drive header
       mov    es:[si].FREE_Ptr,ax	  ; set Free buffer address

; Makesure to fill extent cache buffer with zeros.  Otherwise, Free Mark left
; previous run will generate illegal Free_Buff pointer.
       mov    al,0
       add    si, size Drive_Header	  ; SI-->first extent area
Ext_loop:				  ; fill extent cahe buffer with zeros
       mov    es:[si],al		  ; CX = extent cache size
       inc    si			  ; next byte
       Loop   Ext_Loop			  ; make it zero

FK_Exit:
       clc
       CALL  Check_it
       ret											   ;AN000;

FK_PURGE    ENDP







;----------------------------------------------------------------------
;	  ******* SUPPORT  ROUTINES *******
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
; PROCEDURE: Find_Drive_Header
;
; FUNCTION: Find starting address of drive header in extent Cache Buffer using
;	    drive ID in DL
;
; INPUT:   DL = drive id
;	   Extent_Drive_Buff  (Ptr to the beginning of extent buffer)
;	   ES--> Cache Buffer Segment
;
; OUTPUT:  If Carry = 0    DI --> Drive header
;			   Drive_Hdr_Ptr = address of drive header
;
;	   If Carry = 1    Drive buffer not found
;
; NOTE:    If drive id in DL is same as the drive id in previous request,
;	   no need to search the drive header. Use the previous drive header
;
;----------------------------------------------------------------------

FIND_DRIVE_HEADER    PROC     NEAR

       mov    di,Drive_Hdr_Ptr		; DI-->address of prev drive header
       cmp    drv_id,dl 		; drive id same as previous drive id  (1/11/88)
       jne    Search_drv_hdr		; no - search drive header
       clc				; yes - dont search
       jmp    short drive_exit		; exit

Search_Drv_Hdr:
       mov   cx,Seek_Num_of_Drives	; get number of drives								 ;AN000;
       mov   si,Seek_Extent_Drive_Buff	; SI-->start of extend drive hdr			;AN000;

Drive_Loop:
       mov   al,es:[si] 		; get drive ID from cache drive hdr			   ;AN000;
       cmp   al,dl			; found ??						      ;AN000;
       je    drive_buff_found		; yes, exit						      ;AN000;
       cmp   es:[si].Next_Drv_Hdr_Ptr,-1   ; last header ??					  ;AN000;
       je    drive_Buff_not_found	   ; yes - drive header not found							 ;AN000;
       mov   si,es:[si].Next_Drv_Hdr_Ptr   ; SI-->next drive header				   ;AN000;
       dec   cx 			; update drive count							       ;AN000;
       jz    drive_Buff_not_found	; last drive						      ;AN000;
       jmp   drive_Loop 		; search for more					      ;AN000;

Drive_Buff_Not_Found:			; drive buffer not found
       stc				; set carry flag					      ;AN000;
       jmp   short Drive_Exit		; exit							      ;AN000;

Drive_Buff_Found:			; drive buffer found
       mov   drv_id,dl			; save drive id
       mov   Drive_Hdr_ptr,si		; save drive buffer pointer				      ;AN000;
       mov   di,si			; DI-->drive header					   ;AN000;
       clc											   ;AN000;

Drive_Exit:				; return
       ret											   ;AN000;

FIND_DRIVE_HEADER     endp





;---------------------------------------------------------------
; PROCEDURE: Find_File_Header
;
; FUNCTION: Find starting address of the specific file header with
;	    a specific starting physical cluster number.  Also
;	    determine the type of header found.
;
; INPUT:   SI --> First header in the queue
;	   CX = First Physical Cluster Number (file id)
;	   ES--> Cache Buffer Segment id
;
; OUTPUT:  If Carry = 0    DI --> header found
;			   Cur_Hdr_Ptr	= address of header found
;			   Prev_Hdr_Ptr = address of previous header
;
;			   Prev_Hdr_Ptr = -1   No Previous Header
;
;			   hdr_flag  -	Type of header found
;				   =  0   Header between first & last in queue
;				   =  1   Single header in the queue
;				   =  2   First header in the queue
;				   =  3   LRU (Last) header in the queue
;
;	   If Carry = 1    Header not found
;
;---------------------------------------------------------------

FIND_FILE_HEADER    PROC    NEAR

       push  si 			; save registers					   ;AN000;
       push  cx 										   ;AN000;

       cmp   si, -1			; any file header in this queue ??			   ;AN000;
       jne   Fh_search_hdr		; yes, search for it					   ;AN000;
       stc				; no, set carry and return				   ;AN000;
       jmp   short Fh_Exit										 ;AN000;

Fh_Search_Hdr:
       mov   Prev_Hdr_Ptr,-1		; reset flags						   ;AN000;
       mov   Hdr_Flag, 0		; reset header type flag				   ;AN000;

Fh_Loop1:
       cmp   es:[si].FH_Phys_Clus_Num,CX   ; check current header				   ;AN000;
       jne   Fh_next_header		; if not found branch					   ;AN000;
       mov   di,si			; DI --> header found					;AN000;
       mov   Cur_Hdr_Ptr,si		; save current Hdr pointer				   ;AN000;
       jmp   short Fh_header_found	; then take exit					   ;AN000;

Fh_Next_header: 			; else try next header
       mov   ax,es:[si].FH_Next_Hdr_ptr    ; get address of next header 			   ;AN000;
       cmp   ax,-1			; is this last header?? 				   ;AN000;
       je    Fh_not_found		; yes, header no found					   ;AN000;

       mov   Prev_Hdr_Ptr,si		; save previous header					   ;AN000;
       mov   si,ax			; SI= next header					   ;AN000;
       jmp   Fh_Loop1			; check next header					   ;AN000;

; Determine the type of header found
Fh_Header_Found:			; header found
       cmp   Prev_Hdr_Ptr, -1		; any previous headers ??				   ;AN000;;AN000;
       jne   Fh_LRU			; yes, jump						   ;AN000;
       cmp   es:[si].Fh_Next_Hdr_Ptr, -1  ; any headers following this hdr ??			   ;AN000;
       jne   Fh_First			; yes, jump						   ;AN000;
       mov   Hdr_Flag, 1		; single header in the queue				   ;AN000;
       clc				;							   ;AN000;
       jmp   short FH_Exit		; exit							   ;AN000;

Fh_First:
       mov   Hdr_Flag, 2		; Header found is first header in QUE			   ;AN000;
       clc				; set flag						   ;AN000;
       jmp   short FH_Exit		; exit							   ;AN000;

Fh_LRU:
       cmp   es:[si].Fh_Next_Hdr_Ptr, -1   ; Last header in the queue ??			   ;AN000;
       jne   Fh_middle_hdr		; no, Header between first and last			   ;AN000;
       mov   Hdr_Flag, 3		; set flag indicating LRU header			   ;AN000;
       clc											   ;AN000;
       jmp   short Fh_Exit		; exit							   ;AN000;
												   ;AN000;
Fh_Middle_Hdr:
       clc											   ;AN000;
       jmp   short Fh_Exit		; exit							   ;AN000;

Fh_Not_found:
       stc				; header not found					   ;AN000;

Fh_Exit:
       pop  cx											   ;AN000;
       pop  si											   ;AN000;
       ret				; return						   ;AN000;

FIND_FILE_HEADER    ENDP







;---------------------------------------------------------------
; PROCEDURE: Find_Extent
;
; FUNCTION: Find starting address of the specific Extent that contains
;	    the given logical cluster mumber.
;	    Verifiy that the extent found is the LRU Extent.
;
; INPUT:   SI --> First Extent under current queue
;	   CX = Logical Cluster number to be searched
;	   ES--> Cache Buffer Segment Id
;
; OUTPUT:  If Carry = 0    DI --> Extent found
;			   Cur_Extn_Ptr  = address of extent found
;			   Prev_Extn_Ptr = address of previous extent
;			   IF Extn_Flag = 1, extent found  is the  only
;					     extent under this header
;
;	   If Carry = 1    Extent not found
;
; REVISION HISTORY:  New  (5/87)
;---------------------------------------------------------------

FIND_EXTENT	 PROC	 NEAR

       push  si 			    ; save registers					   ;AN000;
       push  cx 										   ;AN000;
												   ;AN000;
       mov   Prev_Extn_Ptr,-1		    ; reset flags
       mov   Extn_Flag, 0									   ;AN000;
												   ;AN000;
Eh_Loop1:
       cmp   cx,es:[si].EH_Logic_Clus_Num							   ;AN000;
       jl    Eh_Next_Extn		    ; try next extent					   ;AN000;
       mov   ax,es:[si].EH_Count	    ; get range 					   ;AN000;
       add   ax,es:[si].EH_Logic_Clus_Num   ; get upper range					   ;AN000;
       cmp   cx,ax										   ;AN000;
       jg    Eh_Next_Extn		    ; try next extent					   ;AN000;

Eh_Not_LRU:
       mov   di,si			    ; DI --> Extent found				   ;AN000;
       mov   Cur_Extn_Ptr,si		    ; save current extent pointer			      ;AN000;
       clc				    ; set flag						      ;AN000;
       jmp   Eh_Extn_found		    ; then take exit					      ;AN000;

Eh_Next_Extn:				    ; else try next extent
       mov   ax,es:[si].EH_Next_Extn_ptr    ; get address of next extent			    ;AN000;
       cmp   ax,-1			    ; is this last extent??				      ;AN000;
       je    Eh_Not_Found		    ; yes, exit 					      ;AN000;
       mov   Prev_Extn_Ptr,si		    ; save previous extent				      ;AN000;
       mov   si,ax			    ; SI=next extent					      ;AN000;
       jmp   Eh_Loop1			    ; check next extent 				      ;AN000;

       stc				    ; else set flag for extent not found		      ;AN000;
       jmp   short Eh_Exit		    ; then exit 					      ;AN000;

Eh_Extn_Found:				    ; Extent found
       cmp   Prev_Extn_Ptr, -1		    ; any previous extents ??				      ;AN000;
       jne   Eh_yes			    ; yes, jump 					      ;AN000;
       cmp   es:[di].Eh_Next_Extn_Ptr, -1   ; any extents following this extents ??		    ;AN000;
       jne   Eh_yes			    ; yes, jump 					      ;AN000;
       mov   Extn_Flag, 1		    ; no, set flag indicating single extnt		      ;AN000;
					    ; in the queue
Eh_Yes:
       clc											   ;AN000;
       jmp   short Eh_Exit		    ; exit							  ;AN000;

Eh_Not_Found:				    ; extent not found
       stc											   ;AN000;

Eh_Exit:
       pop  cx											   ;AN000;
       pop  si											   ;AN000;

       ret				; return						   ;AN000;

FIND_EXTENT	 ENDP






;---------------------------------------------------------------------------
; PROCEDURE: FIND_CLUSTER_LOCATION
;
; FUNCTION:  Find starting address of a specific extent which identifies
;	     the relative position of the new cluster in the queue.
;
; INPUT:     SI--> First extent under current header
;	     ES--> Cache Buffer Segment
;
; OUTPUT:    If Carry = 0    Cluster location identified
;	     Cur_Extn_Ptr =  Current extent
;	     Prev_Extn_Ptr = Previous extent
;
;			     Find_Flag =  1  Clusters are  contiguous in
;					  the LO end of the current extent
;
;			     Find_Flag =  2  Clusters are contiguous in
;					  the HI end of the current extent
;
;			     Find_Flag =  3  Clusters  belong to a new
;					  extent between current and previous
;					  extent
;
;			     Find_Flag =  4  Clusters belong to a new
;					  extent at the end of the queue
;					  Cur_Extn_Ptr-->Last extent in queue
;
;			     Find_Flag =  5  Clusters belong to a new
;					  extent between current and next
;
;	    If Carry = 1    Clusters already exist
;
;-----------------------------------------------------------------------


FIND_CLUSTER_LOCATION	PROC   NEAR

;--------------------------------------------------------------------------
; Check to see that the given logical cluster number falls within the
; current extent. If true it is an error.
;--------------------------------------------------------------------------
       push  di
       mov   Prev_Extn_Ptr, -1		; initialize the flag					   ;AN000;
       mov   Cur_Extn_Ptr,si		; SI-->First extent under header			   ;AN000;
       mov   Find_Flag, -1		; reset with illegal value
												   ;AN000;
Fe_LOOP1:
       mov   ax,es:[si].EH_Logic_Clus_Num  ; AX = starting logi clus number				;AN000;
       mov   bx,Logical_Clusnum 	; BX = given logical clus num				   ;AN000;
       cmp   bx,ax			; LOW end ??					;AN000;
       jl    Fe_Chk_Low_end		; yes - jump					;AN000;
       add   ax,es:[si].EH_Count	; ending logical clus number				   ;AN000;
       cmp   bx,ax			; HIGH end ??					    ;AN000;
       jg    Fe_Chk_High_end		; yes - jump						;AN000;

;--------------------------------------------------------------------------
; Found the given logical cluster number within the extent.
; This is a normal condition.  In this case the clusters wont be insterted.
;--------------------------------------------------------------------------
       stc				; set flag
       jmp   Fe_Extent_Exit		; return						   ;AN000;


;--------------------------------------------------------------------------
; If not in the extent, then see the logical clus number has continuity at
; LOW end of the current extent.
;--------------------------------------------------------------------------
Fe_Chk_LOW_END:
       mov   ax,es:[si].EH_Logic_Clus_Num  ; starting logi clus number				   ;AN000;
       dec   ax 			; one below the lowest					   ;AN000;
       mov   bx,Logical_Clusnum 	; BX = given logical clus num				   ;AN000;
       cmp   bx,ax			; contiguous at LOW end ??				   ;AN000;
       jl    Fe_Curr_Prev		; no, build a new extent between			   ;AN000;
					; current and previous
; Logical clus has continuity at low end.  Now check physical cluster number
; foe continuity.
       mov   ax,es:[si].EH_Phys_Clus_Num   ; starting Phys clus number				   ;AN000;
       dec   ax 			; one below the lowest in the extent			   ;AN000;
       mov   bx,Physical_Clusnum	; BX = given logical clus num				   ;AN000;
       cmp   bx,ax			; within low end ??					   ;AN000;
       jne   Fe_Curr_Prev		; no, create a new extent between			   ;AN000;
					; current and previous extent
       mov   Find_Flag,1		; yes, set flag for LOW END continuity			   ;AN000;
       jmp   Fe_Extent_found		; then RETURN						   ;AN000;


;--------------------------------------------------------------------------
; Check  the logical clus number has continuity at High end of the current
; extent cluster range. Check physical cluster number has continuity at the
; high end.  If true, check the first logical and phys cluster number is the
; the same as this one.  In this case clusters exist and therefore wont be
; insterted.
;--------------------------------------------------------------------------
Fe_CHK_HIGH_END:
       mov   ax,es:[si].EH_Logic_Clus_Num  ; starting logi clus number				   ;AN000;
       add   ax,es:[si].EH_Count	; ending logical clus number				   ;AN000;
       inc   ax 										   ;AN000;
       mov   bx,Logical_Clusnum 	; BX = given logical clus num				   ;AN000;
       cmp   bx,ax			; within high end ??					   ;AN000;
       jg    Fe_Chk_Next_Extent 	; no, check next extent 				   ;AN000;

; Logical clus num has high end continuity, Check the Physical cluster number
; for continuity.
       mov   ax,es:[si].EH_Phys_Clus_Num    ; starting phys clus number 			   ;AN000;
       add   ax,es:[si].EH_Count	; ending phys clus number				   ;AN000;
       inc   ax 										   ;AN000;
       mov   bx,Physical_Clusnum	; BX = given logical clus num				   ;AN000;
       cmp   bx,ax			; within high end ??					   ;AN000;
       jne   Fe_Chk_Next_Extent 	; no - check next extent		 ;AN000;
					;
; Yes - check first logical and physical cluster number of next extent
       mov   di,es:[si].EH_Next_Extn_Ptr   ; get address of next extent 			   ;AN000;
       cmp   di, -1			; any next extent ??
       je    Fe_High_End		; none - jump
       mov   ax,es:[di].EH_Logic_Clus_Num  ; starting logi clus number				   ;AN000;
       cmp   ax,Logical_Clusnum 	; logical cluster matches ??
       jne   Fe_high_end		; no - jump
       mov   ax,es:[di].EH_Phys_Clus_Num    ; starting phys clus number 			   ;AN000;
       cmp   ax,Physical_Clusnum	; physical cluster match ??
       jne   Fe_High_End		; no -jump
       stc				; clusters already exist in next extent
       jmp   short Fe_Extent_Exit	; return						   ;AN000;

Fe_High_End:
       mov   Find_Flag,2		; set flag for HIGH end continuity			   ;AN000;
       jmp   short Fe_Extent_found	; then RETURN						   ;AN000;


Fe_Chk_Cur_Next:
       cmp  es:[si].EH_Next_Extn_Ptr, -1   ; Current extent last extent ??			   ;AN000;
       je   Fe_flag_4			; yes, set flag-4					   ;AN000;

       mov   Find_Flag,5		; set flag for new extent between			   ;AN000;
       jmp   short Fe_Extent_Found	; current and next extent				   ;AN000;

Fe_Flag_4:
       mov   Find_Flag,4		; set flag for new extent at the			   ;AN000;
       jmp   short Fe_Extent_Found	; bottom end of current queue				   ;AN000;

;--------------------------------------------------------------------------
; Given cluster number has no  continuity but must stay between current extent
; and previous extent
;--------------------------------------------------------------------------
Fe_CURR_PREV:
       mov   Find_Flag,3		; set flag for between current and prev 		   ;AN000;
       jmp   short Fe_Extent_found	; then RETURN						   ;AN000;


;--------------------------------------------------------------------------
; Given cluster number has no  continuity. Try the next extent.
;--------------------------------------------------------------------------
Fe_Chk_NEXT_EXTENT:			; else try next extent
       mov   ax,es:[si].EH_Next_Extn_Ptr   ; get address of next extent 			   ;AN000;
       cmp   ax,-1			; is this last extent ??				   ;AN000;
       je    Extent_at_Bottom		; yes, Clustr belongs to a new				   ;AN000;
					; extent at the bottom					   ;AN000;
       mov   Prev_Extn_Ptr,si		; save current extend as previous extnt
       mov   si,ax			; SI-->Next extent					   ;AN000;
       mov   Cur_Extn_Ptr, si		; save new extent as cur extent 			   ;AN000;
       jmp   Fe_Loop1			; check next extent					   ;AN000;


;--------------------------------------------------------------------------
; Given cluster number has no  continuity but stays in a new extent at
; bottom (last) of the current queue.
;--------------------------------------------------------------------------
Extent_AT_BOTTOM:
       mov   Find_Flag,4		; else set flag for new extent				   ;AN000;

Fe_Extent_Found:
       clc											   ;AN000;

Fe_Extent_Exit:
       pop    di

       RET				; exit							   ;AN000;


FIND_CLUSTER_LOCATION	 ENDP







;-----------------------------------------------------------------------
; PROCEDURE: FIND_LRU_HEADER
;
; FUNCTION: Find address of the LRU header in the current queue
;
; INPUT:   SI --> First header in the current queue
;	   ES--> Cache Buffer Segment
;
; OUTPUT:  DI --> LRU header found
;
;	   LRU_Prev_Hdr = Previous header address
;	   LRU_Hdr	= Address of LRU header found
;	   If Hdr_Flag	= 1  -	Header found is only header in the queue
;
;-----------------------------------------------------------------------

FIND_LRU_HEADER    PROC    NEAR

       push  bx 										   ;AN000;
       mov   hdr_flag,0 		; initilialize flags					   ;AN000;
       mov   LRU_Prev_Hdr, -1		;							   ;AN000;

Flh_Loop1:
       cmp   es:[si].FH_Next_Hdr_Ptr,-1 ; current header is last hdr ?				   ;AN000;
       jne   Flh_next_header		; if not  check next header				   ;AN000;
       mov   di,si			; DI --> LRU header found				   ;AN000;
       mov   LRU_Hdr,si 		; save it						   ;AN000;
       jmp   short Flh_header_found	; then take exit					   ;AN000;

Flh_Next_Header:			; else try next header
       mov   LRU_Prev_Hdr,si		 ; save previous header address 			   ;AN000;
       mov   si,es:[si].FH_Next_Hdr_ptr 							   ;AN000;
       jmp   Flh_Loop1			; check next header					   ;AN000;

Flh_Header_Found:
       cmp  LRU_Prev_Hdr, -1		; any previous header ??				   ;AN000;
       je   F1h_Set_Flag		; no, set flag						   ;AN000;
       clc				; yes							   ;AN000;
       jmp  short F1H_Exit		; exit							   ;AN000;

F1h_Set_Flag:
       mov  hdr_flag,1			; LRU header is the only hdr in queue			   ;AN000;
       clc											   ;AN000;

F1h_Exit:				; exit
       pop  bx											   ;AN000;

       ret											   ;AN000;

FIND_LRU_HEADER    endp




;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; PROCEDURE: FIND_LRU_EXTENT
;
; FUNCTION: Find  address of LRU  Extent under current header
;
; INPUT:   ES--> Cache Buffer Segment
;	   SI--> Header to be searched
;
; OUTPUT:  If  CY =  0	 LRU_Prev_Extent = Previous extent to the LRU extent
;			 LRU_Extent	 = LRU extent found
;			 Extn_Flag = 1	 Extent is the only extent under header
;
;	   If  CY =  1	 Not found
;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

FIND_LRU_EXTENT    PROC     NEAR

       mov   LRU_Prev_Extent, -1	   ; reset flags							;AN000;
       mov   LRU_Extent, -1		   ;									;AN000;
       mov   Extn_Flag, 0
       mov   si, es:[si].FH_MRU_Extn_Ptr   ; SI--> First extent under header
       cmp   si, -1			   ; any extent under this header ??
       jne   Fle_Loop1			   ; yes - check extent
       stc				   ; no - set flag
       jmp   Fle_Exit			   ; exit

Fle_Loop1:
       cmp   es:[si].EH_Next_LRU_Ptr,-1    ; last extent in the queue??
       jne   Fle_next_extent		   ; if not found branch				     ;AN000;
       mov   LRU_Extent,si		   ; save LRU extent address
       jmp   short Fle_Extend_found	   ; exit

Fle_Next_Extent:			   ; else try next extend
       mov   LRU_Prev_Extent,si 	   ; save previous extent address
       mov   si,es:[si].EH_Next_LRU_Ptr    ; get address of next extent
       jmp   Fle_Loop1			   ; check next extent					     ;AN000;

Fle_Extend_Found:
       cmp   LRU_Prev_Extent, -1	   ; any previous extent ??
       je    Fle_Set_Flag		   ; no - set flag
       clc				   ;							      ;AN000;
       jmp   short Fle_Exit

Fle_Set_Flag:
       mov   Extn_Flag, 1		   ; set flag to indicate only flag
       clc

Fle_Exit:
       ret				   ; exit						      ;AN000;

FIND_LRU_EXTENT    ENDP







;----------------------------------------------------------------------
; PROCEDURE: Make_New_Header
;
; FUNCTION: Create a new header in the next available free area.
;	    Initialize the new header and make it MRU header ( move it
;	    to the top of the queue). If no free space in OPEN queue, delete
;	    and extent from the CLOSE queue.  If no space in CLOSE queue, then
;	    delete an extent from OPEN Queue to make space.
;
; INPUT:   Drive_Hdr_Ptr  - Address of drive header
;	   Free_Ptr	  - Address of FREE area
;	   ES--> Cache Buffer Segment
;
; OUTPUT:  Header is created
;
;----------------------------------------------------------------------

MAKE_NEW_HEADER     PROC

; Check if the OPEN Queue was previously empty using two cases. If open queue
; is empty, then the new header should be marked as first header in the queue.
       mov   Open_Queue_Flag, 0 	 ; clear flag open queue empty				   ;AN000;
       mov   di,Drive_Hdr_Ptr									   ;AN000;

; case - 1
       mov   ax,es:[di].Free_Size	 ; FREE size						   ;AN000;
       cmp   es:[di].Buff_Size,ax	 ; both are equal ?					   ;AN000;
       je    Make_Set_Entries		 ; if true, this is the first header			   ;AN000;

; case - 2
       cmp   es:[di].MRU_Hdr_Ptr, -1	 ; check for empty mark 				   ;AN000;
       je    Make_Set_Entries		 ; yes, set flag queue empty				   ;AN000;
       jmp   short Make_Set_Entry2	 ; not empty						   ;AN000;

Make_set_Entries:			 ; set up File Header entries
; When creating first header under drive header, mark header as first
; This flag is set for this purpose.
       mov   Open_Queue_Flag, 1 	 ; set flag open queue was empty			  ;AN000;

Make_Set_Entry2:
       CALL  FIND_FREE_BUFFER		 ; Look for some Free area. If none			   ;AN000;
												   ;AN000;
       mov   di,Drive_Hdr_Ptr		 ; DI-->Drive header					   ;AN000;
       mov   ax,es:[di].Free_Ptr								   ;AN000;
       mov   New_Hdr_Ptr,ax		 ; save new Header address
       mov   ax,es:[di].Free_Size								   ;AN000;

       CALL  UPDATE_FREE_AREA		 ; update Free_Ptr and Free_Size			   ;AN000;
					 ; create some free area

;-----------------------------------------------------------------------------
; Connect the new header to the Top of the OPEN Queue.	If the Queue is
; previously empty, mark the new header indicating nothing under this header.
;-----------------------------------------------------------------------------
Join_To_Drive_Buff:
       mov   di, drive_Hdr_Ptr		 ; DI-->drive buffer					   ;AN000;
       mov   si,New_Hdr_Ptr									   ;AN000;
       mov   Cur_Hdr_Ptr, si		 ; save as current header pointer			   ;AN000;
       mov   ax,es:[di].MRU_Hdr_Ptr	 ; connect current header to				   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax  ; previous MRU header
       mov   es:[di].MRU_Hdr_Ptr,si	 ; make new header MRU hdr

; When a header is created, it should contain no extents
       mov   es:[si].FH_Next_Extn_Ptr,-1    ; mark header with no extents			   ;AN000;
       mov   es:[si].FH_MRU_Extn_Ptr,-1     ; ###mark header with no extents			      ;AN000;
       mov   es:[si].FH_Refer_Count,1	    ; save starting file reference count		   ;AN000;
       mov   ax,First_Phys_Clusnum								   ;AN000;
       mov   es:[si].FH_Phys_Clus_Num,ax    ; save physical cluster number			   ;AN000;

       cmp   Open_Queue_Flag, 1 	 ; OPEN Queue empty ??					   ;AN000;
       je    Set_Single_Header		 ; no, jump						   ;AN000;
       clc
       ret											   ;AN000;

Set_Single_Header:			 ; yes mark new header as last hdr
       mov   si,New_Hdr_Ptr									   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,-1     ; mark as only header				   ;AN000;
       clc
       ret				    ; exit

MAKE_NEW_HEADER    ENDP






;----------------------------------------------------------------------
; PROCEDURE: Find_Free_Buffer
;
; FUNCTION: Find free buffer space. If no free space, delete last extent
;	    under last header in the CLOSE queue.   If none in CLOSE queue,
;	    delete the last extent of the LRU header in the OPEN queue.
;
; INPUT:   Drive_Hdr_Ptr - Pointer to drive header
;	   ES--> Cache Buffer Segment
;
; OUTPUT:  Released Header or extent buffer space will be addded to the
;	   Free area as discontinuous free area.  Free size in drive head
;	   will be updated.
;
;	   If  CARRY = 0
;	       Free_Flag: 0 - Free area is continuous
;			  1 - Free area is discontinuous
;
;	   if  CARRY = 1   Fatal error ( no free space to spare )
;
; NOTE:   The deleted buffers have size same as the size of a header or extent.
;	  Each buffers first location contains a marker (-2) to indicate that
;	  the buffer is a discontinuous buffer.  Each buffer is connected to
;	  the next dicontinous buffer through the 4th word.
;
;----------------------------------------------------------------------

FIND_FREE_BUFFER    PROC     NEAR

       mov    di,drive_Hdr_Ptr	       ; DI-->Drive Header					   ;AN000;
       cmp    es:[di].free_size,0      ; any free area left ??					   ;AN000;
       je     Free_Chk_Close_List      ; none, check CLOSE queue				    ;AN000;

       mov    si,es:[di].Free_Ptr      ; check for discontinuous				   ;AN000;
       mov    ax, -2										   ;AN000;
       cmp    es:[si], ax	       ; discontinuous free buffer??					      ;AN000;
       je     Free_Set_One	       ; yes, set flag for discontinuous

       mov    Free_Flag,0	       ; no, clear flag 					   ;AN000;
       clc											   ;AN000;
       jmp    Free_Exit

Free_Set_one:
       mov    Free_Flag,1	       ; set flag						   ;AN000;
       clc											   ;AN000;
       jmp    Free_exit 	       ; yes, Free space is available				   ;AN000;
				       ; exit


;--------------------------------------------------------------------------
; No free space ,  look for space in CLOSE Queue. Search for the LRU header
; delete the header and any extents under this header.
;--------------------------------------------------------------------------
Free_Chk_Close_List:
       mov    si,es:[di].CLOSE_Ptr     ; SI-->CLOSE queue					    ;AN000;
       cmp    si,-1		       ; anything in CLOSE Queue ??				   ;AN000;
       jne    Free_Chk_CLOSE_QUE       ; yes - get space from CLOSE queue
       jmp    short Free_Look_Open_Queue     ; if none, make space from OPEN Queue			 ;AN000;


; Else get space from CLOSE queue
Free_Chk_Close_QUE:		       ; SI-->CLOSE queue
       mov    si,es:[di].CLOSE_Ptr     ; select OPEN Queue					   ;AN000;
       CALL   FIND_LRU_HEADER	       ; find LRU  header in CLOSE Queue				 ;AN000;
				       ; DI-->LRU header

; Makesure to save all local variables	before calling DELETE
; since, this variables may be altered by DELETE routine.
       mov    ax,Hdr_Flag
       push   ax
       mov    ax,Prev_Hdr_Ptr
       push   ax
       mov    ax,Queue_Type
       push   ax
       mov    ax,Cur_Hdr_Ptr
       push   ax
       mov    ax,First_Phys_Clusnum    ; save original first phys from OPEN call
       push   ax		       ; in the stack
       mov    cx,es:[di].FH_Phys_Clus_Num  ; CX= starting phys clus num of LRU header
       mov    From_FreeBuff,1	       ; set flag

       push   ds
       mov    ax,Cseg_Main
       mov    ds,ax
       assume ds:Cseg_Main
       CALL   VECTOR_DELETE	       ; delete the file
       pop    ds
       assume ds:Cseg_Seek

       mov    From_FreeBuff,0	       ; clear flag
       mov    Free_Flag,1	       ; set flag to indicate discontinuous free area
       pop    ax		       ; restore first phys clus
       mov    First_Phys_Clusnum,ax    ; save it back where it belongs
       pop    ax		       ; restore current header
       mov    Cur_Hdr_Ptr,ax	       ; save it back where it belongs
       pop    ax		       ; restore current header
       mov    Queue_Type,ax	       ; save it back where it belongs
       pop    ax		       ; restore current header
       mov    Prev_Hdr_Ptr,ax	       ; save it back where it belongs
       pop    ax		       ; restore current header
       mov    Hdr_Flag,ax	       ; save it back where it belongs
       clc
       jmp    Free_exit 	       ; exit							   ;AN000;



;----------------------------------------------------------------------------
; No space available in CLOSE Queue . Now get some free space from OPEN Queue
; and add it to the free area.
;----------------------------------------------------------------------------
Free_Look_Open_Queue:
       mov    si,es:[di].MRU_Hdr_Ptr   ; SI-->First header in OPEN Queue			;AN000;
       CALL   FIND_LRU_HEADER	       ; find last header in Queue				   ;AN000;
				       ; DI-->last header
       mov    si,es:[di].FH_MRU_Extn_Ptr ;### SI-->first extent in this header			     ;AN000;
       cmp    si, -1		       ; any extent under this header ??			   ;AN000;
       jne    Free_Open_Find_Extent    ; yes, find last extent					   ;AN000;

; if no extents under this header, delete this header and free the space
       cmp    di,Cur_Hdr_Ptr	       ; header found is its own header ??			;AN000;
       jne    Free_OPen_Mark_Prev      ; no - free the header				  ;AN000;
       stc			       ; Yes - set carry, exit						 ;AN000;
       jmp    Free_Exit 	       ; ERROR	exit					    ;AN000;

Free_Open_Mark_Prev:		       ; mark previous header as LRU before deleting this header
       mov    si,LRU_Prev_Hdr	       ; SI-->previous header					   ;AN000;
       mov    es:[si].FH_Next_Hdr_Ptr, -1  ; mark previous header as last hdr			   ;AN000;
       jmp    Free_Open_Cl_Buffer								   ;AN000;

Free_Open_Find_Extent:
       mov    si,di		       ; SI-->header to be searched
       CALL   FIND_LRU_EXTENT	       ; ### find last extent in the header			       ;AN000;
       mov    di, LRU_Extent	       ; DI-->LRU extent
       cmp    Extn_flag,1	       ; Is this the only extent in the queue ? 		   ;AN000;
       jne    free_Open_prev_extn      ; no, mark previous extent as last extn			   ;AN000;
       push   di		       ; save pointer to Last extent				   ;AN000;
       mov    di,LRU_Hdr	       ; DI-->LRU header					   ;AN000;
       mov    es:[di].FH_Next_Extn_Ptr,-1 ; mark current HEADER with no extents 		       ;AN000;
       mov    es:[di].FH_MRU_Extn_Ptr,-1  ; ### mark current HEADER with no extents			   ;AN000;
       pop    di		       ; DI-->LRU extent					  ;AN000;
       jmp    Free_Open_Cl_Buffer      ; release this extent					   ;AN000;

;----------------------------------------------------------------------
; Mark Previous MRU extent as LRU extent and also connect the previous
; adjucent extent to the next adjcent extent.
;----------------------------------------------------------------------
Free_Open_Prev_Extn:			    ; mark previous MRU extent as LRU extnt
       mov    si, es:[di].EH_Prev_LRU_Ptr   ; no -  SI-->Previous adj extent
       mov    es:[si].EH_Next_LRU_Ptr, -1   ;mark previous extent as last extent	     ;AN000;

       cmp    es:[di].EH_Next_Extn_Ptr, -1  ; any next adjucent extent ??
       jne    OPen_Join_extents 	    ; yes - join previous to next

       mov    si, es:[di].EH_Prev_Extn_Ptr  ; no -  SI-->Previous adj extent
       cmp    si, -1			    ; any previous adj extent ??
       je     Open_Prev_Hdrx		    ; no - previous is a header
       mov    es:[si].EH_Next_Extn_Ptr, -1  ; mark previous extent as the last
       jmp    short Free_Open_Cl_Buffer     ; free the current extent

Open_Prev_Hdrx:
       push   di			    ; DI-->extent to be deleted
       mov    di,LRU_Hdr		    ; DI-->LRU header
       mov    es:[di].FH_Next_Extn_Ptr, -1  ; mark header with no extents
       mov    es:[di].FH_MRU_Extn_Ptr, -1   ; mark header with no extents
       pop    di
       jmp    short Free_Open_Cl_Buffer     ; free current extent

Open_Join_Extents:			    ; DI-->current extent to be freed
       mov    si, es:[di].EH_Prev_Extn_Ptr  ; no -  SI-->Previous adj extent
       cmp    si, -1			    ; any previous extent ??
       je     Open_Prev_Hdry		    ; no - previous is a header - join header
					    ; to extent
       mov    ax, es:[di].EH_Next_Extn_Ptr  ; AX = address of next adjucent extent
       mov    es:[si].EH_Next_Extn_Ptr,ax   ; connect prev adj extent to next adj extent
       push   di			    ; save addrs of extent to be deleted
       mov    di, ax			    ; SI = address of previous LRU extent
       mov    es:[di].EH_Prev_Extn_Ptr,si   ; address of next LRU extent
       pop    di			    ; restore address
       jmp    short Free_Open_Cl_Buffer     ; free the extent

Open_Prev_Hdry:
       mov    si, LRU_Hdr		    ; SI-->LRU_Hdr
       mov    ax, es:[di].EH_Next_Extn_Ptr  ; AX = address of next adjucent extent
       mov    es:[si].FH_Next_Extn_Ptr,ax   ; connect hdr to next adj extent
       mov    si,ax			    ; SI = addrss of next adj extent
       mov    es:[si].EH_Prev_Extn_Ptr,-1   ; mark no previous extent
       mov    di,LRU_Extent		    ; DI-->extent to be deleted

;----------------------------------------------------------------------------
; Free the current Extent or Header
;----------------------------------------------------------------------------
Free_Open_Cl_Buffer:		       ;
       mov    si,di		       ; SI-->LRU extent or header				  ;AN000;
       mov    di,Drive_Hdr_Ptr	       ; DI-->drive buffer					   ;AN000;
       mov    ax,es:[di].Free_Ptr								   ;AN000;
       mov    es:[si].EH_Next_Extn_Ptr,ax   ; connect Free ptr to last				   ;AN000;
				       ; extent in the queue
       mov    ax, -2		       ; discontinuous mark (-2)				   ;AN000;
       mov    es:[si], ax	       ; mark freed area as discontinuous			   ;AN000;
       mov    es:[di].Free_Ptr,si      ; connect header or extent to free area			   ;AN000;

; Increase the Free_Size entry in Drive Header
       mov    ax, Size File_Header     ; size is same for both header or extent 		   ;AN000;
       add    es:[di].Free_Size, ax    ; update free buffer count				   ;AN000;
       mov    Free_Flag,1	       ; set flag for discontinuous free area			   ;AN000;
       clc
Free_Exit:			       ; exit
      ret			       ; return 						   ;AN000;

FIND_FREE_BUFFER    endp






;----------------------------------------------------------------------
; PROCEDURE: Make_MRU_Header
;
; FUNCTION: Move header to the top of the queue. If the header is at the
;	    bottom of the queue, mark previous header as LRU header
;	    before moving the header to the top of the queue.
;
; INPUT:   Drive_Hdr_Ptr  - Points to drive header
;	   Cur_Hdr_Ptr	  - Points to current header
;	   ES--> Cache Buffer Segment
;
; OUTPUT:  Header is moved to top of the current queue
;	   SI-->current header
;
;----------------------------------------------------------------------

MAKE_MRU_HEADER    PROC    NEAR

       mov   si,Cur_Hdr_Ptr		 ; SI-->Current Header					   ;AN000;
       cmp   es:[si].FH_Next_Hdr_Ptr,-1  ; current header LRU header				   ;AN000;
       jne   Move_close_gap		 ; no, jump						   ;AN000;
												   ;AN000;
       mov   di,Prev_Hdr_Ptr		 ; yes, make previous header
       mov   es:[di].FH_Next_Hdr_Ptr,-1  ; LRU header						   ;AN000;
       jmp   short move_to_top

Move_Close_Gap:
       mov   di,Prev_Hdr_Ptr		 ; yes, get previous header
       mov   ax,es:[si].FH_Next_Hdr_Ptr     ; get next header address
       mov   es:[di].FH_Next_Hdr_Ptr,ax  ; connect previous hdr to next hdr
												   ;AN000;
Move_To_Top:
       mov   di,drive_Hdr_Ptr		 ; DI-->drive buffer					   ;AN000;
       mov   ax,es:[di].MRU_Hdr_Ptr	 ; connect current header to				   ;AN000;
       mov   es:[si].FH_Next_Hdr_Ptr,ax  ; previous MRU header					   ;AN000;
       mov   es:[di].MRU_Hdr_Ptr,si	 ; make current header MRU hdr				   ;AN000;
					 ;
       ret

Make_MRU_Header  ENDP






;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; PROCEDURE: MAKE_MRU_EXTENT
;
; FUNCTION: Move Extent to the top of the queue. If the extent is at the
;	    bottom of the queue, mark previous extent as LRU extent
;	    before moving the extent to the top of the queue. If the extent
;	    is between first and last, then close the MRU-LRU chain gap.
;	    If the extent is already MRU then exit.
;
;	    This routine is called if clusters are inserted or looked up
;	    from an existing extent.
;
; INPUT:    Cur_Hdr_Ptr   - Address of current header
;	    Cur_Extn_Ptr  - Address of current extent
;	    ES--> Cache Buffer Segment
;
; OUTPUT:   Extent is moved next to the current header
;	    SI-->current extent
;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

MAKE_MRU_EXTENT     PROC    NEAR

       mov   si,Cur_Hdr_Ptr		 ; SI-->Current Header					   ;AN000;
       mov   ax,Cur_Extn_Ptr
       cmp   es:[si].FH_MRU_Extn_Ptr, ax     ; current extent already MRU??				 ;AN000;
       je    Make_MRU_Exit		 ; yes - exit

       mov   si, Cur_Extn_Ptr		 ; SI-->Current extent
       mov   di,es:[si].EH_Prev_LRU_Ptr  ; get address of previous MRU extent
       cmp   di, -1			 ; any previous MRU extent ??
       je    Make_MRU_Exit		 ; none - exit- current extent is already MRU

; Close the gap (connect previous to next extent)
       mov   si, Cur_Extn_Ptr
       cmp   es:[si].EH_Next_LRU_Ptr, -1    ; current extent LRU extent ??
       jne   join_the_gap		    ; no - close the gap
       mov   es:[di].EH_Next_LRU_Ptr, -1    ; mark the previous extent MRU
       jmp   short move_MRU_Extent	    ; make mru extent

Join_The_Gap:
       mov   ax, es:[si].EH_Next_LRU_Ptr ; AX-->next LRU extent
       mov   es:[di].EH_Next_LRU_Ptr,ax  ; connect previous to next
       mov   bx,di			 ; BX-->prev LRU extent
       mov   di,ax			 ; DI-->Next LRU extent
       mov   es:[di].EH_Prev_LRU_Ptr, bx  ; set previous LRU extent address


; Make the current extent  MRU extent
Move_MRU_Extent:
       mov   di,Cur_Hdr_Ptr		    ; DI-->Current header
       mov   ax,es:[di].FH_MRU_Extn_Ptr     ; AX-->Previous MRU extent
       mov   es:[si].EH_NEXT_LRU_Ptr,ax     ; connect previous to  current extent
       mov   es:[di].FH_MRU_Extn_Ptr,si     ; make current extent MRU extent
       mov   es:[si].EH_Prev_LRU_Ptr, -1    ; mark no previous LRU extent

       mov   di,ax			    ;(12/29) set prev LRU addrs of prev MRU extent
       mov   es:[di].EH_Prev_LRU_Ptr,si     ;(12/29)

Make_MRU_Exit:
       clc
       ret				    ; return

MAKE_MRU_EXTENT     ENDP






;----------------------------------------------------------------------
; PROCEDURE: JOIN_PREV_TO_NEXT
;
; FUNCTION: Connect previous header to next header inorder to close the
;	    gap created when a header is moved to top of the Queue or to
;	    the top of CLOSE queue.  If the file header is the first header
;	    under the current Drive header, connect header to the MRU_Hdr_Ptr.
;
; INPUT:   Prev_Hdr_Ptr   - Points to Previous header
;	   Cur_Hdr_Ptr	  - Points to Current Header
;	   Queue_Type	  - Queue Type:  0 = Open Queue
;					 1 = Close Queue
;	   ES--> Cache Buffer Segment
; OUTPUT:  Gap is closed
;
;----------------------------------------------------------------------

JOIN_PREV_TO_NEXT    PROC

       cmp   Prev_Hdr_Ptr, -1		 ; current hdr first file header ??			   ;AN000;
       jne   join_prev_hdr		 ; no, close gap					   ;AN000;

; Yes, in this case close gap by connecting  Drive header to next header
       mov   di,Drive_Hdr_Ptr		 ; DI-->drive header					   ;AN000;
       mov   si,Cur_Hdr_Ptr		 ; SI-->Current header					   ;AN000;
       mov   ax,es:[si].FH_Next_Hdr_Ptr  ; AX-->Next Header					   ;AN000;
       cmp   Queue_Type, 1		 ; Is this Close Queue ??				   ;AN000;
       je    Join_Sel_Close_Ptr 	 ; Yes, jump						   ;AN000;
       mov   es:[di].MRU_Hdr_Ptr,ax	 ; join next header to Drive Header			   ;AN000;
       jmp   short join_exit		 ; exit 						   ;AN000;

Join_Sel_Close_Ptr:
       mov   es:[di].Close_Ptr,ax	 ; join next header to Drive Header			   ;AN000;
       jmp   short join_exit		 ; exit 						   ;AN000;


; Connect previous header to next header  ( close the gap )
Join_Prev_Hdr:
       mov   di,Prev_Hdr_Ptr		 ; DI-->Previous header 				   ;AN000;
       mov   si,Cur_Hdr_Ptr		 ; SI-->Current Header					   ;AN000;
       mov   ax,es:[si].FH_Next_Hdr_Ptr  ; connect previous header				   ;AN000;
       mov   es:[di].FH_Next_Hdr_Ptr,ax  ; to next header					   ;AN000;

Join_Exit:
       ret				 ; exit 						   ;AN000;

JOIN_PREV_TO_NEXT   ENDP






;----------------------------------------------------------------------
; PROCEDURE: UPDATE_FREE_AREA
;
; FUNCTION:  Update Free area pointer and Free area size before creating
;	     a new extent or new header
;
; INPUT:   Prev_Hdr_Ptr   - Points to Previous header
;	   Cur_Hdr_Ptr	  - Points to Current Header
;	   Queue_Type	  - Queue Type:  0 = Open Queue
;					 1 = Close Queue
;	   Free_Flag	  - Free area type:  0 = continous free area
;					     1 = non-contiguous free area
;	   ES--> Cache Buffer Segment
;
;
; OUTPUT:  Free pool address and size is updated
;
;----------------------------------------------------------------------

UPDATE_FREE_AREA     PROC

       mov   di,Drive_Hdr_Ptr		 ; DI-->drive header					   ;AN000;
       mov   si,es:[di].Free_Ptr	 ; SI-->current free pointerted 			  ;AN000;
					 ;
       mov   ax, Size Extent_Header								   ;AN000;
       sub   es:[di].Free_Size, ax	 ; update free area size				   ;AN000;

       cmp   Free_Flag, 1		 ; continuous free area ??				   ;AN000;
       jne   ext_add_free_ptr		 ; yes - update free area pointer			    ;AN000;

;----------------------------------------------------------------------
; If discontinuous Free area. Update the Free pointer by getting pointer
; to next free from the 4th word using header or extent structure.
; This is because the discontinuous areas are connected chained through
; the 4th word
;----------------------------------------------------------------------
       mov   ax,es:[si].FH_Next_Hdr_Ptr  ; no, update FREE area pointer 			   ;AN000;
       mov   es:[di].Free_Ptr,ax	 ; using the Header structure				   ;AN000;
       jmp   short Update_Free_Exit	 ; Exit 						   ;AN000;

;----------------------------------------------------------------------
; If continuous Free area. Next free area address is computed by adding
; the size of extent of header structure.
;----------------------------------------------------------------------
Ext_Add_Free_Ptr:
       mov   ax, size File_Header	 ; calculate the address of				   ;AN000;
       add   es:[di].Free_Ptr,ax	 ; next free area by adding size of			   ;AN000;
					 ; a extent or header. Both same size
Update_Free_Exit:
       ret				 ; exit 						   ;AN000;

UPDATE_FREE_AREA     ENDP




;----------------------------------------------------------------------
; Procedure: CHECK_IT	   Checks the validity of the queues
;
;----------------------------------------------------------------------

CHECK_IT   PROC    NEAR

       pushf				      ; save all registers
       push   bx
       push   di
       cmp    check_flag,0
       je     check_exit
       mov    ah,090h
       xor    al,al
       xor    cx,cx
       mov    cl,func_cod
       mov    di, Drive_Hdr_Ptr
       INT    2FH
check_exit:
       pop    di
       pop    bx
       popf
       ret

CHECK_IT    ENDP



; Calculate the size of the Cseg_Seek module in bytes
	IF  ($-Cseg_Seek) MOD 16								   ;AN000;
	   ORG ($-Cseg_Seek)+16-(($-Cseg_Seek) MOD 16)						   ;AN000;
	ENDIF											   ;AN000;
END_SEEK   label   word


CSEG_SEEK    ENDS
     END
