/*******************************************************************************
 * 
 * (C) Copyright Microsoft Corp. 1986
 * 
 *    TITLE:	CEMM.EXE - COMPAQ Expanded Memory Manager 386 Driver
 *		EMMLIB.LIB - Expanded Memory Manager Library
 *
 *    MODULE:	EMM.H - EMM includes for "C" code
 *
 *    VERSION:	0.04
 *
 *    DATE:	June 14,1986
 *
 *******************************************************************************
 *	CHANGE LOG
 *  Date     Version	   Description
 * --------  --------	-------------------------------------------------------
 * 06/14/86  Original
 * 06/14/86  0.00	Changed stack frame structure to match new emmdisp.asm
 *			and allow byte regs access (SBP).
 * 06/28/86  0.02	Name change from CEMM386 to CEMM (SBP).
 * 07/06/86  0.04	Changed save area structure (SBP).
 *
 ******************************************************************************/

#define OK			0
#define EMM_SW_MALFUNCTION	0x80
#define EMM_HW_MALFUNCTION	0x81
#define INVALID_HANDLE		0x83
#define INVALID_FUNCTION	0x84
#define NO_MORE_HANDLES		0x85
#define SAVED_PAGE_DEALLOC	0x86
#define NOT_ENOUGH_EXT_MEM	0x87
#define NOT_ENOUGH_FREE_MEM	0x88
#define ZERO_PAGES		0x89
#define LOG_PAGE_RANGE		0x8A
#define PHYS_PAGE_RANGE		0x8B
#define SAVE_AREA_FULL		0x8C
#define MAP_PREV_SAVED		0x8D
#define NO_MAP_SAVED		0x8E
#define INVALID_SUBFUNCTION	0x8F
#define FEATURE_NOT_SUPPORTED	0x91
#define NAMED_HANDLE_NOT_FOUND	0xA0
#define DUPLICATE_HANDLE_NAMES	0xA1
#define ACCESS_DENIED		0xA4

/*
 * various usefull defines
 */
#define PAGE_SIZE	0x1000
#define NULL_HANDLE	(struct handle_ptr *)0x0FFF
#define	NULL_PAGE	0xFFFF
#define NULL_SAVE	(struct save_map *)0

#define	GET		0x00		/* get/set page map sub codes */
#define	SET		0x01
#define	GETSET		0x02
#define	SIZE		0x03

#define EMM_VERSION	0x40
#define Handle_Name_Len 8

/*
 *  defines for INTERNAL vs EXTERNAL current_map save
 */
#define	INTERNAL_SAVE	(unsigned)1
#define	EXTERNAL_SAVE	(unsigned)0

/*
 * page table structure
 */
struct pt {		/* page table structure, HW defined */
	long	pt_entry[1024];
	};

/*
 * Page frame table.
 *	Size is dynamic, based on number of pages
 *	available. Allocated at intialization time.  Each entry
 *	references 4 80386 pages.
 * Note that the lower 12 bits of the page address are used
 * as a link field
 */
union pft386{
	unsigned long	address;
	struct{
		unsigned short	p_handle;
		unsigned short	high;
	} words;
};

/*
 * save_map
 *	This is an array of structures that save the 
 *	current mapping state. Size is dynamically determined.
 */
struct save_map{
	unsigned short	s_handle;
	unsigned short	window[4];
	};
/*
 * handle_table
 *	This is an array of handle pointers. It
 *	is dynamically sized based on the amount of memory being
 *	managed.  
 *	pft_index of NULL_PAGE means free
 */
struct  handle_ptr{
	unsigned short	page_index;	/* index of list header in emm_page */
	unsigned short	page_count;	/* size of list in EMM pages */
	};

/*
 * Handle_Name
 *	This is an 8 character handle name.
 */
typedef char Handle_Name[Handle_Name_Len];

/*
 * Handle_Dir_Entry
 *
 */
struct	Handle_Dir_Entry {
	unsigned short Handle_Value;
	Handle_Name Dir_Handle_Name;
	};


/*
 * register frame on stack
 * 
 * This is the stack frame on entry to the in67 dispatcher
 */
struct reg_frame {
	unsigned short rdi;		/* int 67 entry registers	*/
	unsigned short pad0;
	unsigned short rsi;
	unsigned short pad1;
	unsigned short rbp;
	unsigned short pad2;
	unsigned short rsp;
	unsigned short pad3;
	union {
	    struct {
		unsigned short rbx;
		unsigned short pad4;
		unsigned short rdx;
		unsigned short pad5;
		unsigned short rcx;
		unsigned short pad6;
		unsigned short rax;
		unsigned short pad7;
	    } x;
	    struct {
		unsigned char rbl;
		unsigned char rbh;
		unsigned short pad8;
		unsigned char rdl;
		unsigned char rdh;
		unsigned short pad9;
		unsigned char rcl;
		unsigned char rch;
		unsigned short padA;
		unsigned char ral;
		unsigned char rah;
		unsigned short padB;
	    } h;
	} hregs;
	unsigned short ret_addr;	/* return addr 			*/
	unsigned short rcs;		/* CS segment			*/
	unsigned short PFlag;		/* protected mode flag		*/
	unsigned short rds;		/* int 67 entry DS segment	*/
	unsigned short res;		/* int 67 entry ES segment	*/
	unsigned short rgs;		/* int 67 entry GS segment	*/
	unsigned short rfs;		/* int 67 entry FS segment	*/
	};

extern struct reg_frame  far *regp;
/*
 * macros to set the value of a given register
 * on the stack
 */
#define setAH(xx)	regp->hregs.h.rah = xx
#define setAX(xx)	regp->hregs.x.rax = xx
#define	setBX(xx)	regp->hregs.x.rbx = xx
#define setCX(xx)	regp->hregs.x.rcx = xx
#define setDX(xx)	regp->hregs.x.rdx = xx



/*
 * 4.0 EXTRAS
 */

/*
 * Number of Physical Pages:
 *
 *	LIM 3.2:	Page Frame   ==> 4 x 16k pages
 *	LIM 4.0:	256k to 640k ==> 24 x 16k pages plus 3.2 page frame
 */
#define EMM32_PHYS_PAGES	4
#define EMM40_PHYS_PAGES	(24 + EMM32_PHYS_PAGES)

/*
 * structure of mappable physical page
 */
struct mappable_page {
	unsigned short page_seg;	      /* segment of physical page */
	unsigned short physical_page;	      /* physical page number */
};

/* OS/E Enable/Disable defines */
#define OS_IDLE 	0
#define OS_ENABLED	1
#define OS_DISABLED	2

/*
 * structure of page map `register' bank
 */
struct	PageBankMap {
	unsigned short	pbm_window;
	unsigned char	pbm_map[64];
	};
