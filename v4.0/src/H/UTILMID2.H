/*      SCCSID = @(#)utilmid2.h	5.18 87/05/05 */

#define MSG_REST_FILE_FROM              1634      /* restore file from % 1 %2 */
#define MSG_INS_BACKUP_DISK             1635      /* insert backup %1 in drive %2 */
#define MSG_REST_DISK_OUT_SEQ           1636      /* diskette out of seq press key */
#define MSG_REST_FILE_READ              1637      /* Warning file %1 read only */
#define MSG_REST_CHNG_REPL              1638      /* file was changed after backup */
#define MSG_REST_SYS                    1639      /* system files restored */
#define MSG_REST_FILE_BACKUP            1640      /* files were backed up */
#define MSG_REST_FILENAME               1641      /* filename restored */
#define MSG_REST_SOUR_TARG_SAME         1642      /* source and target are same */
#define MSG_REST_NUM_INVAL_PARA         1643      /* invalid number of para restore */
#define MSG_REST_INVAL_SPEC             15        /* invalid drive */
/* 1744 not used */
#define MSG_REST_NO_FILE_FOUND          1645      /* not files found to restore */
#define MSG_REST_INVAL_PARA             1002      /* invalid parameter %1 */
#define MSG_REST_FILE_SHAR              1642      /* sharing conflict */
/* 1646 - 1647 not used */
#define MSG_REST_LAST_FILE_NOT          1648      /* last file not restored */
#define MSG_REST_SOURCE_NO_BACK         1649      /* source does not contain backup files */
#define MSG_REST_FILE_SEQ_ERROR         1651      /* sequence file out of sequence */
#define MSG_REST_FILE_CREAT_ERROR       110       /* file creation error */
/* 1652 - 1654 not used */
#define MSG_REST_TARG_FULL              112       /* Target is full */
#define MSG_REST_CANNOT_REST_FILE       1655      /* cannot restore file */
#define MSG_REST_DISKETTE               1656      /* diskette %1 */
#define MSG_REST_TARG_DISK              1657      /* insert targ disk in drive %1 */
/* 1658 - 1663 unused */
#define MSG_BACK_NUM_INVAL_PARA         1665      /* inval number of parameters */
#define MSG_BACK_ERROR_LOG_FILE         1664      /* error writing log file */
#define MSG_BACK_INVAL_PARA             1001      /* inval parameter */
/* 1666 not used */
#define MSG_BACK_NO_DRIV_SPEC           1667      /* no drive spec */
#define MSG_BACK_NO_TARG_SPEC           1668      /* no target specified */
#define MSG_BACK_INVAL_PATH             3         /* inval path */
/* 1079 - 1670 not used */
#define MSG_BACK_SOUR_TARG_SAME         1671      /* source target same */
#define MSG_BACK_ERR_FORMAT_UTIL        1672      /* error executing format utility */
#define MSG_BACK_INVAL_DATE             1036      /* inval date */
/* 1673 - 1675 not used */
#define MSG_BACK_INVAL_TIME             1044      /* inval time */
#define MSG_BACK_INVAL_DRIV_SPEC        15        /* inval drive spec */
#define MSG_BACK_CANNOT_FIND_FORM       1676      /* cannot find format util */
#define MSG_BACK_ERROR_OPEN_LOGFILE     1677      /* error open logfile */
#define MSG_BACK_CAN_FORM_UNREM_DR      1678      /* cannot form unremovable drive */
#define MSG_BACK_LAST_NOT_INSERT        1679      /* last disk not inserted */
#define MSG_BACK_LOG_TO_FILE            1680      /* log to file %2 */
#define MSG_BACK_FILE_TARG_DRIVE        1681      /* warning file in target drive %2 */
#define MSG_BACK_FILE_BACK_ERASE        1682      /* files in target drive %c */
#define MSG_BACK_FILE_TO_DRIVE          1683      /* backup up files to drive d */
#define MSG_BACK_DISK_NUM               1684      /* diskette number %2 */
#define MSG_BACK_WARN_NO_FIL_FND        1685      /* warning no files were found to backup */
#define MSG_BACK_INSERT_SOURCE          1686      /* insert backup source diskette in dr d */
#define MSG_BACK_INSERT_BACKUP          1687      /* insert backup source disk %2 in dr */
#define MSG_BACK_UNABLE_TO_BKUP         1688      /* not able to backup file */
#define MSG_BACK_LAST_DISK_DRIVE        1689      /* insert last backup diskette in drive */
#define MSG_BACK_TARG_NOT_USE_BKUP      1690      /* target cannot be used for backup */
#define MSG_BACK_LAST_FILE_NO_BKUP      1691      /* last file not backed up */
#define MSG_BACK_DEVICE_D_IS_FULL       1692      /* fixed backup device d is full */
#define MSG_XCOPY_UNAB_CREATE_DIR       1693      /* unable to create directory */
#define MSG_XCOPY_PATH_TOO_LONG         1694      /* path too long */
#define MSG_XCOPY_BLANK_YN              1695      /* blank y/n */
/* 1696 not used */
#define MSG_XCOPY_READ_SOURCE_FILE      1697      /* reading source file */
#define MSG_XCOPY_FILES_COPIED          1698      /* % files copied */
#define MSG_XCOPY_FILE_NOT_FOUND        1699      /* % file not found */
#define MSG_XCOPY_DOES_SPEC_FILENA      1700      /* Does % specify a filename */
#define MSG_XCOPY_CANNOT_COPY_SUB       1701      /* cannot copy using /s to subdirectory */
/* 1702 not used */
#define MSG_XCOPY_INVAL_PARA            1001      /* invalid parameter xcopy */
/* 1703 not used */
#define MSG_XCOPY_INVAL_NUM_PAR         1704      /* invalid number of parameters xcopy */
#define MSG_ANSI_EXT_SCR_KEY_ON         1705      /* ansi extended screen and keyboard on */
#define MSG_ANSI_EXT_SCR_KEY_OFF        1706      /* ansi extended screen and keyboard off */
#define MSG_ANSI_INVAL_PARA             1001      /* ansi invalid parameter */
/* 1707 not used */
/* 1708 - 1736 basemid */
/* 1737 - 1740 unused */
/* 1739 - 1740 unused */
#define MSG_KEYB_TAB_NOT_EXIST          1741      /* translate table does not exist */
#define MSG_KEYB_READ_TAB               1742      /* error reading translate table file */
#define MSG_KEYB_INVAL_CODE             1454      /* Invalid keyboard layout code */
/* 1743 not used */
#define MSG_KEYB_SYS_ERR                1744      /* System error */
#define MSG_KEYB_CODE_PAGE              1745      /* Code page not available */
#define MSG_KEYB_TOO_MANY_PARMS         1454      /* Too many parms */
/* 1746 not used */
#define MSG_KEYB_DEF_LOAD               1747      /* Default ready loaded */
#define MSG_KEYB_DOS_OPEN_ER            1748      /* Dos open error */
/* 1749 not used */
#define MSG_KEYB_INVAL_TYPE             1750      /* Invalid keyboard type */
#define MSG_KEYB_ERR_LOAD_TRANS         1751      /* Invalid loading translate table */
#define MSG_KEYB_LOADED                 1752      /* translate table loaded */
/* 1753-1760 unused */
#define MSG_CHCP_INVALID_PARAMETER      1761      /* invalid parameter */
#define MSG_CHCP_TASK                   1762      /* unable to set process */
/* 1763 - 1765 unused */
#define MSG_CHCP_REPORT                 1766      /* active code page */
#define MSG_CHCP_SYSTEM                 1767      /* Code page not prepared for system */
#define MSG_CHCP_NO_CP                  1768      /* Code page not set for system */
#define MSG_CHCP_DEVICE                 1769      /* Code page not prepared for device */
/* 1770 - 1772 unused */
#define MSG_START_INVALID_PARAMETER     1773      /* Invalid parameter to start command */
/* 1774-1780 unused */
#define MSG_SPOOLER_FONT_SWITCH         1781      /* error attempting to load font */
#define MSG_SPOOLER_INVAL_CODE_PG       1782      /* code page id not valid */
#define MSG_SPOOLER_ERR_OPEN_FONT       1783      /* error attempt to open font file */
#define MSG_SPOOLER_ERR_READ_FONT       1784      /* error reading font file */
#define MSG_SPOOLER_ERR_READ_CTRL       1784      /* error reading font file ctrl */
#define MSG_SPOOLER_READ_DEFIN          1784      /* error reading font file blocks */
/* 1785 - 1786 not used */
#define MSG_SPOOLER_INVAL_PRINT         1787      /* invalid printer type in devinfo */
#define MSG_SPOOLER_INSUF_STOR          1788      /* insuf storage to activate */
#define MSG_SPOOLER_INCOR_FONT          1789      /* devinfo statement font incorrect */
#define MSG_SPOOLER_INTER_ERR           1790      /* font switching internal error */
#define MSG_SPOOLER_TOO_MANY_ROMS       1791      /* too many roms */
#define MSG_SPOOLER_SOME_FONTS_BAD      1792      /* damaged font files */
/* 1793-1799 unused */
#define MSG_CMD_LOCK_VIOLATION          32        /* lock violation */
/* 1800 - 1803 not used */
#define MSG_CMD_NOT_DOS_DISK            26        /* media store not dos disk */
#define MSG_CMD_NO_MEMORY               8         /* No more memory */
#define MSG_CMD_FILE_NOT_FOUND          1804      /* File not found */
#define MSG_CMD_ACCESS_DENIED           5         /* access denied */
/* 1805 - 1808 not used */
#define MSG_CMD_DRIVE_LOCKED            108       /* drive locked */
#define MSG_CMD_SHARING_VIOLATION       32        /* sharing violation */
#define MSG_CMD_SYS_ERR                 1809      /* A system error occurred */
#define MSG_CMD_DIV_0                   1810      /* process terminated */
#define MSG_CMD_SOFT_ERR                1811      /* fatal software error */
#define MSG_CMD_COPROC                  1812      /* process terminated */
#define MSG_CMD_KILLED                  1813      /* process killed */
#define MSG_CMD_TOO_MANY_OPEN           1814      /* too many open files */
/* 1815 - 1824 unused */
#define MSG_PROG_CANT_FIND_FILE         1825      /* cant find file */
#define MSG_PROG_NO_MEM                 1826      /* cannot process command */
#define MSG_PROG_NON_RECOV              1827      /* cannot process request */
#define MSG_PROG_CNT_START              1828      /* cannot start selected program */
/* 1829  not used */
#define MSG_PROG_NO_MOU                 1830      /* cannot set mou key assign */
#define MSG_PROG_UNEXCEPT_FORMAT        1831      /* unacceptable executable format file */
/* 1832 - 1838 unused */
#define MSG_FDISK_WHOLEDISK_2           1839      /* maximum size */
#define MSG_FDISK_CREATE_DOS_MENU       1840      /* create dos menu */
#define MSG_FDISK_CREATE_DOS_EXT        1841      /* create dos extended partition */
#define MSG_FDISK_CREATE_PRIME_HD       1842      /* create primary menu */
#define MSG_FDISK_CREATE_EXT_HD         1843      /* create extended menu */
#define MSG_FDISK_CREATE_LOG_HD         1844      /* create logical drive */
#define MSG_FDISK_EXT_CREATED           1845      /* extended part created */
#define MSG_FDISK_VOL_CREATED           1846      /* volume created */
/* 1847 not used */
#define MSG_FDISK_DEL_MENU              1848      /* delete menu */
#define MSG_FDISK_DEL_LOG_DRV           1849      /* delete logical drive */
#define MSG_FDISK_DEL_PRIM_DOS          1850      /* delete primary dos partition */
#define MSG_FDISK_DEL_EXT_PART          1851      /* delete extended dos partition */
#define MSG_FDISK_DEL_LOG_HD            1852      /* delete logical drive */
#define MSG_FDISK_ALL_LOG_DEL           1853      /* logical drive deleted */
#define MSG_FDISK_EXT_DEL               1854      /* extended partition deleted */
/* 1855 not used */
#define MSG_FDISK_EXT_PART_DEL          1856      /* extended dos partition deleted */
#define MSG_FDISK_DRV_DEL               1857      /* drive deleted */
/* 1858 not used */
#define MSG_FDISK_CUR_PART_NOT_BOOT     1859      /* the partitions marked is boot */
#define MSG_FDISK_WARN_LOG_LOST         1860      /* data in log drive will be lost */
#define MSG_FDISK_WARN_EXT_LOST         1861      /* data in extended part will be lst */
#define MSG_FDISK_SURE_QUERY            1862      /* are you sure? */
#define MSG_FDISK_LOG_SIZE_INP          1863      /* logical drive size */
#define MSG_FDISK_DISP_LOG_INFO_INP     1864      /* extended partition cont log dr */
#define MSG_FDISK_ESC_TO_DOS            1865      /* press esc to return to dos */
#define MSG_FDISK_DEFAULT_INP           1866      /* 1 */
#define MSG_FDISK_MAX_LOG_SPACE         1867      /* total part avail is cylinders */
#define MSG_FDISK_TOT_PART_SIZE         1868      /* Total partition size is cylinder */
/* 1869 not used */
#define MSG_FDISK_CUR_FDISK_LOG         1870      /* current fixed disk drive */
/* 1871 not used */
#define MSG_FDISK_DRV_LETTERS_CHNGD     1872      /* drive letter have changed or del */
#define MSG_FDISK_BOOT_AL_ACT           1873      /* bootable part on drive 1 is act */
#define MSG_FDISK_EXT_FULL              1874      /* avail space is assign to log dr */
#define MSG_FDISK_NO_BOOT_EXIST         1875      /* only non-boot part on dr 1 */
#define MSG_FDISK_ONLY_CURDRV_PART_ACT  1876      /* only part on drive 1 can be act */
#define MSG_FDISK_MAX_LOGDRV_INS        1877      /* maximum number of log dos dr ins */
/* 1878 not used */
#define MSG_FDISK_CANT_DEL_PRIM         1879      /* cannot delete primary dos part */
#define MSG_FDISK_MAX_AVAIL_SPACE       1880      /* max avail space for partit cyl */
#define MSG_FDISK_LOG_INFO_HD           1881      /* drive start end size */
#define MSG_FDISK_LOG_INFO              1882      /* 1 2 3 4 */
#define MSG_FDISK_PART_INFO             1883      /* 1 2 3 4 5 6 7 8 */
#define MSG_FDISK_ERR_EXT_EXIST         1884      /* extended part already exists */
#define MSG_FDISK_ERR_NO_EXT            1885      /* no extended part to delete */
/* 1886 not used */
#define MSG_FDISK_PART_TOO_SMALL        1887      /* file partition too small */
#define MSG_FDISK_ERR_PART_NOT_BOOT     1859      /* partition selected is not bootable */
#define MSG_FDISK_ERR_NO_LOG_DEF        1888      /* no logical drives defined */
#define MSG_FDISK_ERR_LOG_INP_2_BIG     1889      /* requested log drive size exceeds */
#define MSG_FDISK_ERR_PART_INP_2_BIG    1890      /* requested part size exceeds max */
#define MSG_FDISK_ERR_NO_PART_2_DEL     1891      /* no partitions to delete */
#define MSG_FDISK_ERR_NO_PRIM_PART      1892      /* cannot create extend dos prim dk */
#define MSG_FDISK_ERR_LOG_STILL_EXIST   1893      /* cannot delete extend part log dr */
#define MSG_FDISK_ERR_0_PART_SPEC       1894      /* cannot create a zero cylinder pr */
#define MSG_FDISK_ERR_DRV_DEL           1895      /* drive already deleted */
#define MSG_FDISK_INTERNAL_ERROR        1896      /* internal error */
#define MSG_FDISK_ERR_COMMAND_LINE      1897      /* unsupported switch ignored */
#define MSG_START_NONE                  1898      /* screen group not started */
#define MSG_MODE_COM_PORT               1901      /* query status not available */
#define MSG_MODE_P_IGNORE               1902      /* P option ignored */
/* 1903-1914 unused */
/* 1915-1956 in basemid */
/* 1957-1959 unused */
