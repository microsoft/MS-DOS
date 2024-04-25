/*      SCCSID = @(#)basemid.h	8.26 87/05/21 */

#define MSG_RESPONSE_DATA               0         /* data for valid responses (Y N A R I) */
#define MSG_INVALID_FUNCTION            1         /* Invalid function */
#define MSG_FILE_NOT_FOUND              2         /* File not found */
#define MSG_PATH_NOT_FOUND              3         /* Path not found */
#define MSG_OUT_OF_HANDLES              4         /* Too many open files, no handles left */
#define MSG_ACCESS_DENIED               5         /* Access denied */
#define MSG_INVALID_HANDLE              6         /* Invalid handle */
#define MSG_MEMORY_BLOCKS_BAD           7         /* Memory control blocks destroyed */
#define MSG_NO_MEMORY                   8         /* Insufficient memory */
#define MSG_INVALID_MEM_ADDR            9         /* Invalid memory block address */
#define MSG_INVALID_ENVIRON             10        /* Invalid environment */
#define MSG_INVALID_FORMAT              11        /* Invalid format */
#define MSG_INVALID_ACC_CODE            12        /* Invalid access code */
#define MSG_INVALID_DATA                13        /* Invalid data */
#define MSG_14                          14        /* Reserved */
#define MSG_INVALID_DRIVE               15        /* Invalid drive */
#define MSG_ATT_RD_CURDIR               16        /* Attempt to remove current directory */
#define MSG_NOT_SAME_DEVICE             17        /* Not same device */
#define MSG_NO_MORE_FILES               18        /* No more files */
#define MSG_ATT_WRITE_PROT              19        /* Attempted write on protected disk */
#define MSG_UNKNOWN_UNIT                20        /* Unknown unit */
#define MSG_DRIVE_NOT_READY             21        /* Drive not ready */
#define MSG_UNKNOWN_COMMAND             22        /* Unknown command */
#define MSG_DATA_ERROR                  23        /* Data error (CRC) */
#define MSG_BAD_REQ_STRUCTURE           24        /* Bad request structure length */
#define MSG_SEEK_ERROR                  25        /* Seek error */
#define MSG_UNKNOWN_MEDIA               26        /* Unknown media type */
#define MSG_SECTOR_NOT_FOUND            27        /* Sector not found */
#define MSG_OUT_OF_PAPER                28        /* Printer out of paper */
#define MSG_WRITE_FAULT                 29        /* Write fault */
#define MSG_READ_FAULT                  30        /* Read fault */
#define MSG_GENERAL_FAILURE             31        /* General failure */
#define MSG_SHARING_VIOLATION           32        /* Sharing violation */
#define MSG_SHAR_VIOLAT_FIND            32        /* sharing violation find */
#define MSG_LOCK_VIOLATION              33        /* Lock violation */
#define MSG_INVALID_DISK_CHANGE         34        /* Invalid disk change */
#define MSG_35                          35        /* FCB unavailable */
#define MSG_SHARING_BUFF_OFLOW          36        /* Sharing buffer overflow */
/* msg 37 - 49 reserved */
#define MSG_NET_REQ_NOT_SUPPORT         50        /* net request not supported */
#define MSG_NET_REMOTE_NOT_ONLINE       51        /* remote computer not online */
#define MSG_NET_DUP_FILENAME            52        /* duplicate filename on network */
#define MSG_NET_PATH_NOT_FOUND          53        /* network path not found */
#define MSG_NET_BUSY                    54        /* network is busy */
#define MSG_NET_DEV_NOT_INSTALLED       55        /* device no longer installed */
#define MSG_NET_BIOS_LIMIT_REACHED      56        /* BIOS command limit exceeded */
#define MSG_NET_ADAPT_HRDW_ERROR        57        /* adapter hardware error */
#define MSG_NET_INCORRECT_RESPONSE      58        /* network response incorrect */
#define MSG_NET_UNEXPECT_ERROR          59        /* unexpected network error */
#define MSG_NET_REMOT_ADPT_INCOMP       60        /* remote adapter is incompatible */
#define MSG_NET_PRINT_Q_FULL            61        /* print queue is full */
#define MSG_NET_NO_SPACE_TO_PRINT_FL    62        /* not enough space to print file */
#define MSG_NET_PRINT_FILE_DELETED      63        /* print file was deleted */
#define MSG_NET_NAME_DELETED            64        /* network name was deleted */
#define MSG_NET_ACCESS_DENIED           65        /* network access denied */
#define MSG_NET_DEV_TYPE_INVALID        66        /* network device type invalid */
#define MSG_NET_NAME_NOT_FOUND          67        /* network name cannot be found */
#define MSG_NET_NAME_LIMIT_EXCEED       68        /* net name limit was exceeded */
#define MSG_NET_BIOS_LIMIT_EXCEED       69        /* BIOS session limit exceeded */
#define MSG_NET_TEMP_PAUSED             70        /* net is temporarily paused */
#define MSG_NET_REQUEST_DENIED          71        /* net request was denied */
#define MSG_NET_PRT_DSK_REDIR_PAUSE     72        /* print or disk redirection paused */
/* msg 73 - 79 reserved */
#define MSG_FILE_EXISTS                 80
/* msg 81 reserved */
#define MSG_CANNOT_MAKE                 82
#define MSG_NET_FAIL_INT_TWO_FOUR       83        /* fail on int 24 */
#define MSG_NET_TOO_MANY_REDIRECT       84        /* too many net redirections */
#define MSG_NET_DUP_REDIRECTION         85        /* duplicate redirection */
#define MSG_NET_INVALID_PASSWORD        86        /* invalid password */
#define MSG_NET_INCORR_PARAMETER        87        /* incorrect net parameter */
#define MSG_NET_DATA_FAULT              88        /* net data fault */
#define MSG_NO_PROC_SLOTS               89        /* no process slots */
#define MSG_DISK_CHANGE                 107
#define MSG_DRIVE_LOCKED                108
#define MSG_ERROR_OPEN_FAILED           110       /* error open failed */
#define MSG_DISK_FULL                   112
#define MSG_NO_SEARCH_HANDLES           113
#define MSG_ERR_INV_TAR_HANDLE          114       /* error invalid target handle */
#define MSG_BAD_DRIVER_LEVEL            119       /* bad driver level */
#define MSG_INVALID_NAME                123
#define MSG_NO_VOLUME_LABEL             125
/* */
#define MSG_JOIN_ON_DRIV_IS_TAR         133       /* directory on drive is target of a jo */
#define MSG_JOIN_DRIVE_IS               134       /* drive is joined */
#define MSG_SUB_DRIVE_IS                135       /* drive is substed */
#define MSG_DRIVE_IS_NOT_JOINED         136       /* drive is not joined */
#define MSG_DRIVE_NOT_SUBSTED           137       /* drive is not substituted - subst */
#define MSG_JOIN_CANNOT_JOIN_DRIVE      138       /* cannot join to a joined drive */
#define MSG_SUB_CANNOT_SUBST_DRIVE      139       /* cannot sub to sub drive */
#define MSG_JOIN_CANNOT_SUB_DRIVE       140       /* cannot join to a substed drive */
#define MSG_SUB_CANNOT_JOIN_DRIVE       141       /* cannot sub to a joined drive */
#define MSG_DRIVE_IS_BUSY               142       /* drive is busy - join */
#define MSG_JOIN_SUB_SAME_DRIVE         143       /* cannot join or subst a drive to dir */
#define MSG_DIRECT_IS_NOT_SUBDIR        144       /* directory is not subdirectory of root */
#define MSG_DIRECT_IS_NOT_EMPTY         145       /* directory is not empty  -join */
#define MSG_PATH_USED_SUBST_JOIN        146       /* path used in subst, join - join sub */
/*  147 not used */
#define MSG_PATH_BUSY                   148       /* path is busy - join */
#define MSG_SUB_ON_DRIVE_IS_JOIN        149       /* directory on drive is target of a st */
/* */
#define MSG_VOLUME_TOO_LONG             154
/* */
#define MSG_INVALID_ORDINAL             182       /* invalid ordinal */
#define MSG_INVALID_STARTING_CODESEG    188       /* invalid code seg */
/* */
#define MSG_INVALID_STACKSEG            189       /* invalid stack segment */
#define MSG_INVALID_MODULETYPE          190       /* invalid module type */
#define MSG_INVALID_EXE_SIGNATURE       191       /* Invalid signature */
#define MSG_EXE_MARKED_INVALID          192       /* Invalid exec file */
#define MSG_BAD_EXE_FORMAT              193       /* Bad or old exec file */
#define MSG_ITERATED_DATA_EXCEEDS_64K   194       /* iterated data exceeds 64k */
#define MSG_INVALID_MINALLOCSIZE        195       /* data segment has invalid size */
#define MSG_DYNLINK_FROM_INVALID_RING   196       /* invalid ring */
#define MSG_IOPL_NOT_ENABLED            197       /* IOPL not enabled */
#define MSG_INVALID_SEGDPL              198       /* Invalid privilege level */
#define MSG_AUTODATASEG_EXCEEDS_64K     199       /* Privilege level exceeds 64K */
/*  200 not used */
#define MSG_RELOC_CHAIN_XEEDS_SEGMENT   201       /* Ring must be movable */
#define MSG_INFLOOP_IN_RELOC_CHAIN      202       /* infinite loop */
#define MSG_ENVVAR_NOT_FOUND            203       /* environment variable not found */
#define MSG_SIGNAL_NOT_SENT             205       /* DOS signal not sent */
/* */
#define MSG_MR_CANT_FORMAT              317
#define MSG_MR_NOT_FOUND                318
#define MSG_MR_READ_ERROR               319
#define MSG_MR_IVCOUNT_ERROR            320       /*IvCount out of range */
#define MSG_MR_UN_PERFORM               321
/* */
#define MSG_DIS_ERROR                   355
#define MSG_NO_COUNTRY_SYS              396
#define MSG_OPEN_COUNTRY_SYS            397
#define MSG_COUNTRY_NO_TYPE             401
/* 900 - 999 reserved for IBM Far East */
/* 1000 not used */
#define MSG_BAD_PARM1                   1001      /* invalid parm */
#define MSG_BAD_PARM2                   1002      /* invalid parm with specified input */
#define MSG_BAD_SYNTAX                  1003      /* invalid syntax */
/* 1004 not used */
#define MSG_SWAP_INVALID_DRIVE          1470      /* Invalid drive %1 specified SWAPPATH */
#define MSG_SWAP_INVALID_PATH           1471      /* Invalid path %1 specified in SWAPPATH */
#define MSG_SWAP_CANNOT_CREATE          1472      /* Cannot create swap file %1 */
#define MSG_SWAP_DISABLED               1473      /* Segment swapping is disabled */
#define MSG_SWAP_CANT_INIT              1474      /* Cannot initialize swapper */
#define MSG_SWAP_NOT_READY              1500      /* diskette containing swap file not rdy */
#define MSG_SWAP_WRITE_PROTECT          1501      /* Diskette containing swap file wrpro */
#define MSG_SWAP_IN_ERROR               1502      /* I/O error on swap file */
#define MSG_SWAP_IO_ERROR               1502      /* I/O error on swap file */
#define MSG_SWAP_FILE_FULL              1503      /* Swap file is full */
#define MSG_SWAP_TABLE_FULL             1504      /* Swap control table full */
/* */
#define MSG_SYSINIT_INVAL_CMD           1195      /* Unrecognized command */
#define MSG_SYSINIT_INVAL_PARM          1196      /* Invalid parameter */
#define MSG_SYSINIT_MISSING_PARM        1197      /* Missing parameter */
/* 1198 - 1199 not used */
#define MSG_SYSINIT_DOS_FAIL            1200      /* Cannot create DOS mode */
/* 1201 - 1204 not used */
#define MSG_SYSINIT_DOS_MODIFIED        1205      /* DOS mode memory modified by DD */
#define MSG_SYSINIT_UFILE_NO_MEM        1206      /* Out of memory loading user program or DD */
/* 1207 not used */
#define MSG_SAD_INSERT_DUMP             1395      /* insert dump disk - rasmsg */
/* 1517 not used */
#define MSG_SYSINIT_SFILE_NOT_FND       1518      /* System file not found */
#define MSG_SYSINIT_SFILE_NO_MEM        1519      /* Out of memory loading system program or DD */
/* 1520 not used */
#define MSG_SYSINIT_TOO_MANY_PARMS      1521      /* Too many parms on line */
/* 1522 not used */
#define MSG_SYSINIT_MISSING_SYMB        1523      /* No equal or space */
/* 1708 - 1717 not used */
#define MSG_SYSINIT_UFILE_NOT_FND       1718      /* User file not found */
#define MSG_SYSINIT_UDRVR_INVAL         1719      /* User device driver invalid */
/* 1720 not used */
#define MSG_SYSINIT_BANNER              1721      /* Version banner message */
#define MSG_SYSINIT_CANT_LOAD_MOD       1722      /* Can't load module */
#define MSG_SYSINIT_EPT_MISSING         1723      /* Entry point missing */
#define MSG_SYSINIT_CANT_OPEN_CON       1724      /* Can't open con */
#define MSG_SYSINIT_WRONG_HANDLE        1725      /* wrong handle for standard input file */
#define MSG_SYSINIT_PRESS_ENTER         1726      /* Press enter to continue */
#define MSG_SYSINIT_CANT_GET_CACHE      1727      /* Can't allocate cache memory */
/* 1728 not used */
#define MSG_SYSINIT_VIO_CP              1729      /* VioSetCp failed */
#define MSG_SYSINIT_KBD_CP              1730      /* KbdSetCp failed */
/* 1731 - 1732 not used */
#define MSG_SYSINIT_SCFILE_INVAL        1733      /* System country file is bad */
/* 1734 not used */
#define MSG_SYSINIT_CP_ASSUME           1735      /* Assumed codepage */
/* 1736 not used */
#define MSG_SYSINIT_CP_FATAL            1737      /* Codepage switching disabled */
#define MSG_SYSINIT_NOT_INIT_NMI        1738      /* cannot initial NMI ALSO FOR MODE MGR */
#define MSG_ASYNC_INSTALL               1899      /* Com installed */
#define MSG_ASYNC_COM_DEVICE            1900      /* COM device driver */
/* 1901 - 1914 utilmid2 */
#define MSG_INTERNAL_ERROR              1915      /* Internal error in the Kernel */
#define MSG_USER_ERROR                  1916      /* user error */
/* 1917 - 1918 not used */
#define MSG_SYSINIT_UEXEC_FAIL          1919      /* User program won't execute */
/* 1920 - 1924 not used */
#define MSG_SYSINIT_SEXEC_FAIL          1925      /* System program won't execute */
#define MSG_GEN_PROT_FAULT              1926      /* General protect fault trap d */
#define MSG_CHANGE_INT_VECTOR           1927      /* real mode changed interrupt vector */
#define MSG_NOMEM_FOR_RELOAD            1928      /* no storage to reload code or segment */
#define MSG_STACK_OVERFLOW              1929      /* argument stack low */
#define MSG_TRAP0                       1930      /* divide error */
#define MSG_TRAP1                       1931      /* single step trap */
#define MSG_TRAP2                       1932      /* hardware memory error */
#define MSG_TRAP3                       1933      /* breakpoint instruction */
#define MSG_TRAP4                       1934      /* computation overflow */
#define MSG_TRAP5                       1935      /* index out of range */
#define MSG_TRAP6                       1936      /* incorrect instruction */
#define MSG_TRAP7                       1937      /* cannot process instruction */
#define MSG_TRAP8                       1938      /* double exception error */
#define MSG_TRAP9                       1939      /* math coprocessor */
#define MSG_TRAPA                       1940      /* task state segment */
#define MSG_TRAPB                       1941      /* segment not in memory */
#define MSG_TRAPC                       1942      /* memory beyond the stack segment */
#define MSG_TRAPD                       1943      /* bad segment value */
#define MSG_NMI                         1944      /* nonmaskable interrupt */
#define MSG_NMI_EXC1                    1945      /* error with memory system board */
#define MSG_NM12_EXC2                   1946      /* error memory cards */
#define MSG_NMI2_EXC3                   1947      /* timeout on dma */
#define MSG_NMI2_EXC4                   1948      /* timeout by watchdog timer */
/* 1949 not used */
#define MSG_NPXIEMSG                    1950      /* incorrect operation */
#define MSG_NPXDEMSG                    1951      /* denormalized operand */
#define MSG_NPXZEMSG                    1952      /* zero divide */
#define MSG_NPXOEMSG                    1953      /* overflow */
#define MSG_NPXUEMSG                    1954      /* underflow */
#define MSG_NPXPEMSG                    1955      /* precision */
#define MSG_NPXINSTEMSG                 1956      /* error occurred at address */
#define MSG_SYSINIT_BOOT_ERROR          2025      /* boot error */
#define MSG_SYSINIT_BIO_NOT_FD          2026      /* COMMAND.COM not found */
#define MSG_SYSINIT_INSER_DK            2027      /* Insert diskette */
#define MSG_SYSINIT_DOS_NOT_FD          2028      /* IBMDOS.COM not found */
#define MSG_SYSINIT_DOS_NOT_VAL         2029      /* IBMDOS.COM not valid */
#define MSG_SYSINIT_MORE_MEM            2030      /* need more memory */
/* 2031 - 2056 utilmid3 */
/* 2057 - 2063 not used */
#define MSG_SYSINIT_DOS_NO_MEM          2064      /* Out of memory starting DOS mode */
#define MSG_SYSINIT_SYS_STOPPED         2065      /* System is stopped */
#define MSG_SYSINIT_DOS_STOPPED         2066      /* DOS mode not started */
#define MSG_SYSINIT_SDRVR_INVAL         2067      /* System device driver invalid */
#define MSG_SYSINIT_MSG_LOST            2068      /* Messages lost */
#define MSG_SYSINIT_UCFILE_INVAL        2069      /* User country file is bad */
#define MSG_DEMAND_LOAD_FAILED          2070      /* the demand load has failed */
