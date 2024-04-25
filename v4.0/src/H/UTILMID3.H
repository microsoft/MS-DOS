/*      SCCSID = @(#)utilmid3.h	5.13 87/05/05 */

#define MSG_SPOOL_WTRUNC_ERROR          1425      /* cannot release filling file - print */
#define MSG_SPOOL_OPEN_ERROR            1426      /* cannot delete filling file - print */
#define MSG_SPOOL_SIG_ERROR             1427      /* cannot delete printing file - print */
#define MSG_SPOOL_MACH_ERROR            1428      /* cannot hold filling file - print */
#define MSG_SPOOL_RUN_PRINT_DATA        1429      /* spool running with print data redir */
#define MSG_SPOOL_RUN_DEVICE            1430      /* spool print run on device */
#define MSG_INSTALL_SIMUL_PIPS          1960      /* pips being executed simultaneously */
#define MSG_INSTALL_UNKNOWN_CMD         1961      /* not recognize cmd in pip */
#define MSG_INSTALL_PANEL_ERROR         1962      /* cannot display panel */
#define MSG_INSTALL_FILE_CREATE_ERR     1963      /* cannot create the file */
#define MSG_INSTALL_LABEL_NOT_FOUND     1964      /* cannot find the label */
#define MSG_INSTALL_FILE_NOT_FOUND      1965      /* cannot find file */
#define MSG_INSTALL_FILE_NAME_ERR       1966      /* unacceptable file name */
#define MSG_INSTALL_FILE_OPEN_ERR       1967      /* file open error */
#define MSG_INSTALL_MEM_ALLOC_ERR       1968      /* memory allocation error */
/* 1969 not used */
#define MSG_INSTALL_UNBAL_COMMENTS      1970      /* cannot read part of pip */
#define MSG_INSTALL_SYNTAX_ERR          1971      /* syntax error */
#define MSG_INSTALL_UNSPEC_CHOICE       1972      /* missing choice parameter */
#define MSG_INSTALL_SHELL_ADD_ERR       1973      /* title on program selector */
#define MSG_INSTALL_DUPLICATE_LABEL     1974      /* duplicate label name */
#define MSG_INSTALL_UNSUCCESSFUL        1975      /* not able to install */
#define MSG_INSTALL_HY_HDR              1976      /* history file header */
#define MSG_INSTALL_HY_TITLE            1977      /* history file title */
#define MSG_INSTALL_HY_CRDATE           1978      /* history file date */
#define MSG_INSTALL_HY_UPDATE           1979      /* history file update */
#define MSG_TRC_NOT_ACTIVE              1397      /* trace not active */
/* 1980 not used */
#define MSG_TRC_ABEND                   1981      /* not properly formatted */
/* 1982 - 1984 not used */
#define MSG_INSTALL_BAD_PIP_EXT         1985      /* bad pip extension */
/* 1986 - 1990 unused */
#define MSG_EDLIN_INVALID_DOS_VER       1991      /* Invalid DOS version$ */
#define MSG_EDLIN_Y_IS_FOR_YES          1992      /* Answer for abort and OK questions */
#define MSG_EDLIN_FILENAME_NOT_SPEC     1993      /* Filename must be specified */
#define MSG_EDLIN_INVALID_PARAMETER     1994      /* Invalid parameter */
#define MSG_EDLIN_FILE_READ_ONLY        1061      /* File is read only */
/* 1995 not used */
#define MSG_EDLIN_TOO_MANY_FILES        1996      /* Too many files are open */
#define MSG_EDLIN_READ_ERROR_IN         1997      /* Read error in %S */
#define MSG_EDLIN_CANNOT_EDIT           1998      /* Cannot edit .BAK file -- rename file */
#define MSG_EDLIN_DISK_FULL             1999      /* Disk full edits lost */
#define MSG_EDLIN_INSUFFICIENT_MEM      8         /* Insufficient memory */
/* 2000not used */
#define MSG_EDLIN_ENTRY_ERROR           2001      /* Syntax entry error */
#define MSG_EDLIN_NEW_FILE              2002      /* New file */
#define MSG_EDLIN_NOT_FOUND             2003      /* Cannot find string specified */
#define MSG_EDLIN_OKAY                  2004      /* Okay OK? */
#define MSG_EDLIN_LINE_TOO_LONG         2005      /* The line is too long */
#define MSG_EDLIN_END_INPUT_FILE        2006      /* End of the input file */
#define MSG_EDLIN_ABORT_EDIT            2007      /* Abort edit Y/N ? */
#define MSG_EDLIN_SPECIFY_LINE_NO       2008      /* Must specify destination line number */
#define MSG_EDLIN_NOT_ENOUGH_ROOM       2009      /* Not enough room to merge entire file */
#define MSG_GRAFT_ENG_VER               2010      /* Eng version */
#define MSG_GRAFT_CANFR_VER             2011      /* Canfrench version */
#define MSG_GRAFT_PORT_VER              2012      /* Portugese version */
#define MSG_GRAFT_NORD_VER              2013      /* Nordic version */
#define MSG_GRAFT_ENG_LOAD              2014      /* Eng version loaded */
#define MSG_GRAFT_CANFR_LOAD            2015      /* Canadian French version loaded */
#define MSG_GRAFT_PORT_LOAD             2016      /* Portugese version loaded */
#define MSG_GRAFT_NORD_LOAD             2017      /* Nordic version loaded */
#define MSG_GRAFT_NO_LOAD               2018      /* No Graftable loaded */
#define MSG_GRAFT_ALREAD_LOAD           2019      /* Graftable already loaded */
#define MSG_GRAFT_INCOR_PARM            1001      /* Graftable incorrect parm */
/* 2020 not used */
#define MSG_GRAFT_PARM_SUP              2021      /* Graftable parameter supported */
/* 2022 - 2024 unused */
/* 2025 - 2031 basemid */
/* 2032 - 2034 unused */
#define MSG_FDISK_ESC_TO_CREATE         2035      /* press escape to create logical drive */
/* 2036 - 2039 unused */
#define MSG_DCOPY_WRITE_ERROR           2040      /* Unrecoverable error writing to */
/* 2041 - 2045 */
#define MSG_APPEND_NO_DIR               2046      /* no append dir */
#define MSG_APPEND_ASSIGN_CONFLICT      2047      /* assign conflict */
#define MSG_APPEND_TOPVIEW_CONFLICT     2048      /* topview conflict */
#define MSG_APPEND_ALREADY_INSTALLED    2049      /* append is already installed */
#define MSG_APPEND_INVAL_PATH_PARM      2050      /* invalid path or parameter */
#define MSG_APPEND_INVAL_PATH           2050      /* invalid path */
#define MSG_APPEND_INCOR_APPEND_VER     2052      /* incorrect append version */
/* 2053 - 2055 */
#define MSG_UNEXPEC_ERROR_ENC           2056      /* unexpected error encountered */
/* 2057 - 2070 basemid */
#define MSG_FMT_SKIPPING                2071      /* skipping ADOS files */
#define MSG_FMT_SYS_SKIP                2072      /* files skipped during xfer */
/* 2073 - 2075 unused */
#define MSG_PROG_DOS                    2076      /* to refer to the PCDOS mode box */
#define MSG_PROG_MORE                   2077      /* more data to be scrolled */
/* 2078 - 2080 unused */
#define MSG_INSTALL_SELECT              2081      /* syntax error SELECT/ESELECT block */
/* 2082 - 2085 unused */
#define MSG_LOST_LIBRARY                2086      /* the library is lost */
#define MSG_SETCOM_OPEN_ERROR           2087      /* unable to open a port */
#define MSG_SETCOM_DISABLE              2088      /* port has been disabled */
#define MSG_SETCOM_ENABLE               2089      /* port has been enabled */
#define MSG_BIND_RESERVED               2090      /* unable to load the program */
/* 2091 - 2999 unused */
/* 3000 - 3100 reserved for IBM Far East */
