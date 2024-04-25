/*static char *SCCSID = "@(#)doscall.h	6.25 86/06/03";*/
/***	doscall.h
 *
 *	Shirleyd
 *	(C) Copyright 1988 Microsoft Corporation
 *	12/13/85
 *
 *	Description:
 *
 *		Function declarations to provide strong type checking
 *		on arguments to DOS 4.0 function calls
 *
 *	Major Modifications 04/28/86 by S. S.
 *	Major Modifications 04/30/86 by K. D.
 *	Minor Modifications 04/30/86 by S. S. (DosTimerAsync/Start)
 *	Major Modifications 05/01/86 by S. S. (fix Sems,add Queues)
 *	Minor Modifications 05/14/86 by K. D. (DosFileLocks)
 *	Minor Modifications 05/16/86 by S. S. (NLS routines)
 *	Minor Modifications 05/20/86 by S. S. (Get/SetPrty,CreateThread)
 *	Minor Modifications 05/20/86 by S. S. (add DosSetVector)
 *	Minor Modifications 06/02/86 by S. S. (GetHugeShift, MuxSemWait)
 *	Major Modifications 06/03/86 by S. S. (Mouse calls)
 */



/***	CursorData - structure that contains the characteristics
 *	of the cursor
 */

struct CursorData {
	unsigned cur_start;		/* Cursor start line */
	unsigned cur_end;		/* Cursor end line */
	unsigned cur_width;		/* Cursor width */
	unsigned cur_attribute;		/* Cursor attribute */
	};



/***	DateTime - structure for date and time */

struct DateTime {
	unsigned char hour;		/* current hour */
	unsigned char minutes;		/* current minute */
	unsigned char seconds;		/* current second */
	unsigned char hundredths;	/* current hundredths of a second */
	unsigned char day;		/* current day */
	unsigned char month;		/* current month */
	unsigned year;			/* current year */
	unsigned timezone;		/* minutes of time west of GMT */
	unsigned char day_of_week;	/* current day of week */
	};



/***	FileFindBuf - structure of area where the filesystem driver
 *	returns the results of the search
 */

struct FileFindBuf {
	unsigned create_date;		/* date of file creation */
	unsigned create_time;		/* time of file creation */
	unsigned access_date;		/* date of last access */
	unsigned access_time;		/* time of last access */
	unsigned write_date;		/* date of last write */
	unsigned write_time;		/* time of last write */
	unsigned long file_size;	/* file size (end of data) */
	unsigned long falloc_size;	/* file allocated size */
	unsigned attributes;		/* attributes of the file */
	char string_len;		/* returned length of ascii name str. */
					/* length does not include null byte */
	char file_name[12];		/* name string */
	};


/***	FileStatus - structure of information list used by DosQFileInfo */

struct FileStatus {
	unsigned create_date;		/* date of file creation */
	unsigned create_time;		/* time of file creation */
	unsigned access_date;		/* date of last access */
	unsigned access_time;		/* time of last access */
	unsigned write_date;		/* date of last write */
	unsigned write_time;		/* time of last write */
	unsigned long file_size;	/* file size (end of data) */
	unsigned long falloc_size;	/* file allocated size */
	unsigned block_size;		/* blocking factor */
	unsigned attributes;		/* attributes of the file */
	};


/***	FSAllocate - structure of file system allocation */

struct FSAllocate {
	unsigned long filsys_id;	/* file system ID */
	unsigned long sec_per_unit;	/* number sectors per allocation unit */
	unsigned long num_units;	/* number of allocation units */
	unsigned long avail_units;	/* avaliable allocation units */
	unsigned bytes_sec;		/* bytes per sector */
	};



/***	KbdStatus - structure in which the keyboard support will information */

struct KbdStatus {
	unsigned length;		/* length in words of data structure */
	unsigned bit_mask;		/* bit mask */
	unsigned turn_around_char;	/* turnaround character */
	unsigned interim_char_flags;	/* interim character flags */
	unsigned shift_state;		/* shift state */
	};



/***	KeyData - structure that contains character data */

struct KeyData {
	char char_code;			/* ASCII character code */
	char scan_code;			/* scan code */
	char status;			/* indicates state of the character */
	unsigned shift_state;		/* state of the shift keys */
	unsigned long time;		/* time stamp of the keystroke */
	};



/***	ModeData - structure that contains characteristics of the mode */

struct ModeData {
	unsigned length;		/* Length of structure */
	char type;			/* Text or graphics */
	char color;			/* Color or monochrome */
	unsigned col;			/* Column resolution */
	unsigned row;			/* Row resolution */
	unsigned hres;			/* horizontal resolution */
	unsigned vres;			/* vertical resolution */
	};




/***	ProcIDsArea - structure of the address of the area where the
 *	ID's will be placed
 */

struct ProcIDsArea {
	unsigned procid_cpid;		/* current process' process ID */
	unsigned procid_ctid;		/* current process' thread ID */
	unsigned procid_ppid;		/* process ID of the parent */
	};



/***	PVBData - structure that contains information about the
 *	physical video buffer
 */

struct PVBData {
	unsigned pvb_size;		/* size of the structure */
	unsigned long pvb_ptr;		/* returns pointer to the pvb buffer */
	unsigned pvb_length;		/* length of PVB */
	unsigned pvb_rows;		/* buffer dimension (rows) */
	unsigned pvb_cols;		/* buffer dimension (cols) */
	char pvb_type;			/* color or mono */
	};



/***	SchedParmsArea - structure of address in which the scheduler
 *	parms will be placed
 */

struct SchedParmsArea {
	char dynvar_flag;		/* dynamic variation flag, 1=enabled */
	char maxwait;			/* maxwait (sec) */
	unsigned mintime;		/* minimum timeslice (ms) */
	unsigned maxtime;		/* maximum timeslice (ms) */
	};



/***	Tasking Processes:
 *
 *		DosCreateThread
 *		DosCwait
 *		DosEnterCritSec
 *		DosExecPgm
 *		DosExit
 *		DosExitCritSec
 *		DosExitList
 *		DosGetPID
 *		DosGetPrty
 *		DosGetSchedParms
 *		DosSetFgnd
 *		DosSetPrty
 *		DosKillProcess
 */



/***	DosCreateThread - Create another thread of execution
 *
 *	Creates an asynchronous thread of execution under the
 *	current process
 */

extern unsigned far pascal DOSCREATETHREAD (
	void (far *)(void),		/* Starting Address for new thread */
	unsigned far *,			/* Address to put new thread ID */
	unsigned char far * );		/* Address of stack for new thread */



/***	DosCwait - Wait for child termination
 *
 *	Places the current thread in a wait state until a child process
 *	has terminated, then returns the ending process' process ID and
 *	termination code.
 */

extern unsigned far pascal DOSCWAIT (
	unsigned,			/* Action (execution) codes */
	unsigned,			/* Wait options */
	unsigned far *,			/* Address to put result code */
	unsigned far *,			/* Address to put process ID */
	unsigned );			/* ProcessID of process to wait for */



/***	DosEnterCritSec - Enter critical section of execution
 *
 *	Disables thread switching for the current process
 */

extern void far pascal DOSENTERCRITSEC (void);



/***	DosExecPgm - Execute a program
 *
 *	Allows a program to request another program be executed as a
 *	child process.	The requestor's process may optionally continue
 *	to execute asynchronous to the new program
 */

extern unsigned far pascal DOSEXECPGM (
	unsigned,			/* 0=synchronous, 1=asynchronous with */
					/* return code discarded, 2=async */
					/* with return code saved */
	unsigned,			/* Trace process */
	char far *,			/* Address of argument string */
	char far *,			/* Address of environment string */
	unsigned far *, 		/* Address to put Process ID */
	char far * );			/* Address of program filename */



/***	DosExit - Exit a program
 *
 *	This call is issued when a thread completes its execution.
 *	The current thread is ended.
 */

extern void far pascal DOSEXIT (
	unsigned,			/* 0=end current thread, 1=end all */
	unsigned );			/* Result Code to save for DosCwait */



/***	DosExitCritSec - Exit critical section of execution
 *
 *	Re-enables thread switching for the current process
 */

extern void far pascal DOSEXITCRITSEC (void);



/***	DosExitList - Routine list for process termination
 *
 *	Maintains a list of routines which are to be executed when the
 *	current process ends, normally or otherwise
 */

extern unsigned far pascal DOSEXITLIST (
	unsigned,			/* Function request code */
	void (far *)(void) );		/* Address of routine to be executed */



/***	DosGetPID - Return process ID
 *
 *	Returns the current process's process ID (PID), thread ID,
 *	and the PID of the process that spawned it
 */

extern void far pascal DOSGETPID (
	struct ProcIDsArea far *);	/* ProcID structure */



/***	DosGetPrty - Get Process's Priority
 *
 *	Allows the caller to learn the priority of a process or thread
 */

extern unsigned far pascal DOSGETPRTY (
	unsigned,			/* Indicate thread or process ID */
	unsigned far *,			/* Address to put priority */
	unsigned );			/* PID of process/thread of interest */



/***	DosGetSchedParms - Get scheduler's parameters
 *
 *	Gets the scheduler's current configuration parameters
 */

extern void far pascal DOSGETSCHEDPARMS (
	struct SchedParmsArea far * );	/* Address to put parameters */



/***	DosSetFgnd - Set Foreground Process
 *
 *	Allows the session manager to designate which process
 *	is to receive favored dispatching
 */

extern unsigned far pascal DOSSETFGND (
	unsigned );			/* Process ID of target process */



/***	DosSetPrty - Set Process Priority
 *
 *	Allows the caller to change the base priority or priority
 *	class of a child process or a thread in the current process
 */

extern unsigned far pascal DOSSETPRTY (
	unsigned,			/* Indicate scope of change */
	unsigned,			/* Priority class to set */
	unsigned,			/* Priority delta to apply */
	unsigned );			/* Process or Thread ID of target */



/***	DosKillProcess - Terminate a Process
 *
 *	Terminates a child process and returns its termination code
 *	to its parent (if any)
 */

extern unsigned far pascal DOSKILLPROCESS (
	unsigned,			/* 0=kill child processes also, */
					/* 1=kill only indicated process */
	unsigned );			/* Process ID of process to end */




/***	Asynchronous Notification (Signals):
 *
 *		DosHoldSignal
 *		DosSendSignal
 *		DosSetSigHandler
 */



/***	DosHoldSignal - Disable / Enable signals
 *
 *	Used to termporarily disable or enable signal processing
 *	for the current process.
 */

extern void far pascal DOSHOLDSIGNAL (
	unsigned );			/* 0=enable signal, 1=disable signal */



/***	DosSendSignal - Issue signal
 *
 *	Used to send a signal event to an arbitrary process or
 *	command subtree.
 */

extern unsigned far pascal DOSSENDSIGNAL (
	unsigned,			/* Process ID to signal */
	unsigned,			/* 0=notify entire subtree, 1=notify */
					/* only the indicated process */
	unsigned,			/* Signal argument */
	unsigned );			/* Signal number */



/***	DosSetSigHandler - Handle Signal
 *
 *	Notifies CP/DOS of a handler for a signal.  It may also be used
 *	to ignore a signal or install a default action for a signal.
 */

extern unsigned far pascal DOSSETSIGHANDLER (
	void (far *)(),			/* Signal handler address */
	unsigned long far *,		/* Address of previous handler */
	unsigned far *,			/* Address of previous action */
	unsigned,			/* Indicate request type */
	unsigned );			/* Signal number */




/***	Pipes:
 *
 *		DosMakePipe
 */



/***	DosMakePipe - Create a Pipe */

extern unsigned far pascal DOSMAKEPIPE (
	unsigned far *,			/* Addr to place the read handle */
	unsigned far *,			/* Addr to place the write handle */
	unsigned );			/* Size to reserve for the pipe */




/***	Queues:
 *
 *		DosCloseQueue
 *		DosCreateQueue
 *		DosOpenQueue
 *		DosPeekQueue
 *		DosPurgeQueue
 *		DosQueryQueue
 *		DosReadQueue
 *		DosWriteQueue
 */

/***	DosCloseQueue - Close a Queue
 *
 *	close a queue which is in use by the requesting process
 *
 */

extern unsigned far pascal DOSCLOSEQUEUE (
	unsigned ) ;			/* queue handle */


/***	DosCreateQueue - Create a Queue
 *
 *	creates a queue to be owned by the requesting process
 *
 */

extern unsigned far pascal DOSCREATEQUEUE (
	unsigned far *,			/* queue handle */
	unsigned,			/* queue priority */
	char far * ) ;			/* queue name */


/***	DosOpenQueue - Open a Queue
 *
 *	opens a queue for the current process
 *
 */

extern unsigned far pascal DOSOPENQUEUE (
	unsigned far *,			/* PID of queue owner */
	unsigned far *,			/* queue handle */
	char far * ) ;			/* queue name */



/***	DosPeekQueue - Peek at a Queue
 *
 *	retrieves an element from a queue without removing it from the queue
 *
 */

extern unsigned far pascal DOSPEEKQUEUE (
	unsigned,			/* queue handle */
	unsigned long far *,		/* pointer to request */
	unsigned far *,			/* length of datum returned */
	unsigned long far *,		/* pointer to address of datum */
	unsigned far *,			/* indicator of datum returned */
	unsigned char,			/* wait indicator for empty queue */
	unsigned char far *,		/* priority of element */
	unsigned long ) ;		/* semaphore handle */



/***	DosPurgeQueue - Purge a Queue
 *
 *	purges all elements from a queue
 *
 */

extern unsigned far pascal DOSPURGEQUEUE (
	unsigned ) ;			/* queue handle */



/***	DosQueryQueue - Query size of a Queue
 *
 *	returns the number of elements in a queue
 *
 */

extern unsigned far pascal DOSQUERYQUEUE (
	unsigned,			/* queue handle */
	unsigned far * );		/* pointer for number of elements */



/***	DosReadQueue - Read from a Queue
 *
 *	retrieves an element from a queue
 *
 */

extern unsigned far pascal DOSREADQUEUE (
	unsigned,			/* queue handle */
	unsigned long far *,		/* pointer to request */
	unsigned far *,			/* length of datum returned */
	unsigned long far *,		/* pointer to address of datum */
	unsigned,			/* indicator of datum returned */
	unsigned char,			/* wait indicator for empty queue */
	unsigned char far *,		/* priority of element */
	unsigned long ) ;		/* semaphore handle */



/***	DosWriteQueue - Write to a Queue
 *
 *	adds an element to a queue
 *
 */

extern unsigned far pascal DOSWRITEQUEUE (
	unsigned,			/* queue handle */
	unsigned,			/* request */
	unsigned,			/* length of datum */
	unsigned char far *,		/* address of datum */
	unsigned char );		/* priority of element */





/***	Semaphores:
 *
 *		DosSemClear
 *		DosSemRequest
 *		DosSemSet
 *		DosSemWait
 *		DosSemSetWait
 *		DosMuxSemWait
 *		DosCloseSem
 *		DosCreatSem
 *		DosOpenSem
 */



/***	DosSemClear - Unconditionally clears a semaphore
 *
 *	Unconditionally clears a semaphore; i.e., sets the
 *	state of the specified semaphore to unowned.
 */

extern unsigned far pascal DOSSEMCLEAR (
	unsigned long );		/* semaphore handle */



/***	DosSemRequest - Wait until next DosSemClear
 *
 *	Blocks the current thread until the next DosSemClear is
 *	issued to the indicated semaphore
 */

extern unsigned far pascal DOSSEMREQUEST (
	unsigned long,			/* semaphore handle */
	unsigned long );		/* Timeout, -1=no timeout, */
					/* 0=immediate timeout, >1=number ms */


/***	DosSemSet - Unconditionally take a semaphore
 *
 *	Unconditionally takes a semaphore; i.e., sets the status
 *	of the specified semaphore to owned.
 */

extern unsigned far pascal DOSSEMSET (
	unsigned long );		/* semaphore handle */



/***	DosSemSetWait - Wait for a semaphore to be cleared and set it
 *
 *	Blocks the current thread until the indicated semaphore is
 *	cleared and then establishes ownership of the semaphore
 */

extern unsigned far pascal DOSSEMSETWAIT (
	unsigned long,			/* semaphore handle */
	unsigned long );		/* Timeout, -1=no timeout, */
					/* 0=immediate timeout, >1=number ms */


/***	DosSemWait - Wait for a semaphore to be cleared
 *
 *	Blocks the current thread until the indicated semaphore is
 *	cleared but does not establish ownership of the semaphore
 */

extern unsigned far pascal DOSSEMWAIT (
	unsigned long,			/* semaphore handle */
	unsigned long );		/* Timeout, -1=no timeout, */
					/* 0=immediate timeout, >1=number ms */


/***	DosMuxSemWait - Wait for 1 of N semaphores to be cleared
 *
 *	Blocks the current thread until the indicated semaphore is
 *	cleared but does not establish ownership of the semaphore
 */

extern unsigned far pascal DOSMUXSEMWAIT (
	unsigned far *,			/* address for event index number */
	unsigned far *,			/* list of semaphores */
	unsigned long );		/* Timeout, -1=no timeout, */
					/* 0=immediate timeout, >1=number ms */



/***	DosCloseSem - Close a system semaphore
 *
 *	closed the specified system semaphore
 */

extern unsigned far pascal DOSCLOSESEM (
	unsigned long );		/* semaphore handle */



/***	DosCreateSem - Create a system semaphore
 *
 *	create a system semaphore
 */

extern unsigned far pascal DOSCREATESEM (
	unsigned,			/* =0 indicates exclusive ownership */
	unsigned long far *,		/* address for semaphore handle */
	char far * );			/* name of semaphore */


/***	DosOpenSem - Open a system semaphore
 *
 *	open a system semaphore
 */

extern unsigned far pascal DOSOPENSEM (
	unsigned long far *,		/* address for semaphore handle */
	char far * );			/* name of semaphore */




/***	Timer Services:
 *
 *		DosGetDateTime
 *		DosSetDateTime
 *		DosSleep
 *		DosGetTimerInt
 *		DosTimerAsync
 *		DosTimerStart
 *		DosTimerStop
 */



/***	DosGetDateTime - Get the current date and time
 *
 *	Used to get the current date and time that are maintained by
 *	the operating system
 */

extern unsigned far pascal DOSGETDATETIME (
	struct DateTime far * );



/***	DosSetDateTime - Set the current date and time
 *
 *	Used to set the date and time that are maintained by the
 *	operating system
 */

extern unsigned far pascal DOSSETDATETIME (
	struct DateTime far * );



/***	DosSleep - Delay Process Execution
 *
 *	Suspends the current thread for a specified interval of time,
 *	or if the requested interval is '0', simply gives up the
 *	remainder of the current time slice.
 */

extern unsigned far pascal DOSSLEEP (
	unsigned long );		/* TimeInterval - interval size */



/***	DosGetTimerInt - Get the timer tick interval in 1/10000 sec.
 *
 *	Gets a word that contains the timer tick interval in ten
 *	thousandths of a second.  This is the amount of time that
 *	elapses with every timer tick
 */

extern unsigned far pascal DOSGETTIMERINT (
	unsigned far * );		/* interval size */



/***	DosTimerAsync - Start an asynchronous time delay
 *
 *	Starts a timer that runs asynchronously to the thread issuing
 *	the request.  It sets a RAM semaphore which can be used by the
 *	wait facility
 */

extern unsigned far pascal DOSTIMERASYNC (
	unsigned long,			/* Interval size */
	unsigned long,			/* handle of semaphore */
	unsigned far * );		/* handle of timer */



/***	DosTimerStart - Start a Periodic Interval Timer
 *
 *	Starts a periodic interval timer that runs asynchronously to
 *	the thread issuing the request.  It sets a RAM semaphore which
 *	can be used by the wait facility.  The semaphore is continually
 *	signalled at the specified time interval until the timer is
 *	turned off by DosTimerStop
 */

extern unsigned far pascal DOSTIMERSTART (
	unsigned long,			/* Interval size */
	unsigned long,			/* handle of semaphore */
	unsigned far * );		/* handle of timer */



/***	DosTimerStop - Stop an interval timer
 *
 *	Stops an interval timer that was started by DosTimerStart
 */

extern unsigned far pascal DOSTIMERSTOP (
	unsigned );			/* Handle of the timer */




/***	Memory Management:
 *
 *		DosAllocSeg
 *		DosAllocShrSeg
 *		DosGetShrSeg
 *		DosReallocSeg
 *		DosFreeSeg
 *		DosAllocHuge
 *		DosGetHugeShift
 *		DosReallocHuge
 *		DosCreateCSAlias
 */



/***	DosAllocSeg - Allocate Segment
 *
 *	Allocates a segment of memory to the requesting process.
 */

extern unsigned far pascal DOSALLOCSEG (
	unsigned,			/* Number of bytes requested */
	unsigned far *,			/* Selector allocated (returned) */
	unsigned );			/* Indicator for sharing */



/***	DosAllocShrSeg - Allocate Shared Segment
 *
 *	Allocates a shared memory segment to a process.
 */

extern unsigned far pascal DOSALLOCSHRSEG (
	unsigned,			/* Number of bytes requested */
	char far *,			/* Name string */
	unsigned far * );		/* Selector allocated (returned) */



/***	DosGetShrSeg - Access Shared Segment
 *
 *	Allows a process to access a shared memory segment previously
 *	allocated by another process.  The reference count for the
 *	shared segment is incremented.
 */

extern unsigned far pascal DOSGETSHRSEG (
	char far *,			/* Name string */
	unsigned far * );		/* Selector (returned) */



/***	DosGiveSeg - Give access to Segment
 *
 *	Gives another process access to a shares memory segment
 */

extern unsigned far pascal DOSGIVESEG (
	unsigned,			/* Caller's segment handle */
	unsigned,			/* Process ID of recipient */
	unsigned far * );		/* Recipient's segment handle */



/***	DosReallocSeg - Change Segment Size
 *
 *	Changes the size of a segment already allocated.
 */

extern unsigned far pascal DOSREALLOCSEG (
	unsigned,			/* New size requested in bytes */
	unsigned );			/* Selector */



/***	DosFreeSeg - Free a Segment
 *
 *	Deallocates a segment
 */

extern unsigned far pascal DOSFREESEG (
	unsigned );			/* Selector */



/***	DosAllocHuge - Allocate Huge Memory
 *
 *	Allocates memory greater than the maximum segment size
 */

extern unsigned far pascal DOSALLOCHUGE (
	unsigned,			/* Number of 65536 byte segments */
	unsigned,			/* Number of bytes in last segment */
	unsigned far *,			/* Selector allocated (returned) */
	unsigned );			/* Max number of 65536-byte segments */



/***	DosGetHugeShift - Get shift count used with Huge Segments
 *
 *	Returns the shift count used in deriving selectors
 *	to address memory allocated by DosAllocHuge.
 */

extern unsigned far pascal DOSGETHUGESHIFT (
	unsigned far *);		/* Shift Count (returned) */



/***	DosReallocHuge - Change Huge Memory Size
 *
 *	Changes the size of memory originally allocated by DosAllocHuge
 */

extern unsigned far pascal DOSREALLOCHUGE (
	unsigned,			/* Number of 65536 byte segments */
	unsigned,			/* Number of bytes in last segment */
	unsigned );			/* Selector */



/***	DosCreateCSAlias - Create CS Alias
 *
 *	Creates an alias descriptor for a data type descriptor passed
 *	as input.  The type of the new descriptor is executable.
 */

extern unsigned far pascal DOSCREATECSALIAS (
	unsigned,			/* Data segment selector */
	unsigned far * );		/* Code segment selector (returned) */




/***	Memory Sub-Allocation Package (MSP)
 *
 *		DosSubAlloc
 *		DosSubFree
 *		DosSubSet
 */



/***	DosSubAlloc - Allocate Memory
 *
 *	Allocates memory from a segment previously allocated by
 *	DosAllocSeg or DosAllocShrSeg and initialized by DosSubSet
 */

extern unsigned far pascal DOSSUBALLOC (
	unsigned,			/* Segment selector */
	unsigned far *,			/* Address of block offset */
	unsigned );			/* Size of requested block */



/***	DosSubFree - Free Memory
 *
 *	Frees memory previously allocated by DosSubAlloc
 */

extern unsigned far pascal DOSSUBFREE (
	unsigned,			/* Segment selector */
	unsigned,			/* Offset of memory block to free */
	unsigned );			/* Size of block in bytes */



/***	DosSubSet - Initialize or Set Allocated Memory
 *
 *	Can be used either to initialize a segment for sub-allocation
 *	of to notify MSP of a change in the size of a segment already
 *	initialized.
 */

extern unsigned far pascal DOSSUBSET (
	unsigned,			/* Segment selector */
	unsigned,			/* Parameter flags */
	unsigned );			/* New size of the block */




/***	Program Execution Control:
 *
 *		DosLoadModule
 *		DosFreeModule
 *		DosGetProcAddr
 *		DosGetModHandle
 *		DosGetModName
 */



/***	DosLoadModule - Load Dynamic Link Routines
 *
 *	Loads a dynamic link module and returns a handle for the module
 */

extern unsigned far pascal DOSLOADMODULE (
	char far *,			/* Module name string */
	unsigned far * );		/* Module handle (returned) */



/***	DosFreeModule - Free Dynamic Link Routines
 *
 *	Frees the reference to the dynamic link module for this process.
 *	If the dynamic link module is no longer used by any process, the
 *	module will be freed from system memory.
 */

extern unsigned far pascal DOSFREEMODULE (
	unsigned );			/* Module handle */



/***	DosGetProcAddr - Get Dynamic Link Procedure Address
 *
 *	Retruns a far address to the desired procedure within a dynamic
 *	link module.
 */

extern unsigned far pascal DOSGETPROCADDR (
	unsigned,			/* Module handle */
	char far *,			/* Module name string */
	unsigned long far * );		/* Procedure address (returned) */



/***	DosGetModHandle - Get Dynamic Link Module Handle
 *
 *	Returns the handle to a dynamic link module that was previously
 *	loaded.  The interface provides a mechanism for testing whether
 *	a dynamic link module is already loaded.
 */

extern unsigned far pascal DOSGETMODHANDLE (
	char far *,			/* Module name string */
	unsigned far *);		/* Module handle (returned) */



/***	DosGetModName - Get Dynamic Link Module Name
 *
 *	returns the fully qualified drive, path, filename, and
 *	extension associated with the referenced modul handle
 */

extern unsigned far pascal DOSGETMODNAME (
	unsigned,			/* Module handle */
	unsigned,			/* Maximum buffer length */
	unsigned far * );		/* Buffer (returned) */




/***	Device I/O Services:
 *
 *		DosBeep
 *		DosDevConfig
 *		DosDevIOCtl
 *		DosScrDirectIO
 *		DosScrRedrawWait
 *		DosScrLock
 *		DosScrUnLock
 *		DosSGInit
 *		DosSGNum
 *		DosSGRestore
 *		DosSGSave
 *		DosSGSwitch
 *		DosSGSwitchMe
 *		DosVioAttach
 *		DosVioRegister
 *		KbdCharIn
 *		KbdFlushBuffer
 *		KbdGetStatus
 *		KbdPeek
 *		KbdSetStatus
 *		KbdStringIn
 *		VioRegister
 *		VioFreePhysBuf
 *		VioGetBuf
 *		VioGetCurPos
 *		VioGetCurType
 *		VioGetMode
 *		VioGetPhysBuf
 *		VioReadCellStr
 *		VioReadCharStr
 *		VioScrollDn
 *		VioScrollUp
 *		VioScrollLf
 *		VioScrollRt
 *		VioSetCurPos
 *		VioSetCurType
 *		VioSetMode
 *		VioShowBuf
 *		VioWrtCellStr
 *		VioWrtCharStr
 *		VioWrtCharStrAtt
 *		VioWrtNAttr
 *		VioWrtNCell
 *		VioWrtNChar
 *		VioWrtTTY
 *		VioSetANSI
 *		VioGetANSI
 *		VioPrtScreen
 *		VioSaveRedrawWait
 *		VioSaveRedrawWaitUndo
 *		VioScrLock
 *		VioScrUnlock
 *		VioSetMnLockTime
 *		VioSetMXSaveTime
 *		VioGetTimes
 *		VioPopUp
 *		VioEndPopUp
 */



/***	DosBeep - Generate Sound From Speaker */

extern unsigned far pascal DOSBEEP (
	unsigned,			/* Hertz (25H-7FFFH) */
	unsigned );			/* Length of sound  in ms */



/***	DosDevConfig - Get Device Configurations
 *
 *	Get information about attached devices
 */

extern unsigned far pascal DOSDEVCONFIG (
	unsigned char far *,		/* Returned information */
	unsigned,			/* Item number */
	unsigned );			/* Reserved */



/***	DosDevIOCtl - Preform Control Functions Directly On Device
 *
 *	Control functions on the device specified by the opened
 *	handle
 */

extern unsigned far pascal DOSDEVIOCTL (
	char far *,			/* Data area */
	char far *,			/* Command-specific argument list */
	unsigned,			/* Device-specific function code */
	unsigned,			/* Device category */
	unsigned );			/* Device handle returned by Open */



/***	DosScrDirectIO - Direct Screen I/O
 *
 *	Indicate direct screen I/O
 */

extern unsigned far pascal DOSSCRDIRECTIO (
	unsigned );			/* Indicates state of direct I/O */
					/* 0=on, 1=off */



/***	DosScrRedrawWait - Screen Refresh
 *
 *	Wait for notification to refresh or redraw screen
 */

extern unsigned far pascal DOSSCRREDRAWWAIT (void);



/***	DosScrLock - Lock Screen
 *
 *	Lock the screen for I/O
 */

extern unsigned far pascal DOSSCRLOCK (
	unsigned,			/* Block or not - 0=return if */
					/* screen unavailable, 1=wait */
	unsigned far *);		/* Return status of lock - */
					/* 0=sucessful, 1=unsuccessful */



/***	DosScrUnLock - Unlock Screen
 *
 *	Unlock the screen for I/O
 */

extern unsigned far pascal DOSSCRUNLOCK (void) ;



/***	DosSGInit - Initialize Screen Group
 *
 *	Initialize the specified screen group
 */

extern unsigned far pascal DOSSGINIT (
	unsigned );			/* Number of screen group */



/***	DosSGNum - Get Number of Screen Groups
 *
 *	Get the number of screen groups
 */

extern unsigned far pascal DOSSGNUM (
	unsigned far *);		/* Total number of screen groups */



/***	DosSGRestore - Restore Screen Group
 *
 *	Restore the current screen group
 */

extern unsigned far pascal DOSSGRESTORE (void);



/***	DosSGSave - Save Screen Group
 *
 *	Save the current screen group
 */

extern unsigned far pascal DOSSGSAVE (void);



/***	DosSGSwitch - Switch Screen Groups
 *
 *	Switch the specified screen group to the active screen group
 */

extern unsigned far pascal DOSSGSWITCH (
	unsigned );			/* Number of screen group */



/***	DosSGSwitchMe - Put Process in Screen Group
 *
 *	Switch the caller into the specified screen group
 */

extern unsigned far pascal DOSSGSWITCHME (
	unsigned );			/* Number of screen groups */



/***	DosVioAttach - Attach to Video Subsystem
 *
 *	Attach to the current video subsystem for the current screen
 *	group.	This must be done prior to using any VIO functions.
 */

extern unsigned far pascal DOSVIOATTACH (void);



/***	DosVioRegister - Register Video Subsystem
 *
 *	Register a video subsystem for a screen group
 */

extern unsigned far pascal DOSVIOREGISTER (
	char far *,			/* Module name */
	char far * );			/* Table of entries supported by */
					/* the VIO dynamic link module */



/***	KbdCharIn - Read Character, Scan Code
 *
 *	Return a character and scan code from the standard input device
 */

extern unsigned far pascal KBDCHARIN (
	struct KeyData far *,		/* Buffer for character code */
	unsigned,			/* I/O wait - 0=wait for a */
					/* character, 1=no wait */
	unsigned );			/* keyboard handle */



/***	KbdFlushBuffer - Flush Keystroke Buffer
 *
 *	Clear the keystroke buffer
 */

extern unsigned far pascal KBDFLUSHBUFFER (
	unsigned );			/* keyboard handle */



/***	KbdGetStatus - Get Keyboard Status
 *
 *	Gets the current state of the keyboard.
 */

extern unsigned far pascal KBDGETSTATUS (
	struct KbdStatus far *,		/* data structure */
	unsigned );			/* Keyboard device handle */



/***	KbdPeek - Peek at Character, Scan Code
 *
 *	Return the character/scan code, if available, from the
 *	standard input device without removing it from the buffer.
 */

extern unsigned far pascal KBDPEEK (
	struct KeyData far *,		/* buffer for data */
	unsigned );			/* keyboard handle */



/***	KbdSetStatus - Set Keyboard Status
 *
 *	Sets the characteristics of the keyboard.
 */

extern unsigned far pascal KBDSETSTATUS (
	struct KbdStatus far *,		/* data structure */
	unsigned );			/* device handle */



/***	KbdStringIn - Read Character String
 *
 *	Read a character string (character codes only) from the
 *	standard input device.	The character string may optionally
 *	be echoed at the standard output device if the echo mode
 *	is set (KbdSetEchoMode)
 */

extern unsigned far pascal KBDSTRINGIN (
	char far *,			/* Char string buffer */
	unsigned far *,			/* Length of buffer */
	unsigned,			/* I/O wait- 0=wait for a */
					/* character, 1=no wait */
	unsigned );			/* keyboard handle */



/***	VioRegister - Register Video Subsystem
 *
 *	Register a video subsystem within a screen group
 *
 */

extern unsigned far pascal VIOREGISTER (
	char far *,			/* Module name */
	char far *,			/* Entry Point name */
	unsigned long,			/* Function mask 1 */
	unsigned long );		/* Function mask 2 */



/***	VioFreePhysBuf - Free Physical Video Buffer
 *
 *	Release the physical video buffer
 */

extern unsigned far pascal VIOFREEPHYSBUF (
	char far * );			/* Physical video buffer */



/***	VioGetBuf - Get Logical Video Buffer
 *
 *	Return the address of the logical video buffer
 */

extern unsigned far pascal VIOGETBUF (
	unsigned long far *,		/* Will point to logical video buffer */
	unsigned far *,			/* Length of Buffer */
	unsigned );			/* Vio Handle */



/***	VioGetCurPos - Get Cursor Position
 *
 *	Return the cursor position
 */

extern unsigned far pascal VIOGETCURPOS (
	unsigned far *,			/* Current row position */
	unsigned far *,			/* Current column position */
	unsigned );			/* Vio Handle */



/***	VioGetCurType - Get Cursor Type
 *
 *	Return the cursor type
 */

extern unsigned far pascal VIOGETCURTYPE (
	struct CursorData far *,	/* Cursor characteristics */
	unsigned );			/* Vio Handle */



/***	VioGetMode - Get Display Mode
 *
 *	Return the mode of the display
 */

extern unsigned far pascal VIOGETMODE (
	struct ModeData far *,		/* Length of Buffer */
	unsigned );			/* Vio Handle */



/***	VioGetPhysBuf - Get Physical Video Buffer
 *
 *	Return the address of the physical video buffer
 */

extern unsigned far pascal VIOGETPHYSBUF (
	char far *,			/* Buffer start address */
	char far *,			/* Buffer end address */
	unsigned far *,			/* Address of selector list */
	unsigned );			/* Length of selector list */



/***	VioReadCellStr - Read Character/Attributes String
 *
 *	Read a string of character/attributes (or cells) from the
 *	screen starting at the specified location.
 */

extern unsigned far pascal VIOREADCELLSTR (
	char far *,			/* Character Buffer */
	unsigned far *,			/* Length of cell string buffer */
	unsigned,			/* Starting location (row) */
	unsigned,			/* Starting location (col) */
	unsigned );			/* Vio Handle */



/***	VioReadCharStr - Read Character String
 *
 *	Read a character string from the display starting at the
 *	current cursor position
 */

extern unsigned far pascal VIOREADCHARSTR (
	char far *,			/* Character Buffer */
	unsigned far *,			/* Length of cell string buffer */
	unsigned,			/* Starting location (row) */
	unsigned,			/* Starting location (col) */
	unsigned );			/* Vio Handle */



/***	VioScrollDn - Scroll Screen Down
 *
 *	Scroll the current screen down
 */

extern unsigned far pascal VIOSCROLLDN (
	unsigned,			/* Top row of section to scroll */
	unsigned,			/* Left column of section to scroll */
	unsigned,			/* Bottom row of section to scroll */
	unsigned,			/* Right column of section to scroll */
	unsigned,			/* Number of blank lines at bottom */
	char far *,			/* pointer to blank Char,Attr */
	unsigned );			/* Vio Handle */



/***	VioScrollUp - Scroll Screen Up
 *
 *	Scroll the active page (or display) up
 */

extern unsigned far pascal VIOSCROLLUP (
	unsigned,			/* Top row of section to scroll */
	unsigned,			/* Left column of section to scroll */
	unsigned,			/* Bottom row of section to scroll */
	unsigned,			/* Right column of section to scroll */
	unsigned,			/* Number of blank lines at bottom */
	char far *,			/* pointer to blank Char,Attr */
	unsigned );			/* Vio Handle */



/***	VioScrollLf - Scroll Screen Left
 *
 *	Scroll the current screen left
 */

extern unsigned far pascal VIOSCROLLLF (
	unsigned,			/* Top row of section to scroll */
	unsigned,			/* Left column of section to scroll */
	unsigned,			/* Bottom row of section to scroll */
	unsigned,			/* Right column of section to scroll */
	unsigned,			/* Number of blank columsn at right */
	char far *,			/* pointer to blank Char,Attr */
	unsigned );			/* Vio Handle */



/***	VioScrollLf - Scroll Screen Right
 *
 *	Scroll the current screen right
 */

extern unsigned far pascal VIOSCROLLRT (
	unsigned,			/* Top row of section to scroll */
	unsigned,			/* Left column of section to scroll */
	unsigned,			/* Bottom row of section to scroll */
	unsigned,			/* Right column of section to scroll */
	unsigned,			/* Number of blank columsn at left */
	char far *,			/* pointer to blank Char,Attr */
	unsigned );			/* Vio Handle */



/***	VioSetCurPos - Set Cursor Position
 *
 *	Set the cursor position
 */

extern unsigned far pascal VIOSETCURPOS (
	unsigned,			/* Row return data */
	unsigned,			/* Column return data */
	unsigned );			/* Vio Handle */



/***	VioSetCurType - Set Cursor Type
 *
 *	Set the cursor type
 */

extern unsigned far pascal VIOSETCURTYPE (
	struct CursorData far *,	/* Cursor characteristics */
	unsigned );			/* Vio Handle */



/***	VioSetMode - Set Display Mode
 *
 *	Set the mode of the display
 */

extern unsigned far pascal VIOSETMODE (
	struct ModeData far *,		/* Mode characteristics */
	unsigned );			/* Vio Handle */



/***	VioShowBuf - Display Logical Buffer
 *
 *	Update the display with the logical video buffer
 */

extern unsigned far pascal VIOSHOWBUF (
	unsigned,			/* Offset into buffer */
	unsigned,			/* Length of area to be updated */
	unsigned );			/* Vio Handle */



/***	VioWrtCellStr - Write Character/Attribute String
 *
 *	Write a character,attribute string to the display
 */

extern unsigned far pascal VIOWRTCELLSTR (
	char far *,			/* String to be written */
	unsigned,			/* Length of string */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	unsigned );			/* Vio Handle */



/***	VioWrtCharStr - Write Character String
 *
 *	Write a character string to the display
 */

extern unsigned far pascal VIOWRTCHARSTR (
	char far *,			/* String to be written */
	unsigned,			/* Length of string */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	unsigned );			/* Vio Handle */



/***	VioWrtCharStrAtt - Write Character String With Attribute
 *
 *	Write a character string with repeated attribute to the display
 */

extern unsigned far pascal VIOWRTCHARSTRATT (
	char far *,			/* String to be written */
	unsigned,			/* Length of string */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	char far *,			/* Attribute to be replicated */
	unsigned );			/* Vio Handle */



/***	VioWrtNAttr - Write N Attributes
 *
 *	Write an attribute to the display a specified number of times
 */

extern unsigned far pascal VIOWRTNATTR (
	char far *,			/* Attribute to be written */
	unsigned,			/* Length of write */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	unsigned );			/* Vio Handle */



/***	VioWrtNCell - Write N Character/Attributes
 *
 *	Write a cell (or character/attribute) to the display a
 *	specified number of times
 */

extern unsigned far pascal VIOWRTNCELL (
	char far *,			/* Cell to be written */
	unsigned,			/* Length of write */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	unsigned );			/* Vio Handle */



/***	VioWrtNChar - Write N Characters
 *
 *	Write a character to the display a specified number of times
 */

extern unsigned far pascal VIOWRTNCHAR (
	unsigned,			/* Character to be written */
	unsigned,			/* Length of write */
	unsigned,			/* Starting position for output (row) */
	unsigned,			/* Starting position for output (col) */
	unsigned );			/* Vio Handle */



/***	VioWrtTTY - Write TTY String
 *
 *	Write a character string from the current cursor position in
 *	TTY mode to the display.  The cursor will be positioned at the
 *	end of the string+1 at the end of the write.
 */

extern unsigned far pascal VIOWRTTTY (
	char far *,			/* String to be written */
	unsigned,			/* Length of string */
	unsigned );			/* Vio Handle */



/***	VioSetAnsi - Set ANSI On or Off
 *
 *	Activates or deactivates ANSI support
 *
 */

extern unsigned far pascal VIOSETANSI (
	unsigned,			/* ON (=1) or OFF (=0) indicator */
	unsigned );			/* Vio Handle */



/***	VioGetAnsi - Get ANSI State
 *
 *	Returns the current ANSI state (0=inactive, 1=active)
 *
 */

extern unsigned far pascal VIOGETANSI (
	unsigned far *,			/* ANSI state (returned) */
	unsigned );			/* Vio Handle */



/***	VioPrtScreen - Print Screen
 *
 *	Copies the screen to the printer
 *
 */

extern unsigned far pascal VIOPRTSCREEN (
	unsigned );			/* Vio Handle */



/***	VioSaveRedrWait - Screen Save Redraw Wait
 *
 *	Allows a process to be notified when it must
 *	save or redraw its screen
 *
 */

extern unsigned far pascal VIOSAVEREDRAWWAIT (
	unsigned,			/* Save/Redraw Indicator */
	unsigned far *,			/* Notify type (returned) */
	unsigned );			/* Vio Handle */



/***	VioSaveRedrWaitUndo - Undo Screen Save Redraw Wait
 *
 *	Allows a one thread within a process to cancel a
 *	VIOSAVREDRAWWAIT issued by another thread within
 *	that same process.  Ownership of the VIOSAVREDRAWWAIT
 *	can either be reserved or given up.
 *
 */

extern unsigned far pascal VIOSAVEREDRAWWAITUNDO (
	unsigned,			/* Ownership Indicator */
	unsigned,			/* Terminate Indicator */
	unsigned );			/* Vio Handle */



/***	VioScrLock -  Lock Screen
 *
 *	Tells a process if I/O to the physical screen buffer can occur.
 *
 */

extern unsigned far pascal VIOSCRLOCK (
	unsigned,			/* Wait Flag */
	unsigned char far *,		/* Status of lock (returned) */
	unsigned );			/* Vio Handle */



/***	VioScrUnlock -	Unlock Screen
 *
 *	Unlocks the physical screen buffer for I/O.
 *
 */

extern unsigned far pascal VIOSCRUNLOCK (
	unsigned );			/* Vio Handle */



/***	VioSetMnLockTime - Set Minimum Screen Lock Time
 *
 *	Sets the minimum amount of time that the system will allow a
 *	process to have exclusive use of the screen via VIOSCRLOCK.
 *
 */

extern unsigned far pascal VIOSETMNLOCKTIME (
	unsigned,			/* Number of seconds */
	unsigned );			/* Vio Handle */



/***	VioSetMxSaveTime - Set Maximum Screen Save/Restore Time
 *
 *	Sets the maximum amount of time (in msec) that the system will
 *	allow a process to take before issuing a VIOSAVREDRWAIT call
 *	after being notified by the Session Mgr that one is needed.
 *
 */

extern unsigned far pascal VIOSETMXSAVETIME (
	unsigned,			/* Number of milliseconds */
	unsigned );			/* Vio Handle */



/***	VioGetTimes - Return VIO Lock and Save/Redraw Times
 *
 *	Returns the 2 word values set by the calls
 *	VIOSETMNLOCKTIME and VIOSETMXSAVETIME.
 *
 */

extern unsigned far pascal VIOGETTIMES (
	unsigned far *,			/* Min. Lock time (in seconds) */
	unsigned far *,			/* Max. Save time (in msec) */
	unsigned );			/* Vio Handle */



/***	VioPopUp - Allocate a PopUp Display Screen
 *
 *	Creates a temporary window to display a momentary message
 *
 */

extern unsigned far pascal VIOPOPUP (
	unsigned far *,			/* Wait/Nowait Bit flags */
	unsigned );			/* Vio Handle */



/***	VioEndPopUp - Deallocate a PopUp Display Screen
 *
 *	Closes a PopUp window
 *
 */

extern unsigned far pascal VIOENDPOPUP (
	unsigned );			/* Vio Handle */




/***	Mouse Services
 *
 *	MouRegister
 *	MouGetNumButtons
 *	MouGetNumMickeys
 *	MouGetDevStatus
 *	MouReadEventQueue
 *	MouGetNumQueEl
 *	MouGetEventMask
 *	MouGetScaleFact
 *	MouSetScaleFact
 *	MouSetEventMask
 *	MouOpen
 *	MouClose
 *	MouSetPtrShape
 *	MouRemovePtr
 *	MouDrawPtr
 *	MouSetHotKey
 */


/***	MouRegister - Register a Mouse Subsystem or Environment Manager
 *
 */

extern unsigned far pascal MOUREGISTER (
	char far *,			/* Module name */
	char far *,			/* Entry Point name */
	unsigned long,			/* Function mask */
	unsigned );			/* Mouse Device Handle */



/***	MouGetNumButtons - returns the number of mouse buttons supported
 *
 */

extern unsigned far pascal MOUGETNUMBUTTONS (
	unsigned far *,			/* Number of mouse buttons (returned) */
	unsigned );			/* Mouse Device Handle */



/***	MouGetNumMickeys - returns the number of mickeys per centimeter
 *
 */

extern unsigned far pascal MOUGETNUMMICKEYS (
	unsigned far *,			/* Number of Mickeys/cm (returned) */
	unsigned );			/* Mouse Device Handle */



/***	MouGetDevStatus - returns the mouse driver status flags
 *
 */

extern unsigned far pascal MOUGETDEVSTATUS (
	unsigned far *,			/* Device Status (returned) */
	unsigned );			/* Mouse Device Handle */



/***	MouReadEventQueue - reads an event from the mouse event queue
 *
 */

extern unsigned far pascal MOUREADEVENTQUEUE (
	unsigned,			/* Type of read operation */
	unsigned char far *,		/* Event Queue Entry (returned) */
	unsigned );			/* Mouse Device Handle */



/***	MouGetNumQueEl - returns the status of the Mouse Event Queue
 *
 */

extern unsigned far pascal MOUGETNUMQUEEL (
	unsigned far *,			/* Maximum # of Elements in Queue */
	unsigned far *,			/* Current # of Elements in Queue */
	unsigned );			/* Mouse Device Handle */



/***	MouGetEventMask - Returns the current mouse 1-word event mask
 *
 */

extern unsigned far pascal MOUGETEVENTMASK (
	unsigned far *,			/* Event Mask (returned) */
	unsigned );			/* Mouse Device Handle */



/***	MouGetScaleFact - Returns the current mouse scaling factors
 *
 */

extern unsigned far pascal MOUGETSCALEFACT (
	unsigned far *,			/* Y Coordinate Scaling Factor */
	unsigned far *,			/* X Coordinate Scaling Factor */
	unsigned );			/* Mouse Device Handle */



/***	MouSetScaleFact - Sets the current mouse scaling factors
 *
 */

extern unsigned far pascal MOUSETSCALEFACT (
	unsigned,			/* Y Coordinate Scaling Factor */
	unsigned,			/* X Coordinate Scaling Factor */
	unsigned );			/* Mouse Device Handle */



/***	MouSetEventMask - Set the current mouse 1-word event mask
 *
 */

extern unsigned far pascal MOUSETEVENTMASK (
	unsigned,			/* Event Mask */
	unsigned );			/* Mouse Device Handle */



/***	MouOpen - Open the mouse device
 *
 */

extern unsigned far pascal MOUOPEN (
	unsigned far * );		/* Mouse Device Handle (returned) */



/***	MouClose - Close the mouse device
 *
 */

extern unsigned far pascal MOUCLOSE (
	unsigned );			/* Mouse Device Handle */



/***	MouSetPtrShape - Set the shape and size of the mouse pointer image
 *
 */

extern unsigned far pascal MOUSETPTRSHAPE (
	unsigned char far *,		/* Pointer Shape (returned) */
	unsigned long,			/* Size of data passed */
	unsigned,			/* Height of Ptr Shape */
	unsigned,			/* Width of Ptr Shape */
	unsigned,			/* Offset to Ptr Column Center */
	unsigned,			/* Offset to Ptr Row Center */
	unsigned );			/* Mouse Device Handle */



/***	MouRemovePtr - Restricts the Mouse Ptr from occurring in a region
 *
 */

extern unsigned far pascal MOUREMOVEPTR (
	unsigned far *,			/* Pointer Area */
	unsigned );			/* Mouse Device Handle */



/***	MouDrawPtr - Unrestricts the Mouse Ptr
 *
 */

extern unsigned far pascal MOUDRAWPTR (
	unsigned );			/* Mouse Device Handle */


/***	MouSetHotKey - Determines which Mouse Key is the system hot key
 *
 */

extern unsigned far pascal MOUSETHOTKEY (
	unsigned,			/* Mouse Button Mask */
	unsigned );			/* Mouse Device Handle */




/***	Device Monitor Services
 *
 *		DosMonOpen
 *		DosMonClose
 *		DosMonReg
 *		DosMonRead
 *		DosMonWrite
 */



/***	DosMonOpen - Open a Connection to a CP/DOS Device Monitor
 *
 *	This call is issued once by a process which wishes to use
 *	device monitors
 */

extern unsigned far pascal DOSMONOPEN (
	char far *,			/* Ascii string of device name */
	unsigned far * );		/* Address for handle return value */



/***	DosMonClose - Close a Connection to a CP/DOS Device Monitor
 *
 *	This call is issued once by a process which wishes to terminate
 *	monitoring.  This call causes all monitor buffers associated to
 *	be flushed and closed.
 */

extern unsigned far pascal DOSMONCLOSE (
	unsigned );			/* Handle from DosMonOpen */



/***	DosMonReg - Register a Set of Buffers as a Monitor
 *
 *	This call is issued to establish a pair of buffer structures -
 *	one input and one output - to monitor an I/O stream
 */

extern unsigned far pascal DOSMONREG (
	unsigned,			/* Handle from DosMonOpen */
	unsigned char far *,		/* Address of monitor input buffer */
	unsigned char far *,		/* Address of monitor output buffer */
	unsigned,			/* Position flag - 0=no positional */
					/* preference, 1=front of list, */
					/* 2=back of the list */
	unsigned );			/* Index */



/***	DosMonRead - Read Input From Monitor Structure
 *
 *	This call is issued to wait for and read input records from
 *	the monitor buffer structure
 */

extern unsigned far pascal DOSMONREAD (
	unsigned char far *,		/* Address of monitor input buffer */
	unsigned char,			/* Block/Run indicator - 0=block */
					/* input ready, 1=return */
	unsigned char far *,		/* Address of data buffer */
	unsigned far * );		/* Number of bytes in the data record */



/***	DosMonWrite - Write Output to Monitor Structure
 *
 *	Writes data to the monitor output buffer structure
 */

extern unsigned far pascal DOSMONWRITE (
	unsigned char far *,		/* Address of monitor output buffer */
	unsigned char far *,		/* Address of data buffer */
	unsigned );			/* Number of bytes in data record */




/***	File I/O Services:
 *
 *		DosBufReset
 *		DosChdir
 *		DosChgFilePtr
 *		DosClose
 *		DosCreateUn
 *		DosDelete
 *		DosDupHandle
 *		DosFindClose
 *		DosFindFirst
 *		DosFindNext
 *		DosFileLocks
 *		DosGetInfoSeg
 *		DosMkdir
 *		DosMove
 *		DosNewSize
 *		DosOpen
 *		DosQCurDir
 *		DosQCurDisk
 *		DosQFHandState
 *		DosQFileInfo
 *		DosQFileMode
 *		DosQFSInfo
 *		DosQHandType
 *		DosQSwitChar
 *		DosQVerify
 *		DosRead
 *		DosReadAsync
 *		DosRmdir
 *		DosSelectDisk
 *		DosSetFileInfo
 *		DosSetFileMode
 *		DosSetFHandState
 *		DosSetFSInfo
 *		DosSetMaxFH
 *		DosSetVerify
 *		DosWrite
 *		DosWriteAsync
 */



/***	DosBufReset - Commit File's Cache Buffers
 *
 *	Flushes requesting process's cache buffers for the specified
 *	format
 */

extern unsigned far pascal DOSBUFRESET (
	unsigned );			/* File handle */



/***	DosChdir - Change The Current Directory
 *
 *	Define the current directory for the requesting process
 */

extern unsigned far pascal DOSCHDIR (
	char far *,			/* Directory path name */
	unsigned long );		/* Reserved (must be 0) */



/***	DosChgFilePtr - Change (Move) File Read Write Pointer
 *
 *	Move the read/write pointer according to the method specified
 */

extern unsigned far pascal DOSCHGFILEPTR (
	unsigned,			/* File handle */
	long,				/* Distance to move in bytes */
	unsigned,			/* Method of moving (0,1,2) */
	unsigned long far * );		/* New pointer location */



/***	DosClose - Close a File Handle
 *
 *	Closes the specified file handle
 */

extern unsigned far pascal DOSCLOSE (
	unsigned );			/* File handle */



/***	DosCreateUn - Create a Unique File Path Name
 *
 *	Generates a unique file path name
 */

extern unsigned far pascal DOSCREATEUN (
	char far * );			/* File path name area */



/***	DosDelete - Delete a File
 *
 *	Removes a directory entry associated with a filename
 */

extern unsigned far pascal DOSDELETE (
	char far *,			/* Filename path */
	unsigned long );		/* Reserved (must be 0) */



/***	DosDupHandle - Duplicate a File Handle
 *
 *	Returns a new file handle for an open file that refers to the
 *	same file at the same position
 */

extern unsigned far pascal DOSDUPHANDLE (
	unsigned,			/* Existing file handle */
	unsigned far * );		/* New file handle */



/***	DosFindClose - Close Find Handle
 *
 *	Closes the association between a directory handle and a
 *	DosFindFirst or DosFindNext directory search function
 */

extern unsigned far pascal DOSFINDCLOSE (
	unsigned );			/* Directory search handle */



/***	DosFindFirst - Find First Matching File
 *
 *	Finds the first filename that matches the specified file
 *	specification
 */

extern unsigned far pascal DOSFINDFIRST (
	char far *,			/* File path name */
	unsigned far *,			/* Directory search handle */
	unsigned,			/* Search attribute */
	struct FileFindBuf far *,	/* Result buffer */
	unsigned,			/* Result buffer length */
	unsigned far *, 		/* Number of entries to find */
	unsigned long );		/* Reserved (must be 0) */



/***	DosFindNext - Find Next Matching File
 *
 *	Finds the next directory entry matching the name that was
 *	specified on the previous DosFindFirst or DosFindNext function
 *	call
 */

extern unsigned far pascal DOSFINDNEXT (
	unsigned,			/* Directory handle */
	struct FileFindBuf far *,	/* Result buffer */
	unsigned,			/* Result buffer length */
	unsigned far * );		/* Number of entries to find */



/***	DosFileLocks - File Lock Manager
 *
 *	Unlock and/or lock multiple ranges in an opened file
 */

extern unsigned far pascal DOSFILELOCKS (
	unsigned,			/* File handle */
	long far *,			/* Unlock Range */
	long far * );			/* Lock Range */



/***	DosGetInfoSeg - Get addresses of system variable segments
 *
 *	Returns 2 selectors: one for the global information segment,
 *	the other for a process information segment
 */

extern unsigned far pascal DOSGETINFOSEG (
	unsigned far *,			/* Selector for Global Info Seg */
	unsigned far * );		/* Selector for Process Info Seg */



/***	DosMkdir - Make Subdirectory
 *
 *	Creates the specified directory
 */

extern unsigned far pascal DOSMKDIR (
	char far *,			/* New directory name */
	unsigned long );		/* Reserved (must be 0) */



/***	DosMove - Move a file or SubDirectory
 *
 *	Moves the specified file or directory
 */

extern unsigned far pascal DOSMOVE (
	char far *,			/* Old path name */
	char far *,			/* New path name */
	unsigned long );		/* Reserved (must be 0) */



/***	DosNewSize - Change File's Size
 *
 *	Changes a file's size
 */

extern unsigned far pascal DOSNEWSIZE (
	unsigned,			/* File handle */
	unsigned long );		/* File's new size */



/***	DosOpen - Open a File
 *
 *	Creates the specified file (if necessary) and opens it
 */

extern unsigned far pascal DOSOPEN (
	char far *,			/* File path name */
	unsigned far *,			/* New file's handle */
	unsigned far *,			/* Action taken - 1=file existed, */
					/* 2=file was created */
	unsigned long,			/* File primary allocation */
	unsigned,			/* File attributes */
	unsigned,			/* Open function type */
	unsigned,			/* Open mode of the file */
	unsigned long );		/* Reserved (must be zero) */



/***	DosQCurDir - Query Current Directory
 *
 *	Get the full path name of the current directory for the
 *	requesting process for the specified drive
 */

extern unsigned far pascal DOSQCURDIR (
	unsigned,			/* Drive number - 1=A, etc */
	char far *,			/* Directory path buffer */
	unsigned far * );		/* Directory path buffer length */



/***	DosQCurDisk - Query Current Disk
 *
 *	Determine the current default drive for the requesting process
 */

extern unsigned far pascal DOSQCURDISK (
	unsigned far *,			/* Default drive number */
	unsigned long far * );		/* Drive-map area */




/***	DosQFHandState - Query file handle state
 *
 *	Query the state of the specified handle
 */

extern unsigned far pascal DOSQFHANDSTATE (
	unsigned,			/* File Handle */
	unsigned far * );		/* File handle state */



/***	DosQFileInfo - Query a File's Information
 *
 *	Returns information for a specific file
 */

extern unsigned far pascal DOSQFILEINFO (
	unsigned,			/* File handle */
	unsigned,			/* File data required */
	char far *,			/* File data buffer */
	unsigned );			/* File data buffer size */


/***	DosQFileMode - Query File Mode
 *
 *	Get the mode (attribute) of the specified file
 */

extern unsigned far pascal DOSQFILEMODE (
	char far *,			/* File path name */
	unsigned far *,			/* Data area */
	unsigned long );		/* Reserved (must be zero) */



/***	DosQFSInfo - Query File System Information
 *
 *	Gets information from a file system device
 */

extern unsigned far pascal DOSQFSINFO (
	unsigned,			/* Drive number - 0=default, 1=A, etc */
	unsigned,			/* File system info required */
	char far *,			/* File system info buffer */
	unsigned );			/* File system info buffer size */



/***	DosQHandType - Query Handle type
 *
 *	Returns a flag as to whether a handle references a device or
 *	a file, and if a device, returns device driver attribute word
 */

extern unsigned far pascal DOSQHANDTYPE (
	unsigned,			/* File Handle */
	unsigned far *,			/* Handle Type (0=file, 1=device) */
	unsigned far * );		/* Device Driver Attribute Word */



/***	DosQSwitChar - Query Switch Character
 *
 *	Returns the system switch character
 */

extern unsigned far pascal DOSQSWITCHAR (
	unsigned char far * );		/* Switch Character (returned) */



/***	DosQVerify - Query Verify Setting
 *
 *	Returns the value of the Verify flag
 */

extern unsigned far pascal DOSQVERIFY (
	unsigned far * );		/* Verify setting - 0=verify mode */
					/* not active, 1=verify mode active */



/***	DosRead - Read from a File
 *
 *	Reads the specified number of bytes from a file to a
 *	buffer location
 */

extern unsigned far pascal DOSREAD (
	unsigned,			/* File handle */
	char far *,			/* Address of user buffer */
	unsigned,			/* Buffer length */
	unsigned far * );		/* Bytes read */



/***	DosReadAsync - Async Read from a File
 *
 *	Reads the specified number of bytes from a file to a buffer
 *	location asynchronously with respect to the requesting process's
 *	execution
 */

extern unsigned far pascal DOSREADASYNC (
	unsigned,			/* File handle */
	unsigned long far *,		/* Address of Ram semaphore */
	unsigned far *,			/* Address of I/O error return code */
	char far *,			/* Address of user buffer */
	unsigned,			/* Buffer length */
	unsigned far * );		/* Number of bytes actually read */



/***	DosRmDir - Remove Subdirectory
 *
 *	Removes a subdirectory from the specified disk
 */

extern unsigned far pascal DOSRMDIR (
	char far *,			/* Directory name */
	unsigned long );		/* Reserved (must be zero) */



/***	DosSelectDisk - Select Default Drive
 *
 *	Select the drive specified as the default drive for the
 *	calling process
 */

extern unsigned far pascal DOSSELECTDISK (
	unsigned );			/* Default drive number */



/***	DosSetFHandState - Set File Handle State
 *
 *	Get the state of the specified file
 */

extern unsigned far pascal DOSSETFHANDSTATE (
	unsigned,			/* File handle */
	unsigned);			/* File handle state */


/***	DosSetFSInfo - Set File System Information
 *
 *	Set information for a file system device
 */

extern unsigned far pascal DOSSETFSINFO (
	unsigned,			/* Drive number - 0=default, 1=A, etc */
	unsigned,			/* File system info required */
	char far *,			/* File system info buffer */
	unsigned );			/* File system info buffer size */



/***	DosSetFileInfo - Set a File's Information
 *
 *	Specifies information for a file
 */

extern unsigned far pascal DOSSETFILEINFO (
	unsigned,			/* File handle */
	unsigned,			/* File info data required */
	char far *,			/* File info buffer */
	unsigned );			/* File info buffer size */



/***	DosSetFileMode - Set File Mode
 *
 *	Change the mode (attribute) of the specified file
 */

extern unsigned far pascal DOSSETFILEMODE (
	char far *,			/* File path name */
	unsigned,			/* New attribute of file */
	unsigned long );		/* Reserved (must be zero) */



/***	DosSetMaxFH - Set Maximum File Handles
 *
 *	Defines the maximum number of file handles for the
 *	current process
 */

extern unsigned far pascal DOSSETMAXFH (
	unsigned );			/* Number of file handles */



/***	DosSetVerify - Set/Reset Verify Switch
 *
 *	Sets the verify switch
 */

extern unsigned far pascal DOSSETVERIFY (
	unsigned );			/* New value of verify switch */



/***	DosWrite - Synchronous Write to a File
 *
 *	Transfers the specified number of bytes from a buffer to
 *	the specified file, synchronously with respect to the
 *	requesting process's execution
 */

extern unsigned far pascal DOSWRITE (
	unsigned,			/* File handle */
	char far *,			/* Address of user buffer */
	unsigned,			/* Buffer length */
	unsigned far * );		/* Bytes written */



/***	DosWriteAsync - Asynchronous Write to a File
 *
 *	Transfers the specified number of bytes from a buffer to
 *	the specified file, asynchronously with respect to the
 *	requesting process's execution
 */

extern unsigned far pascal DOSWRITEASYNC (
	unsigned,			/* File handle */
	unsigned long far *,		/* Address of RAM semaphore */
	unsigned far *,			/* Address of I/O error return code */
	char far *,			/* Address of user buffer */
	unsigned,			/* Buffer length */
	unsigned far * );		/* Bytes written */




/***	Hard Error Handling
 *
 *		DosError
 */



/***	DosError - Enable Hard Error Processing
 *
 *	Allows a CP/DOS process to receive hard error notification
 *	without generating a hard error signal.  Hard errors generated
 *	under a process which has issued a DosError call are FAILed and
 *	the appropriate error code is returned.
 */

extern unsigned far pascal DOSERROR (
	unsigned );			/* Action flag */



/***	Machine Exception Handling
 *
 *		DosSetVector
 */



/***	DosSetVec - Establish a handler for an Exception
 *
 *	Allows a process to register an address to be
 *	called when a 286 processor exception occurs.
 */

extern unsigned far pascal DOSSETVEC (
	unsigned,			/* Exception Vector */
	void (far *)(void),		/* Address of exception handler */
	void (far * far *)(void) );	/* Address to store previous handler */



/***	Message Functions
 *
 *		DosGetMessage
 *		DosInsMessage
 *		DosPutMessage
 */



/***	DosGetMessage - Return System Message With Variable Text
 *
 *	Retrieves a message from the specified system message file
 *	and inserts variable information into the body of the message
 */

extern unsigned far pascal DOSGETMESSAGE (
	char far * far *,		/* Table of variables to insert */
	unsigned,			/* Number of variables */
	char far *,			/* Address of message buffer */
	unsigned,			/* Length of buffer */
	unsigned,			/* Number of the message */
	char far *,			/* Message file name */
	unsigned far * );		/* Length of returned message */



/***	DosInsMessage - Insert Variable Text into Message
 *
 *	Inserts variable text string information into the body ofa message.
 */

extern unsigned far pascal DOSINSMESSAGE (
	char far * far *,		/* Table of variables to insert */
	unsigned,			/* Number of variables */
	char far *,			/* Address of output buffer */
	unsigned,			/* Length of output buffer */
	unsigned,			/* Length of message */
	char far *,			/* Address of input string */
	unsigned far * );		/* Length of returned message */



/***	DosPutMessage - Output Message Text to Indicated Handle
 *
 *	Outputs a message in a buffer passed by a caller to the
 *	specified handle.  The function formats the buffer to
 *	prevent words from wrapping if displayed to a screen.
 */

extern unsigned far pascal DOSPUTMESSAGE (
	unsigned,			/* Handle of output file/device */
	unsigned,			/* Length of message buffer */
	char far * );			/* Message buffer */



/***	RAS Services
 *
 *		DosSysTrace
 */



/***	DosSysTrace - Add a Trace record to the System Trace Buffer
 *
 *	Allows a subsystem or system extension to add information to the
 *	System trace buffer.  This call can only be made from protected
 *	mode.
 */

extern unsigned far pascal DOSSYSTRACE (
	unsigned,			/* Major trace event code (0-255) */
	unsigned,			/* Length of area to be recorded */
	unsigned,			/* Minor trace event code (0-FFFFH) */
	char far * );			/* Pointer to area to be traced */



/***	Program Startup Conventions
 *
 *		DosGetEnv
 *		DosGetVersion
 */



/***	DosGetEnv - Get the Address of Process' Environment String
 *
 *	Return the address of the current process' environment string
 */

extern unsigned far pascal DOSGETENV (
	unsigned far *,			/* Address to place segment handle */
	unsigned far * );		/* Address for command line start */



/***	DosGetVersion - Get DOS Version
 *
 *	Returns the DOS version number
 */

extern unsigned far pascal DOSGETVERSION (
	unsigned far * );		/* Address to put version number */



/***	World Trade Support
 *
 *	All of these functions declarations have the string NLS in a comment.
 *	This is required in the generation of the Imports Library DOSCALLS.LIB
 *
 *		DosGetCtryInfo
 *		DosSetCtryCode
 *		DosGetDBCSEv
 *		DosCaseMap
 *		DosGetSpecChar
 *		DosCollate
 */



/***	DosGetCtryInfo
 *
 *	Returns the country dependant formatting information that
 *	resides in the NLSCDIT.SYS World Trade Support file
 */

extern unsigned far pascal DOSGETCTRYINFO (			/*<NLS>*/
	unsigned,			/* Length of data area provided */
	unsigned long far *,		/* Country code */
	char far *, 			/* Memory buffer */
	unsigned far * );		/* Length of returned data */



/***	DosSetCrtyCode
 *
 *	Sets the current country code for the system
 */

extern unsigned far pascal DOSSETCTRYCODE (			/*<NLS>*/
	unsigned long far * );		/* Country code */



/***	DosGetDBCSEv - Get the DBCS Environment Vector
 *
 *	Used to obtain the DBCS environmental vector that resides in
 *	the NLSDBCS.SYS World Trade Support file.
 */

extern unsigned far pascal DOSGETDBCSEV (			/*<NLS>*/
	unsigned,			/* Length of data area provided */
	unsigned long far *,		/* Country code */
	char far * );			/* Pointer to data area */



/***	DosCaseMap
 *
 *	Used to perform case mapping on a string of binary values which
 *	represent ASCII characters.
 */

extern unsigned far pascal DOSCASEMAP (				/*<NLS>*/
	unsigned,			/* Length of string to case map */
	unsigned long far *,		/* Country code */
	char far * );			/* Address of string of binary values */



/***	DosGetSpecChar
 *
 *	Gets a list of special characters that are valid in file names, etc.
 *	The list corresponds to the byte values 128-255.
 */

extern unsigned far pascal DOSGETSPECCHAR (			/*<NLS>*/
	unsigned,			/* Length of data area provided */
	unsigned long far *,		/* Country Code */
	unsigned char far * );		/* Data area */



/***	DosCollate
 *
 *	Undocumented NLS feature
 */

extern unsigned far pascal DOSCOLLATE (				/*<NLS>*/
	unsigned,			/* Buffer Length */
	unsigned long far *,		/* Country Code */
	char far * );			/* Buffer Address */



/* End of File */
