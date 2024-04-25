/*******************************************************************************
 * 
 * (C) Copyright Microsoft Corp. 1986
 * 
 *    TITLE:	VDMM
 *
 *    MODULE:	EMM40.C - EMM 4.0 functions code.
 *
 *    VERSION:	0.00
 *
 *    DATE:	Feb 25, 1987
 *
 *******************************************************************************
 *	CHANGE LOG
 *  Date     Version	   Description
 * --------  --------	-------------------------------------------------------
 * 02/25/87	0.00	Orignal
 *
 *******************************************************************************
 *     FUNCTIONAL DESCRIPTION
 *
 * Paged EMM Driver for the iAPX 386.
 * Extra functions defined in the 4.0 spec required by Windows.
 * 
 ******************************************************************************/ 

/******************************************************************************
	INCLUDE FILES
 ******************************************************************************/ 
#include "emm.h"
/*#include "mem_mgr.h"*/


/******************************************************************************
	EXTERNAL DATA STRUCTURES
 ******************************************************************************/ 
/*
 * handle_table
 *	This is an array of handle pointers.
 *	page_index of zero means free
 */
extern struct handle_ptr handle_table[];
extern Handle_Name Handle_Name_Table[]; 	/* Handle names */
extern unsigned short	handle_table_size;	/* number of entries */
extern unsigned short	handle_count;		/* active handle count */

/*
 * EMM Page table
 *	this array contains lists of indexes into the 386
 *	Page Table.  Each list is pointed to by a handle
 *	table entry and is sequential/contiguous.  This is
 *	so that maphandlepage doesn't have to scan a list
 *	for the specified entry.
 */
extern unsigned	short *emm_page;	/* _emm_page array */
extern int	free_count;		/* current free count */
extern int	total_pages;		/* number being managed */
extern unsigned	emmpt_start;		/* next free entry in table */

/*
 * EMM free table
 *	this array is a stack of available page table entries. 
 *	each entry is an index into the pseudo page table
 */
/*extern	unsigned free_stack_count;	/* number of entries */

/*
 * Current status of `HW'. The way this is handled is that
 * when returning status to caller, normal status is reported 
 * via EMMstatus being moved into AX. Persistant errors
 * (such as internal datastructure inconsistancies, etc) are
 * placed in `EMMstatus' as HW failures. All other errors are 
 * transient in nature (out of memory, handles, ...) and are 
 * thus reported by directly setting AX. The EMMstatus variable
 * is provided for expansion and is not currently being
 * set to any other value.
 */
extern unsigned short EMMstatus;

/*
 * 4.0 EXTRAS
 */

extern unsigned short emm40_info[5];		/* hardware information */
extern struct mappable_page mappable_pages[];	/* mappable segments
					           and corresponding pages */
extern short	mappable_page_count;		/* number of entries in above */
extern short	page_frame_pages;		/* pages in the page frame */
extern short	physical_page_count;		/* number of physical pages */
/*extern char	VM1_cntxt_pages;		/* pages in a VM1 context */
/*extern char	VMn_cntxt_pages;		/* pages in a VM context */
/*extern char	VM1_cntxt_bytes;		/* bytes in a VM1 context */
/*extern char	VMn_cntxt_bytes;		/* bytes in a VM context */
extern char cntxt_pages;		/* pages in context */
extern char cntxt_bytes;		/* bytes in context */
extern unsigned short PF_Base;
extern unsigned short VM1_EMM_Pages;
/*extern unsigned short VM1_EMM_Offset;*/
extern long	page_frame_base[];
extern char	EMM_MPindex[];
extern long	OSEnabled;			/* OS/E function flag */
extern long	OSKey;				/* Key for OS/E function */

/******************************************************************************
	EXTERNAL FUNCTIONS
 ******************************************************************************/ 
extern	struct handle_ptr	*valid_handle();	/* validate handle */
extern	unsigned far	*source_addr(); 		/* get DS:SI far ptr */
extern	unsigned far	*dest_addr();			/* get ES:DI far ptr */
extern	unsigned	wcopyb();
extern	unsigned	copyout();
extern	unsigned short	Avail_Pages();


/******************************************************************************
	ROUTINES
 ******************************************************************************/ 

/*
 * Reallocate Pages
 *	parameters:
 *		bx    -- new number of pages
 *		dx    -- handle
 *	returns:
 *		bx    -- new number of pages
 *
 * Change the number of pages allocated to a handle.
 *
 * ISP 5/23/88 Updated for MEMM
 */
ReallocatePages() 
{
#define	handle	((unsigned short)regp->hregs.x.rdx)

	register struct handle_ptr	*hp;
	struct handle_ptr		*hp_save;
	unsigned			new_size;
	register unsigned 		n_pages;
	register unsigned 		next;

	if ( (hp = valid_handle(handle)) == NULL_HANDLE )
		return;		/* (error code already set) */

	setAH((unsigned char)EMMstatus);	/* Assume success */
	new_size = regp->hregs.x.rbx;
	if ( new_size == hp->page_count )
		return;				/* do nothing... */

	if ( new_size > hp->page_count ) {
		if ( new_size > total_pages ) {
			setAH(NOT_ENOUGH_EXT_MEM);
			return;
		}
		n_pages = new_size - hp->page_count;
		if ( n_pages > Avail_Pages() ) {
			setAH(NOT_ENOUGH_FREE_MEM);
			return;
		}
		if ( hp->page_count == 0 )
			next = hp->page_index = emmpt_start;
		else
			next = hp->page_index + hp->page_count;
		hp->page_count = new_size;
		if ( next != emmpt_start ) {
				/*
				 * Must shuffle emm_page array to make room
				 * for the extra pages.  wcopyb correctly
				 * handles this case where the destination
				 * overlaps the source.
				 */
			wcopyb(emm_page+next, emm_page+next+n_pages,
			       emmpt_start - next);
			/* Now tell other handles where their pages went */
			hp_save = hp;
			for ( hp = handle_table;
			      hp < &handle_table[handle_table_size]; hp++ )
				if ( hp->page_index != NULL_PAGE &&
				     hp->page_index >= next )
					hp->page_index += n_pages;
			hp = hp_save;
		}
		emmpt_start += n_pages;
		if ( get_pages(n_pages, next) == NULL_PAGE) { /* strange failure */
			setAH(NOT_ENOUGH_FREE_MEM);
			new_size = hp->page_count - n_pages;  /* as it was! */
			setBX(new_size);
			goto shrink;			/* and undo damage */
		}
	} else {
		/* Shrinking - make handle point to unwanted pages */
	shrink:
		hp->page_count -= new_size;
		hp->page_index += new_size;
		free_pages(hp);    /* free space in emm_page array */
		/* Undo damage to handle, the index was not changed */
		hp->page_count = new_size;
		hp->page_index -= new_size;
	}

#undef	handle
}

/*
 * UndefinedFunction
 *
 * An undefined or unsupported function.
 *
 * 05/10/88  ISP  No update needed
 */
UndefinedFunction() 
{
	setAH(INVALID_FUNCTION);
}

/*
 * Get Mappable Physical Address Array
 *	parameters:
 *		al == 0
 *		es:di -- destination
 *	returns:
 *		cx    -- number of mappable pages
 *
 *	parameters:
 *		al == 1
 *	returns:
 *		cx    -- number of mappable pages
 * 
 * Get the number of mappable pages and the segment address for each
 * physical page.
 *
 * ISP	5/23/88 Updated for MEMM.  u_ptr made into a far pointer.
 */
GetMappablePAddrArray() 
{
	unsigned far *u_ptr;
	int	n_pages;
	int	i;
	struct mappable_page *mp = mappable_pages;

		n_pages = mappable_page_count;

	if ( regp->hregs.h.ral == 0 ) {
		if ( n_pages > 0 ) {
			u_ptr = dest_addr();		/* ES:DI */
			for (i=0 ; i < 48 ; i++)
				if (EMM_MPindex[i] != -1)
					copyout(((struct mappable_page far *)u_ptr)++,
						mp + EMM_MPindex[i],
						sizeof(struct mappable_page) );
		}
	} else if ( regp->hregs.h.ral != 1 ) {
		setAH(INVALID_SUBFUNCTION);
		return;
	}
	setCX(n_pages);
	setAH((unsigned char)EMMstatus);
}

/*
 * Get Expanded Memory Hardware Information
 *	parameters:
 *		al == 0
 *		es:di -- user array
 *	returns:
 *		es:di[0] = raw page size in paragraphs
 *		es:di[2] = number of EXTRA fast register sets
 *		es:di[4] = number of bytes needed to save a context 
 *		es:di[6] = number of settable DMA channels
 *
 *	parameters:
 *		al == 1
 *	returns:
 *		bx = number of free raw pages
 *		dx = total number of raw pages
 *		
 * ISP	5/23/88 Updated for MEMM. Made u_ptr into far ptr.
 */
GetInformation() 
{
	unsigned far *u_ptr;
	unsigned pages;

	if ( OSEnabled >= OS_DISABLED ) {
		setAH(ACCESS_DENIED);		/* Denied by operating system */
		return;
	}

	if ( regp->hregs.h.ral == 0 ) {
		u_ptr = dest_addr();		/* ES:DI */
		emm40_info[2] = (short)cntxt_bytes;	/* update size */
		copyout(u_ptr, emm40_info, sizeof(emm40_info));
		setAH((unsigned char)EMMstatus);
	} else if ( regp->hregs.h.ral == 1 ) {
		GetUnallocatedPageCount();	/* Use existing code */
	} else
		setAH(INVALID_SUBFUNCTION);
}

/*
 * GetSetHandleAttribute
 *
 *	parameters:
 *		al == 0
 *	returns:
 *		al == 0 -- volatile handles
 *
 *	parameters:
 *		al == 1
 *	returns:
 *		ah = 91h -- Feature not supported
 *
 *	parameters:
 *		al == 2
 *	returns:
 *		al == 0 -- Supports ONLY volatile handles
 *
 * 05/09/88 ISP No update needed
 */
GetSetHandleAttribute()
{
#define	handle	((unsigned short)regp->hregs.x.rdx)

	if ( regp->hregs.h.ral == 0 ) {
		if (valid_handle(handle) == NULL_HANDLE)
			return;						/* (error code already set) */
		setAX(EMMstatus << 8);		/* AL = 0 [volatile attribute] */
	} else if ( regp->hregs.h.ral == 1 ) {
		setAH(FEATURE_NOT_SUPPORTED);
	} else if ( regp->hregs.h.ral == 2 ) {
		setAX(EMMstatus << 8);		/* AL = 0 [volatile attribute] */
	} else
		setAH(INVALID_SUBFUNCTION);

#undef	handle
}




/*
 * GetSetHandleName
 *
 *  Subfunction 0 Gets the name of a given handle
 *  Subfunction 1 Sets a new name for handle
 *
 *	parameters:
 *		al == 0
 *		es:di == Data area to copy handle name to
 *		dx    -- handle
 *	returns:
 *		[es:di] == Name of DX handle
 *
 *	parameters:
 *		al == 1
 *		ds:si == new handle name
 *		dx    -- handle
 *	returns:
 *		ah = Status
 *
 * ISP 5/23/88 Updated for MEMM. Name made into far *. Copyin routine used
 *	       to copy name in into handle name table.
 */
GetSetHandleName()
{
	register unsigned short handle = ((unsigned short)regp->hregs.x.rdx);
	register char far *Name;

    /* Validate subfunction */
	if ( (regp->hregs.h.ral != 0) && (regp->hregs.h.ral != 1) ) {
		setAH(INVALID_SUBFUNCTION);
		return;
	}

    /* Validate handle */

	if ( valid_handle(handle) == NULL_HANDLE )
		return; 	/* (error code already set) */

    /* Implement subfunctions 0 and 1 */
	if ( regp->hregs.h.ral == 0 ) {
		Name = (char far *)dest_addr(); 	   /* ES:DI */
		copyout(Name, Handle_Name_Table[handle & 0xFF], Handle_Name_Len);
		setAH((unsigned char)EMMstatus);
	} else if ( regp->hregs.h.ral == 1 ) {
		GetHandleDirectory();		/* See if already there */
		switch ( regp->hregs.h.rah ) {
		case NAMED_HANDLE_NOT_FOUND:
			break;
		case DUPLICATE_HANDLE_NAMES:
			return;
		default:
			if ( handle == regp->hregs.x.rdx )
				break;		/* same handle, OK */
			regp->hregs.x.rdx = handle;
			setAH(DUPLICATE_HANDLE_NAMES);
			return;
		}
		Name = (char far *)source_addr();
		copyin(Handle_Name_Table[handle & 0xFF], Name, Handle_Name_Len);
		setAH((unsigned char)EMMstatus);
	} else
		setAH(INVALID_SUBFUNCTION);

}




/*
 * GetHandleDirectory
 *
 *  Subfunction 0 Returns a directory of handles and handle names
 *  Subfunction 1 Returns the handle specified by the name at [ds:si]
 *
 *	parameters:
 *		al == 0
 *		es:di == Data area to copy handle name to
 *	returns:
 *		al == Number of entries in the handle_dir array
 *		[es:di] == Handle_Dir array
 *
 *	parameters:
 *		al == 1
 *		[ds:si] == Handle name to locate
 *	returns:
 *		ah == Status
 *
 *	parameters:
 *		al == 2
 *	returns:
 *		bx == Total handles in system
 *
 * ISP 5/23/88 Updated for MEMM.  nameaddress and dir_entry made into far *
 *	       copyin routine used to copy name into local area for search.
 */
GetHandleDirectory()
{
	char far			*NameAddress;
	register struct handle_ptr	*hp;
	struct Handle_Dir_Entry far	*Dir_Entry;
	unsigned short			Handle_Num, Found;
/*
 * since all local variables are allocated on stack (SS seg)
 * and DS and SS has grown apart (ie DS != SS),
 * we need variables in DS seg (ie static variables) to pass
 * to copyout(),copyin() and Names_Match() which expects those
 * parameters that are near pointers to be in DS
 *
 * PC 08/03/88
 */
	static Handle_Name			Name;
	static unsigned short		Real_Handle;

	if ( regp->hregs.h.ral == 0 ) {
		Dir_Entry = (struct Handle_Dir_Entry far *)dest_addr();
		hp = handle_table;
		for (Handle_Num = 0; Handle_Num < handle_table_size; Handle_Num++) {
		    if ( hp->page_index != NULL_PAGE) {
			Real_Handle =  Handle_Num;
			copyout(Dir_Entry, &Real_Handle, sizeof(short));
			copyout(Dir_Entry->Dir_Handle_Name, Handle_Name_Table[Handle_Num], Handle_Name_Len);
			Dir_Entry++;
		    } hp++;
		} setAX((EMMstatus << 8) + handle_count);
	} else if ( regp->hregs.h.ral == 1 ) {
		NameAddress = (char far *)source_addr();
		copyin(Name, NameAddress, Handle_Name_Len);
		hp = handle_table;
		Found = 0;
		Handle_Num = 0;
		while ((Handle_Num < handle_table_size) && (Found < 2)) {
		    if ( hp->page_index != NULL_PAGE ) {
			if (Names_Match(Name, Handle_Name_Table[Handle_Num])) {
			    Found++;
			    Real_Handle = Handle_Num;
			}
		    } hp++;
		    Handle_Num++;
		}
		switch (Found) {
		    case 0:
			setAH((unsigned char)NAMED_HANDLE_NOT_FOUND);
			break;
		    case 1:
			setDX(Real_Handle);
			setAH((unsigned char)EMMstatus);
			break;
		    default:
			setAH((unsigned char)DUPLICATE_HANDLE_NAMES);
		}

	} else if ( regp->hregs.h.ral == 2 ) {
		setBX(handle_table_size);
		setAH((unsigned char)EMMstatus);
	} else
		setAH(INVALID_SUBFUNCTION);

#undef	handle
}

/*
 * Prepare For Warm Boot
 *
 *	Always ready to reboot the system so just return status = OK
 *
 *	parameters:
 *		None
 *	returns:
 *		AH = EMMstatus
 *
 * 05/09/88 ISP No update needed.
 *
 */
PrepareForWarmBoot()
{
	setAH((unsigned char)EMMstatus);
}

/*
 * Enable/Disable OS/E Function Set Functions
 *
 *	Enable/Disable access to functions 26, 28 and 30
 *
 *	parameters:
 *		AL = 0		Enable Functions
 *		AL = 1		Disable Functions
 *		AL = 2		Return Access Key
 *		BX, CX		Access Key
 *	returns:
 *		AH = EMMstatus
 *		BX, CX		Access Key if successful
 *
 * 05/09/88 ISP Updated for MEMM. Removed check for pCurVMID
 *
 */
OSDisable()
{
	unsigned char function = regp->hregs.h.ral;

	if ( function > 2 ) {
		setAH(INVALID_SUBFUNCTION);
		return;
	}

	if ( OSEnabled == OS_IDLE ) {		/* First invocation */
		if ( function == 2 ) {
			setAH(ACCESS_DENIED);
			return;
		}
		OSKey = Get_Key_Val();		/* Suitably random number */
		regp->hregs.x.rbx = (short)OSKey;
		regp->hregs.x.rcx = (short)(OSKey >> 16);
	} else {				/* Check Key */
		if ( (short)OSKey != regp->hregs.x.rbx
		     || (short)(OSKey >> 16) != regp->hregs.x.rcx ) {
			setAH(ACCESS_DENIED);
			return;
		}
	}
	if ( function == 0 )			/* enable */
		OSEnabled = 1;
	else if ( function == 1 )		/* disable */
		OSEnabled = 2;
	else if ( function == 2 )		/* return key */
		OSEnabled = 0;

	setAH((unsigned char)EMMstatus);
}


