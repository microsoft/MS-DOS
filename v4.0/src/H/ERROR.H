/*static char *SCCSID = "@(#)error.h    7.11 86/09/29";*/
/* XENIX calls all return error codes through AX.  If an error occurred then */
/* the carry bit will be set and the error code is in AX.  If no error occurred */
/* then the carry bit is reset and AX contains returned info. */
/* */
/* Since the set of error codes is being extended as we extend the operating */
/* system, we have provided a means for applications to ask the system for a */
/* recommended course of action when they receive an error. */
/* */
/* The GetExtendedError system call returns a universal error, an error */
/* location and a recommended course of action. The universal error code is */
/* a symptom of the error REGARDLESS of the context in which GetExtendedError */
/* is issued. */
/* */

/* */
/* These are the 2.0 error codes */
/* */
#define NO_ERROR			0
#define ERROR_INVALID_FUNCTION		1
#define ERROR_FILE_NOT_FOUND		2
#define ERROR_PATH_NOT_FOUND		3
#define ERROR_TOO_MANY_OPEN_FILES	4
#define ERROR_ACCESS_DENIED		5
#define ERROR_INVALID_HANDLE		6
#define ERROR_ARENA_TRASHED		7
#define ERROR_NOT_ENOUGH_MEMORY 	8
#define ERROR_INVALID_BLOCK		9
#define ERROR_BAD_ENVIRONMENT		10
#define ERROR_BAD_FORMAT		11
#define ERROR_INVALID_ACCESS		12
#define ERROR_INVALID_DATA		13
/***** reserved 		EQU	14	; ***** */
#define ERROR_INVALID_DRIVE		15
#define ERROR_CURRENT_DIRECTORY 	16
#define ERROR_NOT_SAME_DEVICE		17
#define ERROR_NO_MORE_FILES		18
/* */
/* These are the universal int 24 mappings for the old INT 24 set of errors */
/* */
#define ERROR_WRITE_PROTECT		19
#define ERROR_BAD_UNIT			20
#define ERROR_NOT_READY 		21
#define ERROR_BAD_COMMAND		22
#define ERROR_CRC			23
#define ERROR_BAD_LENGTH		24
#define ERROR_SEEK			25
#define ERROR_NOT_DOS_DISK		26
#define ERROR_SECTOR_NOT_FOUND		27
#define ERROR_OUT_OF_PAPER		28
#define ERROR_WRITE_FAULT		29
#define ERROR_READ_FAULT		30
#define ERROR_GEN_FAILURE		31
/* */
/* These are the new 3.0 error codes reported through INT 24 */
/* */
#define ERROR_SHARING_VIOLATION 	32
#define ERROR_LOCK_VIOLATION		33
#define ERROR_WRONG_DISK		34
#define ERROR_FCB_UNAVAILABLE		35
#define ERROR_SHARING_BUFFER_EXCEEDED	36
/* */
/* New OEM network-related errors are 50-79 */
/* */
#define ERROR_NOT_SUPPORTED		50
/* */
/* End of INT 24 reportable errors */
/* */
#define ERROR_FILE_EXISTS		80
#define ERROR_DUP_FCB			81	  /* ***** */
#define ERROR_CANNOT_MAKE		82
#define ERROR_FAIL_I24			83
/* */
/* New 3.0 network related error codes */
/* */
#define ERROR_OUT_OF_STRUCTURES 	84
#define ERROR_ALREADY_ASSIGNED		85
#define ERROR_INVALID_PASSWORD		86
#define ERROR_INVALID_PARAMETER 	87
#define ERROR_NET_WRITE_FAULT		88
/* */
/* New error codes for 4.0 */
/* */
#define ERROR_NO_PROC_SLOTS		89	  /* no process slots available */
#define ERROR_NOT_FROZEN		90
#define ERR_TSTOVFL			91	  /* timer service table overflow */
#define ERR_TSTDUP			92	  /* timer service table duplicate */
#define ERROR_NO_ITEMS			93	  /* There were no items to operate upon */
#define ERROR_INTERRUPT 		95	  /* interrupted system call */

#define ERROR_TOO_MANY_SEMAPHORES	100
#define ERROR_EXCL_SEM_ALREADY_OWNED	101
#define ERROR_SEM_IS_SET		102
#define ERROR_TOO_MANY_SEM_REQUESTS	103
#define ERROR_INVALID_AT_INTERRUPT_TIME 104

#define ERROR_SEM_OWNER_DIED		105	  /* waitsem found owner died */
#define ERROR_SEM_USER_LIMIT		106	  /* too many procs have this sem */
#define ERROR_DISK_CHANGE		107	  /* insert disk b into drive a */
#define ERROR_DRIVE_LOCKED		108	  /* drive locked by another process */
#define ERROR_BROKEN_PIPE		109	  /* write on pipe with no reader */
/* */
/* New error codes for 5.0 */
/* */
#define ERROR_OPEN_FAILED		110	  /* open/created failed due to */
						  /* explicit fail command */
#define ERROR_BUFFER_OVERFLOW		111	  /* buffer passed to system call */
						  /* is too small to hold return */
						  /* data. */
#define ERROR_DISK_FULL 		112	  /* not enough space on the disk */
						  /* (DOSNEWSIZE/w_NewSize) */
#define ERROR_NO_MORE_SEARCH_HANDLES	113	  /* can't allocate another search */
						  /* structure and handle. */
						  /* (DOSFINDFIRST/w_FindFirst) */
#define ERROR_INVALID_TARGET_HANDLE	114	  /* Target handle in DOSDUPHANDLE */
						  /* is invalid */
#define ERROR_PROTECTION_VIOLATION	115	  /* Bad user virtual address */
#define ERROR_VIOKBD_REQUEST		116
#define ERROR_INVALID_CATEGORY		117	  /* Category for DEVIOCTL in not */
						  /* defined */
#define ERROR_INVALID_VERIFY_SWITCH	118	  /* invalid value passed for */
						  /* verify flag */
#define ERROR_BAD_DRIVER_LEVEL		119	  /* DosDevIOCTL looks for a level */
						  /* four driver.	If the driver */
						  /* is not level four we return */
						  /* this code */
#define ERROR_CALL_NOT_IMPLEMENTED	120	  /* returned from stub api calls. */
						  /* This call will disappear when */
						  /* all the api's are implemented. */
#define ERROR_SEM_TIMEOUT		121	  /* Time out happened from the */
						  /* semaphore api functions. */
#define ERROR_INSUFFICIENT_BUFFER	122	  /* Some call require the  */
					  /* application to pass in a buffer */
					  /* filled with data.	This error is */
					  /* returned if the data buffer is too */
					  /* small.  For example: DosSetFileInfo */
					  /* requires 4 bytes of data.	If a */
					  /* two byte buffer is passed in then */
					  /* this error is returned.   */
					  /* error_buffer_overflow is used when */
					  /* the output buffer in not big enough. */
#define ERROR_INVALID_NAME		123	  /* illegal character or malformed */
						  /* file system name */
#define ERROR_INVALID_LEVEL		124	  /* unimplemented level for info */
						  /* retrieval or setting */
#define ERROR_NO_VOLUME_LABEL		125	  /* no volume label found with */
						  /* DosQFSInfo command */
#define ERROR_MOD_NOT_FOUND		126	  /* w_getprocaddr,w_getmodhandle */
#define ERROR_PROC_NOT_FOUND		127	  /* w_getprocaddr */

#define ERROR_WAIT_NO_CHILDREN		128	  /* CWait finds to children */

#define ERROR_CHILD_NOT_COMPLETE	129	  /* CWait children not dead yet */

#define ERROR_DIRECT_ACCESS_HANDLE	130	  /* handle operation is invalid */
						  /* for direct disk access */
						  /* handles */
#define ERROR_NEGATIVE_SEEK		131	  /* application tried to seek	*/
						  /* with negitive offset */
#define ERROR_SEEK_ON_DEVICE		132	  /* application tried to seek */
						  /* on device or pipe */
/* */
/* The following are errors generated by the join and subst workers */
/* */
#define ERROR_IS_JOIN_TARGET		133
#define ERROR_IS_JOINED 		134
#define ERROR_IS_SUBSTED		135
#define ERROR_NOT_JOINED		136
#define ERROR_NOT_SUBSTED		137
#define ERROR_JOIN_TO_JOIN		138
#define ERROR_SUBST_TO_SUBST		139
#define ERROR_JOIN_TO_SUBST		140
#define ERROR_SUBST_TO_JOIN		141
#define ERROR_BUSY_DRIVE		142
#define ERROR_SAME_DRIVE		143
#define ERROR_DIR_NOT_ROOT		144
#define ERROR_DIR_NOT_EMPTY		145
#define ERROR_IS_SUBST_PATH		146
#define ERROR_IS_JOIN_PATH		147
#define ERROR_PATH_BUSY 		148
#define ERROR_IS_SUBST_TARGET		149
#define ERROR_SYSTEM_TRACE		150	/* system trace error */
#define ERROR_INVALID_EVENT_COUNT	151	/* DosMuxSemWait errors */
#define ERROR_TOO_MANY_MUXWAITERS	152
#define ERROR_INVALID_LIST_FORMAT	153
#define ERROR_LABEL_TOO_LONG		154
#define ERROR_TOO_MANY_TCBS		155
#define ERROR_SIGNAL_REFUSED		156
#define ERROR_DISCARDED 		157
#define ERROR_NOT_LOCKED		158
#define ERROR_BAD_THREADID_ADDR 	159
#define ERROR_BAD_ARGUMENTS		160
#define ERROR_BAD_PATHNAME		161
#define ERROR_SIGNAL_PENDING		162
#define ERROR_UNCERTAIN_MEDIA		163
#define ERROR_MAX_THRDS_REACHED 	164

#define ERROR_INVALID_SEGMENT_NUMBER	180
#define ERROR_INVALID_CALLGATE		181
#define ERROR_INVALID_ORDINAL		182
#define ERROR_ALREADY_EXISTS		183
#define ERROR_NO_CHILD_PROCESS		184
#define ERROR_CHILD_ALIVE_NOWAIT	185
#define ERROR_INVALID_FLAG_NUMBER	186
#define ERROR_SEM_NOT_FOUND		187

/*	following error codes have added  to make the loader error
	messages distinct
*/

#define ERROR_EXCEEDED_SYS_STACKLIMIT		188	/* wrw! */
#define ERROR_INVALID_STARTING_CODESEG		189
#define ERROR_INVALID_STACKSEG			190
#define ERROR_INVALID_MODULETYPE		191
#define ERROR_INVALID_EXE_SIGNATURE		192
#define ERROR_EXE_MARKED_INVALID		193
#define ERROR_BAD_EXE_FORMAT			194
#define ERROR_ITERATED_DATA_EXCEEDS_64k 	195
#define ERROR_INVALID_MINALLOCSIZE		196
#define ERROR_DYNLINK_FROM_INVALID_RING 	197
#define ERROR_IOPL_NOT_ENABLED			198
#define ERROR_INVALID_SEGDPL			199
#define ERROR_AUTODATASEG_EXCEEDS_64k		200
#define ERROR_RING2SEGS_MUST_BE_MOVABLE 	201	/* wrw! */
#define ERR_RELOCSRC_CHAIN_OVER_SEGLIM		202	/* wrw! */

#define ERROR_USER_DEFINED_BASE 	0xF000

#define ERROR_I24_WRITE_PROTECT 	0
#define ERROR_I24_BAD_UNIT		1
#define ERROR_I24_NOT_READY		2
#define ERROR_I24_BAD_COMMAND		3
#define ERROR_I24_CRC			4
#define ERROR_I24_BAD_LENGTH		5
#define ERROR_I24_SEEK			6
#define ERROR_I24_NOT_DOS_DISK		7
#define ERROR_I24_SECTOR_NOT_FOUND	8
#define ERROR_I24_OUT_OF_PAPER		9
#define ERROR_I24_WRITE_FAULT		0x0A
#define ERROR_I24_READ_FAULT		0x0B
#define ERROR_I24_GEN_FAILURE		0x0C
#define ERROR_I24_DISK_CHANGE		0x0D
#define ERROR_I24_WRONG_DISK		0x0F
#define ERROR_I24_UNCERTAIN_MEDIA	0x10
#define ERROR_I24_CHAR_CALL_INTERRUPTED 0x11

#define ALLOWED_FAIL			0x0001
#define ALLOWED_ABORT			0x0002
#define ALLOWED_RETRY			0x0004
#define ALLOWED_IGNORE			0x0008

#define I24_OPERATION			0x1
#define I24_AREA			0x6
							  /* 01 if FAT */
							  /* 10 if root DIR */
							  /* 11 if DATA */
#define I24_CLASS			0x80


/* Values for error CLASS */

#define ERRCLASS_OUTRES 		1	  /* Out of Resource */
#define ERRCLASS_TEMPSIT		2	  /* Temporary Situation */
#define ERRCLASS_AUTH			3	  /* Permission problem */
#define ERRCLASS_INTRN			4	  /* Internal System Error */
#define ERRCLASS_HRDFAIL		5	  /* Hardware Failure */
#define ERRCLASS_SYSFAIL		6	  /* System Failure */
#define ERRCLASS_APPERR 		7	  /* Application Error */
#define ERRCLASS_NOTFND 		8	  /* Not Found */
#define ERRCLASS_BADFMT 		9	  /* Bad Format */
#define ERRCLASS_LOCKED 		10	  /* Locked */
#define ERRCLASS_MEDIA			11	  /* Media Failure */
#define ERRCLASS_ALREADY		12	  /* Collision with Existing Item */
#define ERRCLASS_UNK			13	  /* Unknown/other */
#define ERRCLASS_CANT			14
#define ERRCLASS_TIME			15

/* Values for error ACTION */

#define ERRACT_RETRY			1	  /* Retry */
#define ERRACT_DLYRET			2	  /* Delay Retry, retry after pause */
#define ERRACT_USER			3	  /* Ask user to regive info */
#define ERRACT_ABORT			4	  /* abort with clean up */
#define ERRACT_PANIC			5	  /* abort immediately */
#define ERRACT_IGNORE			6	  /* ignore */
#define ERRACT_INTRET			7	  /* Retry after User Intervention */

/* Values for error LOCUS */

#define ERRLOC_UNK			1	  /* No appropriate value */
#define ERRLOC_DISK			2	  /* Random Access Mass Storage */
#define ERRLOC_NET			3	  /* Network */
#define ERRLOC_SERDEV			4	  /* Serial Device */
#define ERRLOC_MEM			5	  /* Memory */
