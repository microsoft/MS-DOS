;	SCCSID = @(#)dpb.asm	1.1 85/04/10
;	SCCSID = @(#)dpb.asm	1.1 85/04/10
BREAK <DPB structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
dpb	STRUC
dpb_drive	    DB	    ?		; Logical drive # assoc with DPB (A=0,B=1,...)
dpb_UNIT	    DB	    ?		; Driver unit number of DPB
dpb_sector_size     DW	    ?		; Size of physical sector in bytes
dpb_cluster_mask    DB	    ?		; Sectors/cluster - 1
dpb_cluster_shift   DB	    ?		; Log2 of sectors/cluster
dpb_first_FAT	    DW	    ?		; Starting record of FATs
dpb_FAT_count	    DB	    ?		; Number of FATs for this drive
dpb_root_entries    DW	    ?		; Number of directory entries
dpb_first_sector    DW	    ?		; First sector of first cluster
dpb_max_cluster     DW	    ?		; Number of clusters on drive + 1
dpb_FAT_size	    DW	    ?		;;Number of records occupied by FAT
dpb_dir_sector	    DW	    ?		; Starting record of directory
dpb_driver_addr     DD	    ?		; Pointer to driver
dpb_media	    DB	    ?		; Media byte
dpb_first_access    DB	    ?		; This is initialized to -1 to force a media
					; check the first time this DPB is used
dpb_next_dpb	    DD	    ?		; Pointer to next Drive parameter block
dpb_next_free	    DW	    ?		; Cluster # of last allocated cluster
dpb_free_cnt	    DW	    ?		; Count of free clusters, -1 if unknown
dpb	ENDS

DPBSIZ	EQU	SIZE dpb		; Size of the structure in bytes

DSKSIZ	=	dpb_max_cluster 	; Size of disk (temp used during init only)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
