/*      SCCSID = @(#)utilmid.h	10.5 87/05/22 */

#define MSG_REC_FILE_NOT_FOUND          2         /* file not found */

#define MSG_DCOMP_INSUFF_MEM            8         /* insufficient storage - diskcomp */
#define MSG_DCOPY_INSUFF_MEM            8         /* insufficient storage - diskcopy */
#define MSG_CHK_MEMORY_UNAVAIL          8         /* memory unavailable - chkdsk */
#define MSG_REST_INSUF_MEM              8         /* insufficient memory */
#define MSG_BACK_INSUF_MEM              8         /* insufficient mem */
#define MSG_REC_UNABLE_ALL_MEM          8         /* unable to allocate memory */
/* 1000 - 1004 basemid */
/* 1005 not used */
#define MSG_SORT_INVAL_PARA             1002      /* sort invalid parameter */
#define MSG_SORT_NOT_ENOUGH_MEMORY      1006      /* sort file size too big */
/* 1008 not used */
#define MSG_SORT_READ_ERROR             30        /* error reading from disk/diskette */
/* 1009 not used */
#define MSG_SORT_RCD_SIZE_EXCEED        1010      /* record size exceeded */
/* 1011 - 1014 unused */
#define MSG_REC_ENT_BEG_REC             1015      /* Press Enter to being recover drive %1 */
#define MSG_REC_ERROR_DRIVE             1016      /* %1 error %2 drive %3 */
#define MSG_REC_INVAL_PARAMETER         1001      /* Invalid parameter */
/* 1018 not used */
#define MSG_REC_INVAL_DRIVE             1019      /* invalid drive */
#define MSG_REC_INVAL_DRIVE_FILE        2         /* invalid drive or filename */
/* 1020 - 1022 */
#define MSG_REC_BYTES_RECOVERED         1023      /* %1 of %2 bytes recovered */
#define MSG_REC_WARN_DIR_FULL           1024      /* warning directory full */
#define MSG_REC_FILES_RECOVERED         1025      /* %1 files recovered */
#define MSG_REC_TOO_MANY_PARAMETERS     1003      /* Too many parameters entered */
/* 1026 - 1031 unused */
#define MSG_REN_INVAL_NUM_PARA          1003      /* Rename invalid number of parameters */
#define MSG_STRIKE_ANY_KEY              1032      /* press any key when ready */
#define MSG_DIR_INVALID_DIR             3         /* Dir invalid directory */
/* 1033 not used */
#define MSG_COM_SEARCH_DIR_BAD          1034      /* specified command search dir bad */
#define MSG_REN_INVAL_PATH_FILENAME     1035      /* rename invalid path or filename */
#define MSG_DATE_INVALID                1036      /* invalid date */
#define MSG_NO_BAT_LABEL                1039      /* batch label not found */
#define MSG_DIR_BAD_COMMAND_OR_FILE     1041      /* bad command or filename */
#define MSG_RMDIR_INVALID_PATH          1042      /* rmdir is bad */
#define MSG_REN_INVALID_PARAMETER       1003      /* rename invalid parameter */
/* 1043 not used */
#define MSG_REN_INVALID_TIME            1044      /* rename invalid time */
#define MSG_BAD_DOS_VER                 1045      /* CMD and DOS incompat */
#define MSG_VER_SPEC_ON_OFF             1001      /* verify and break on or off */
/* 1046 not used */
#define MSG_COMM_VER                    1047      /* command version 5.0 */
#define MSG_C                           1048      /* c acknowledgement */
#define MSG_FILES_COPIED                1049      /* % files copied */
#define MSG_CURRENT_DATE                1050      /* current date is */
#define MSG_CURRENT_TIME                1051      /* current time is */
#define MSG_DOSWRITE_ERROR_TO_DEV       29        /* doswrite error writing to device */
/* 1052 not used */
#define MSG_DIR_OF                      1053      /* directory of %1 */
#define MSG_DIR                         1054      /* dir */
#define MSG_OUT_OF_ENVIRON_SPACE        1056      /* out of environment space */
/* 1058 not used */
#define MSG_EXEC_FAILURE                1059      /* EXEC failure */
#define MSG_FILES_FREE                  1060      /* %1 files %2 bytes free */
#define MSG_FILE_CREATION_ERROR         1061      /* file creation error */
/* 1062 - 1063 not used */
#define MSG_LINES_TOO_LONG              1065      /* lines too long */
#define MSG_CONT_LOST_BEF_COPY          1066      /* content of destination lost before */
#define MSG_INSRT_DISK_BAT              1067      /* insert disk with batch file press key */
#define MSG_ENTER_NEW_DATE              1068      /* Enter new date */
#define MSG_SYNERR_NLN                  1003      /* newline */
/* 1069 not used */
#define MSG_ENTER_NEW_TIME              1070      /* enter new line */
#define MSG_RDR_HNDL_CREATE             1071      /* Handle creation error */
#define MSG_ECHO_OFF                    1074      /* ECHO is off */
#define MSG_ECHO_ON                     1075      /* ECHO is on */
#define MSG_VERIFY_OFF                  1076      /* Verify is off */
#define MSG_VERIFY_ON                   1077      /* Verify is on */
#define MSG_CANNOT_COPIED_ONTO_SELF     1078      /* message cannot be copied onto self */
#define MSG_SYNERR_GENL                 1079      /* syntax error general */
#define MSG_TOP_LEVEL_PROCESS_CAN       1081      /* top level process aborted, cannot con */
#define MSG_PID_IS                      1082      /* pid is %1 */
#define MSG_DUP_FILENAME_OR_NOT_FD      1083      /* duplicate filename or file not found */
#define MSG_ARE_YOU_SURE                1084      /* Are you sure (Y/N)? */
#define MSG_SET_SYNTAX_ERROR            1003      /* syntax error on set command */
/* 1085 not used */
#define MSG_TOKEN_TOO_LONG              1086      /* token too long */
#define MSG_PROG_TOO_BIG_MEM            8         /* program is too big to fit into memory */
/* 1087 not used */
#define MSG_MS_DOS_VERSION              1090      /* cp-dos version %1 %2 */
#define MSG_PIPE_FAILURE                1092      /* pipeline failure %1 */
#define MSG_MS_MORE                     1093      /* more? */
/* 1094 - 1100 unused */
#define MSG_BAD_VERSION                 1210      /* bad dos version - join */
#define MSG_JS_INCOR_SYNT               1003      /* bad join syntax */
/* 1001 not used */
#define MSG_JOIN_CANNOT_CREAT_DIR       82        /* cannot create directory */
/* 1102 not used */
#define MSG_SUBST_CANNOT_ACCPT_DIR      1103      /* cannot accept directory - join */
#define MSG_JOIN_LIST                   1104      /* join is joined */
#define MSG_SUBST_LIST                  1105      /* subst is substituted */
/* 1106 not used */
#define MSG_REAL_MODE_ONLY              1107      /* app run in real mode only */
/* 1108 - 1135 unused */
#define MSG_REP_INCOR_VERSION           1135      /* incorrect dos version replace */
#define MSG_REP_INCOR_PARA              1002      /* incorrect parameters replace */
/* 1136 not used */
#define MSG_REP_SOUR_PATH_REQ           1137      /* source path required replace */
#define MSG_REP_PARA_NOT_COMP           1003      /* parameters not compatible */
/* 1138 not used */
#define MSG_REP_ENTER_ADD_FILE          1139      /* press enter to add file */
#define MSG_REP_ENTER_REPLACE_FILE      1140      /* press enter replace file */
#define MSG_REP_NO_FILES_FOUND          1141      /* no files found replace */
#define MSG_REP_FILE_NOT_COPY_SELF      1078      /* file cannot be copied to self %1 */
/* 1142 - 1144 not used */
#define MSG_REP_NOT_FOUND               2         /* file not found %1 */
#define MSG_REP_PATH_REQ_NOT_FOUND      3         /* path requested not found */
#define MSG_REP_ACCESS_DENIED           1145      /* access to %1 denied */
#define MSG_REP_DRIVE                   15        /* drive rep incorrect */
/* 1146 - 1147 not used */
#define MSG_REP_NO_FILES_ADDED          1148      /* no files added. */
#define MSG_REP_FILES_ADDED             1149      /* files %1 added. */
#define MSG_REP_NO_FILES_REP            1150      /* no files replaced */
#define MSG_REP_FILES_REP               1151      /* files %1 replaced */
#define MSG_REP_ADD                     1152      /* add %1 y/n */
#define MSG_REP_FILES                   1153      /* want to replace %1 */
#define MSG_REP_ADDING_FILES            1154      /* adding %1 files */
#define MSG_REP                         1155      /* replacing %1 files */
/* 1156 - 1160 unused */
#define MSG_COMP_COMPARE_MORE           1161      /* compare more files */
#define MSG_COMP_ENTER_FILE_1ST         1162      /* enter primary filename */
#define MSG_COMP_ENTER_FILE_2ND         1163      /* enter 2nd filename or drive letter */
#define MSG_COMP_COMPARE_OK             1164      /* files compare ok */
#define MSG_COMP_END_COMPARE            1165      /* 10 mismatches ending compare */
#define MSG_COMP_FILE2_BYTE             1166      /* file2 = %0 */
#define MSG_COMP_FILE1_BYTE             1167      /* file 1 = %0 */
#define MSG_COMP_FILE_OFFSET            1168      /* compare error at offset %0 */
#define MSG_COMP_LENGTH_MISMATCH        1169      /* files are different sizes */
#define MSG_COMP_1ST_2ND_FILENAMES      1170      /* %1 and %2 */
#define MSG_COMP_INVALID_PATH           1171      /* invalid path */
#define MSG_COMP_FILE_NOT_FOUND         1490      /* %1 file not found */
#define MSG_COMP_INVALID_DRIVE          15        /* invalid drive */
#define MSG_COMP_INVALID_DOSVER         1210      /* invalid dos version */
/* 1172 - 1179 unused */
#define MSG_MOUSE_PARA_MOD              1180      /* parameters modified */
#define MSG_MOUSE_NOT_LOADED            1181      /* mouse device driver version not load */
#define MSG_MOUSE_LOADED                1183      /* mouse loaded */
#define MSG_XCOPY_ITSELF                1184      /* cannot copy itself */
#define MSG_XCOPY_INTERNAL_ERROR        1185      /* internal error */
#define MSG_XCOPY_NO_OPEN_SOURCE        1186      /* no source open */
#define MSG_XCOPY_NO_OPEN_TARGET        1187      /* no target open */
#define MSG_XCOPY_NO_READ_SOURCE        1186      /* no read source */
/* 1188 not used */
#define MSG_XCOPY_NO_CLOSE_SOURCE       1189      /* close source */
#define MSG_XCOPY_NO_CLOSE_TARGET       1189      /* no close target */
/* 1190  - 1191 not used */
#define MSG_XCOPY_NO_WRITE_TARGET       1187      /* no write target */
#define MSG_XCOPY_NO_ACCESS_SOURCE      1192      /* no access source */
#define MSG_XCOPY_NO_ACCESS_TARGET      1192      /* no access target */
/* 1193 not used */
#define MSG_XCOPY_INVALID_DATE          1036      /* invalid date */
/* 1194 - 1207 basemid */
#define MSG_ENTER_JAPAN_DATE            1208      /* enter the new date yy-mm-dd */
#define MSG_ENTER_DEF_DATE              1209      /* enter the new date dd-mm-yy */
#define MSG_INCORRECT_DOSVER            1210      /* incorrect dos version */
#define MSG_SAD_INV_DOS                 1210      /* invalid dos version - created */
#define MSG_STCP_INV_DOS                1210      /* trace only in >= dos  - trace */
#define MSG_INVALID_DOS_PRINT           1210      /* incorrect dos version */
#define MSG_TREE_INV_DOSVER             1210      /* incorrect DOS version */
#define MSG_INVAL_DOS_VERSION           1210      /* invalid DOS version */
#define MSG_REST_INVAL_VERS             1210      /* invalid dos version not 1.0 */
#define MSG_BACK_INCOR_DOS_VER          1210      /* inval dos ver */
#define MSG_REP_INCOR_DOS_VERSION       1210      /* incorrect dos version replace */
#define MSG_ABORT_RETRY_IGNORE          1211      /* abort, retry, or ignore */
#define MSG_REC_ABORT_RETRY_IGNORE      1211      /* abort, retry, ignore */
#define MSG_PRESS_ANY_KEY               1212      /* press any key when ready */
/* 1213 - 1215 not used */
#define MSG_DCOMP_INV_PARM              1001      /* invalid parameter - diskcomp */
/* 1230 not used */
#define MSG_DCOMP_INV_DRIVE             1231      /* invalid drive - diskcomp */
#define MSG_DCOPY_INV_DRV               1231      /* invalid drive - diskcopy */
#define MSG_DCOMP_INSERT_FIRST          1232      /* insert first disk - diskcomp */
#define MSG_DCOPY_INSERT_SRC            1232      /* insert source disk - diskcopy */
#define MSG_DCOMP_INSERT_SECOND         1233      /* insert second disk - diskcomp */
#define MSG_DCOPY_INSERT_TARG           1233      /* insert target disk - diskcopy */
#define MSG_DCOMP_DISK1_BAD             1234      /* first disk bad - diskcomp */
#define MSG_DCOMP_DISK2_BAD             1235      /* second disk bad - diskcomp */
/* 1236 - 1237 not used */
#define MSG_DCOMP_REPEAT_COMP           1238      /* compare another? - diskcomp */
#define MSG_DCOMP_COMPARING             1239      /* comparing ...  - diskcomp */
#define MSG_DCOMP_DRV_INCOMPAT          1240      /* drive incompatible - diskcomp */
#define MSG_DCOPY_COPYING               1240      /* copying ...  - diskcopy */
#define MSG_DCOMP_COMPARE_ERROR         1242      /* compare error - diskcomp */
/* 1243 not used */
#define MSG_DCOMP_COMPARE_ENDED         1244      /* compare ended - diskcomp */
#define MSG_DCOMP_COMPARE_OK            1245      /* compare ok - diskcomp */
#define MSG_DCOMP_ENTER_SRC             1246      /* source drive letter - diskcomp/copy */
#define MSG_DCOMP_ENTER_TARG            1247      /* target drive letter - diskcomp/copy */
/* 1248 not used */
#define MSG_DCOPY_FORMATTING            1252      /* copying while formatting - diskcopy */
#define MSG_DCOPY_TARG_NOUSE            1255      /* target disk possibly bad - diskcopy */
/* 1256 not used */
#define MSG_DCOPY_COPY_ANOTHER          1259      /* copy another?  - diskcopy */
#define MSG_DCOPY_COPY_TRACKS           1260      /* copy tracks */
/* 1261 - 1262 not used */
#define MSG_DCOPY_READ_ERROR            1264      /* read error - diskcopy */
#define MSG_DCOPY_UNREC_RDERR           1265      /* unrecoverable read error - diskcopy */
#define MSG_DCOPY_COPY_ENDED            1266      /* copy ended - diskcopy */
/* 1267 - 1269 not used */
#define MSG_FMT_INS_NEW_DISK            1270      /* insert new disk - format */
#define MSG_FMT_DISK_WARNING            1271      /* fixed disk warning - format */
#define MSG_FMT_SYS_XFERED              1272      /* system transferred - format */
#define MSG_FMT_ANOTHER                 1273      /* format another - format */
#define MSG_FMT_INV_VOLUME              123       /* invalid volume name - format */
/* 1274 - 1275 not used */
#define MSG_FMT_INV_PARAMETER           1276      /* invalid parameter - format */
#define MSG_FMT_REINSERT_DISK           1277      /* reinsert target disk - format */
#define MSG_FMT_INSERT_DOS              1278      /* reinsert system disk - format */
#define MSG_FMT_FORMAT_FAIL             1279      /* format failure - format */
#define MSG_FMT_DISK_UNSUIT             1280      /* disk unsuitable for system - format */
#define MSG_FMT_INV_MEDIA               1281      /* invalid media - format */
#define MSG_FMT_INSUFF_STORAGE          8         /* insufficient storage - format */
/* 1282 not used */
#define MSG_FMT_DISK_SPACE              1283      /* disk space available - format */
#define MSG_FMT_BYTES_USED              1284      /* bytes used - format */
#define MSG_FMT_BYTES_BAD               1285      /* bytes in bad sectors - format */
#define MSG_FMT_BYTES_AVAIL             1286      /* bytes available - format */
#define MSG_FMT_VOLUME_PROMPT           1288      /* enter volume name - format */
/* 1289 not used */
#define MSG_FMT_NO_SYS_TRANS            1290      /* system cannot transfer */
#define MSG_FMT_DOS_DISK_ERR            1291      /* dos disk error - format */
#define MSG_FMT_NONSYS_DISK             1292      /* non-system disk - format */
/* 1283 not used */
#define MSG_FMT_COMPLETE                1294      /* format complete - format */
#define MSG_FMT_WP_VIOLATION            1295      /* write protect violation - format */
#define MSG_FMT_NO_WRITE_BOOT           1296      /* unable to write boot - format */
#define MSG_FMT_INCOMPAT_DISK           1297      /* incompatible parms for disk - format */
#define MSG_FMT_PARM_INCOMPAT           1298      /* incompatible parameter - format */
#define MSG_FMT_DRV_NOT_READY           1299      /* drive not ready - format */
/* 1300 - 1301 not used */
#define MSG_FMT_HEAD_CYL                1302      /* head/cylinder - format */
#define MSG_FMT_NOT_SUPPORTED           1303      /* format not supported - format */
/* 1304 - 1306 not used */
#define MSG_FMT_FAT_ERROR               1307      /* error writing fat - format */
#define MSG_FMT_DIR_WRTERR              1308      /* error writing directory - format */
#define MSG_FMT_DRIVE_LETTER            1310      /* drive letter must be specified */
#define MSG_FMT_SYS_FILES               1311      /* cannot find system files - format */
/* 1312 not used */
#define MSG_FMT_BAD_PARTITION           1313      /* bad partition table - format */
/* 1314 not used */
#define MSG_FMT_UNSUPP_PARMS            1316      /* parameters not supported - format */
#define MSG_FMT_WHAT_IS_VOLID           1318      /* enter current volume label for dr %1 */
#define MSG_FMT_BAD_VOLID               1319      /* incorrect volume label for drive %1 */
#define MSG_FMT_TBL_ERR                 1320      /* format.tbl missing or an error */
#define MSG_FMT_TRANSFER                1321      /* format transferred */
#define MSG_FMT_DEFAULT_PARM            1322      /* default parameters /n or /t */
#define MSG_CHK_REAL_MODE_MEM_RPT       1327      /* real mode memory report */
#define MSG_CHK_NON_CONT_BLOCKS         1328      /* non-contig blocks */
#define MSG_CHK_SPEC_FILE_CONT          1329      /* specified files are contig */
#define MSG_CHK_INVALID_PARM            1330      /* invalid parameter - chkdsk */
#define MSG_CHK_DISK_OPEN_ERR           1331      /* cannot open disk error - chkdsk */
#define MSG_CHK_DISK_LOCK_ERR           1332      /* cannot lock disk error - chkdsk */
#define MSG_CHK_INVALID_DRIVE           1333      /* invalid drive specification - chkdsk */
#define MSG_CHK_FAT_READ                1336      /* error reading FAT - chkdsk */
#define MSG_CHK_FAT_WRITE               1337      /* error writing FAT - chkdsk */
#define MSG_CHK_DIRECTORY               1338      /* directory - chkdsk */
#define MSG_CHK_NO_SLASHF               1339      /* errors found, no /F - chkdsk */
#define MSG_CHK_INV_CLUSTER             1340      /* invalid cluster - chkdsk */
#define MSG_CHK_INV_CURDIR              1341      /* invalid current dir - chkdsk */
#define MSG_CHK_ALLOC_ERR               1342      /* allocation error - chkdsk */
#define MSG_CHK_CROSSLINK               1343      /* files cross linked - chkdsk */
#define MSG_CHK_1ST_CLUSTER             1344      /* first cluster bad - chkdsk */
#define MSG_CHK_UNREC_DIRERR            1345      /* unrecoverable dir error - chkdsk */
#define MSG_CHK_CONVERT                 1346      /* conver directory? - chkdsk */
#define MSG_CHK_DIR_EMPTY               1347      /* directory empty - chkdsk */
#define MSG_CHK_INV_SUBDIR              1349      /* invalid subdirectory - chkdsk */
#define MSG_CHK_NO_REC_DOT              1350      /* can't recover . entry - chkdsk */
#define MSG_CHK_NO_REC_DOTDOT           1351      /* can't recover .. entry - chkdsk */
#define MSG_CHK_BAD_LINK                1352      /* bad link - chkdsk */
#define MSG_CHK_BAD_ATTRIB              1352      /* bad file attribute - chkdsk */
#define MSG_CHK_BAD_SIZE                1352      /* bad file size - chkdsk */
/* 1353 - 1354 not used */
#define MSG_CHK_NOT_EXIST               1355      /* file does not exist - chkdsk */
#define MSG_CHK_LOST_CLUSTERS           1356      /* lost clusters - chkdsk */
#define MSG_CHK_SPACE_FREED             1358      /* space freed - chkdsk */
#define MSG_CHK_SPACE_POSSIBLE          1359      /* space available - chkdsk */
#define MSG_CHK_NOROOM_ROOT             1360      /* no room in root - chkdsk */
#define MSG_CHK_DISK_TOTAL              1361      /* total space on disk - chkdsk */
#define MSG_CHK_BAD_SECTORS             1362      /* bad sectors - chkdsk */
#define MSG_CHK_HIDDEN_TOTAL            1363      /* hidden file total - chkdsk */
#define MSG_CHK_DIR_TOTAL               1364      /* directory total - chkdsk */
#define MSG_CHK_FILE_TOTAL              1365      /* file total - chkdsk */
#define MSG_CHK_RECOVER_TOTAL           1366      /* recovered total - chkdsk */
#define MSG_CHK_BYTES_POSSIBLE          1367      /* bytes possible - chkdsk */
#define MSG_CHK_BYTES_AVAIL             1368      /* bytes available - chkdsk */
#define MSG_CHK_PROCESS_STOP            1373      /* can't continue - chkdsk */
#define MSG_CHK_FAT_BAD                 1374      /* bad fat - chkdsk */
#define MSG_CHK_VOL_CREATE              1375      /* can't create volume - chkdsk */
#define MSG_CHK_ERR_WRITE_DIR           1376      /* can't write directory - chkdsk */
#define MSG_CHK_ROOT_BAD_DRV            1377      /* root directory bad - chkdsk */
#define MSG_CHK_NON_DOS                 1379      /* probable non-dos disk - chkdsk */
#define MSG_CHK_ERR_READ_DIR            1380      /* can't read dir - chkdsk */
#define MSG_SAD_DUMPING                 1381      /* dump in process */
#define MSG_SAD_INSERT_NEXT             1382      /* current dump diskette filled */
#define MSG_SAD_DISK_ERROR              1383      /* error with diskette, insert another */
#define MSG_SAD_REINSERT                1384      /* insert dump diskette #1 */
#define MSG_SAD_DISK_OVERWRITE          1385      /* disk will be overwritten - created */
#define MSG_SAD_API_ERR                 1386      /* api error - createdd */
#define MSG_SAD_INV_DRIVE               15        /* invalid drive parm - createdd */
#define MSG_SAD_USED_ONCE               1388      /* dump data is already on the diskette */
#define MSG_SAD_HIGH_CAPACITY           1389      /* high capacity diskette */
#define MSG_SAD_PRO_TERM_USER           1390      /* progm is end by user - createdd */
#define MSG_SAD_COMPLETE                1391      /* dump complete remove and reboot */
#define MSG_SAD_NOT_CONTIG              1392      /* not enough contiguous - createdd */
#define MSG_SAD_MEM_RANGE               1393      /* memory address ranges on this disk ar */
/* 1395 basemid */
#define MSG_SAD_INSERT_NEW              1396      /* insert new dump disk - rascrv */
#define MSG_STCP_NOT_EXIST              1397      /* sys trace does not exist - trace */
#define MSG_STCP_INV_ON_OFF             1399      /* invalid or missing on/off - trace */
#define MSG_STCP_EC_RANGE               1400      /* out of range event code - trace */
#define MSG_STCP_EC_INVALID             1401      /* event codes invalid - trace */
/* 1402 - 1405 not used */
#define MSG_DFMT_ENTER                  1406      /* enter to continue - dumpfmtr */
/* 1407 - 1424 not used */
#define MSG_SAD_INS_PROPER              31        /* diskette error, ensure diskette inser */
#define MSG_SAD_WRITE_PROTECT           19        /* diskette error, write protect tab */
#define MSG_SPOOL_WTRUNC_ERROR          1425      /* cannot release filling file - print */
#define MSG_SPOOL_OPEN_ERROR            1426      /* cannot delete filling file - print */
#define MSG_SPOOL_SIG_ERROR             1427      /* cannot delete printing file - print */
#define MSG_SPOOL_MACH_ERROR            1428      /* cannot hold filling file - print */
#define MSG_SPOOL_RUN_PRINT_DATA        1429      /* spool running with print data redir */
#define MSG_SPOOL_RUN_DEVICE            1430      /* spool print run on device */
#define MSG_SPOOL_INV_PARA              1001      /* spooler invalid parameter */
#define MSG_SPOOL_INV_DEVICE            15        /* spool invalid device */
/* 1431 - 1432  not used */
#define MSG_SPOOL_INV_INPAR             1433      /* spool inval input device para */
#define MSG_SPOOL_INV_OUTPAR            1434      /* spool inval output device para */

#define MSG_SPOOL_INV_DIRPARM           1435      /* spool inval subdirectory */
#define MSG_SPOOL_INT_ERROR             8         /* spool internal error */
/* 1436 not used */
#define MSG_SPOOL_DISK_FULL             1437      /* spool disk full */
#define MSG_SPOOL_CURR_CAN_OPER         1438      /* spooler current cancelled by operator */
#define MSG_SPOOL_ALL_CAN_OPER          1439      /* spooler cancelled by operator */
/* 1440 not used */
#define MSG_SPOOL_SHAR_VIOLAT           1441      /* spool share violation */
#define MSG_SPOOL_ALREADY_RUN           1442      /* spool is already running for device */
#define MSG_SPOOL_DISK_IS_FULL          112       /* spool disk is full action different */
/* 1443 - 1455 not used */
#define MSG_SPOOL_DK_FULL               1437      /* spool disk is full action different */
#define MSG_SYS_NO_ROOM                 1456      /* no room for system on disk - sys */
#define MSG_SYS_BAD_TRANS               1457      /* could not transfer files - sys */
#define MSG_SYS_NO_SYSTEM               1458      /* no system on default drive - sys */
#define MSG_SYS_TARGET_DRIVE_IN_USE     21        /* drive in use by another process -sys */
#define MSG_SYS_INTERNAL_ERROR          1459      /* internal error in sys -sys */
/* 1460 not used */
#define MSG_SYS_INV_PARM                1460      /* invalid parameter - sys */
#define MSG_SYS_INV_DRIVE               1461      /* invalid drive - sys */
#define MSG_SYS_TRANSFERRED             1272      /* system transferred - sys */
#define MSG_FDISK_INV_PART_TABLE        1462      /* invalid partition table */
#define MSG_FDISK_ERR_LOADING_OS        1463      /* error loading operating system */
#define MSG_FDISK_ERR_MISSING_OS        1464      /* missing operating system */
#define MSG_VDISK_INV_PARM              1465      /* invalid parameter - vdisk */
#define MSG_VDISK_INSUFF_MEM            1466      /* insufficient memory - vdisk */
#define MSG_VDISK_REPORT                1467      /* vdisk summary - vdisk */
#define MSG_SES_MGR_TERM                1468      /* session manager terminate ignore */
#define MSG_SES_MGR_MENU                1469      /* session manager menu */
/* */
/* 1470-1474 are for swapper and are in basemid.inc */
/* */
#define MSG_TREE_INV_PARM               1001      /* invalid parameter */
/* 1475  - 1477 not used */
#define MSG_TREE_INV_DRIVE              15        /* invalid drive specification */
#define MSG_TREE_INV_PATH               1478      /* invalid path */
#define MSG_TREE_TOP_HEADER             1479      /* DIRECTORY PATH LISTING */
#define MSG_TREE_PATHNAME               1480      /* Path: %1 */
#define MSG_TREE_SUBDIR_HEADER          1481      /* Sub-directories:  %1 */
#define MSG_TREE_FILE_HEADER            1482      /* Files:            %1 */
#define MSG_TREE_NONE_FILE              1483      /* Files:            None */
#define MSG_TREE_NONE_SUBDIR            1484      /* Sub-directories:  None */
#define MSG_TREE_FILENAME               1485      /*                   %1 */
#define MSG_TREE_NO_SUBDIR_EXIST        1486      /* subdirectory does not exist */
#define MSG_HELP_BAD_MID                1487      /* Invalid message id */
#define MSG_HELP_MID_LARGE              1488      /* Message id too large */
#define MSG_HELP_SYNTAX                 1489      /* Syntax error */
#define MSG_FIND_FILE_NOT_FOUND         1490      /* FIND file not found %1 */
#define MSG_SYNTAX_ERR_FIND             1003      /* FIND syntax error */
#define MSG_INVALID_P_NUM               1003      /* invalid number of parameters */
/* 1491 - 1492 not used */
#define MSG_HELP_NO_HELP                1493      /* No help available */
#define MSG_READ_ERROR_FIND             31        /* FIND read error */
/* 1494 - 1496 not used */
#define MSG_INVALID_PARM_FIND           1002      /* FIND invalid parameter */
#define MSG_PATH_NOT_FIND               3         /* path not found */
/* 1497 - 1499 not used */
#define MSG_VDISK_NO_DRIVES             1505      /* no drive letters for vdisk */
/* 1506 - 1508 unused */
#define MSG_INVALID_DR_LABEL            15        /* invalid drive specification %1 */
/* 1509- 1511 unused */
#define MSG_INVALID_LABEL               123       /* inval charact. in volume label */
/* 1512 - 1513 unused */
#define MSG_HAS_NO_LABEL                1514      /* volume in drive x has no label */
#define MSG_GET_NEW_LABEL               1515      /* volume label (11 char) ent for none % */
#define MSG_DR_VOL_LABEL                1516      /* volume in drive X is */
/* 1517 - 1523 in basemid.inc */
#define MSG_PRINT_INV_PARM              1525      /* invalid command line parameter */
#define MSG_PRINT_TOO_MANY              1526      /* too many command line param entered */
/* 1528 not used */
#define MSG_PRINT_INV_DEVICE            1529      /* invalid printer device */
#define MSG_PRINT_WRITE_ERROR           28        /* error occurred on the printer */
/* 1530 not used */
#define MSG_PRINT_NO_SPOOL              1531      /* spooler not running */
#define MSG_PRINT_REAL_MODE             1532      /* spooler runs only in protect mode */
#define MSG_PRINT_FILE_NOT_FOUND        1533      /* file not found */
#define MSG_FDISK_MAIN_INTRO            1534      /* fdisk setup */
#define MSG_FDISK_MAIN_MENU             1535      /* FDISK options */
#define MSG_FDISK_MAIN_NEXTFDISK        1536      /* 5. Select next fixed disk drive */
#define MSG_FDISK_MAIN_PROMPT           1537      /* Enter choice: */
#define MSG_FDISK_CHANGE_CANTACT        1538      /* table partition can't be made active */
#define MSG_FDISK_CHANGE_CURACT         1539      /* current active partition is %1 */
#define MSG_FDISK_CHANGE_DONE           1540      /* partition %1 made active */
#define MSG_FDISK_CHANGE_NOPART         1541      /* No partitions to make active */
#define MSG_FDISK_CHANGE_1PART          1542      /* Partition 1 is already active */
#define MSG_FDISK_CHANGE_PROMPT         1543      /* Enter the number of the partition you */
#define MSG_FDISK_CHANGE_TITLE          1544      /* change active partition */
#define MSG_FDISK_CREATE_DONE           1545      /* DOS partition created */
#define MSG_FDISK_CREATE_NOSPACE        1546      /* No space for a %1 partition */
#define MSG_FDISK_CREATE_NOSPATHE       1547      /* No space for %1 cylinder at cyl%2 */
#define MSG_FDISK_CREATE_NOSPAFDOS      1548      /* No space to create a DOS partition */
#define MSG_FDISK_CREATE_PARTEXISTS     1549      /* fixed disk already has a dos partit */
#define MSG_FDISK_CREATE_SIZEPROMPT     1550      /* Enter partition size... */
#define MSG_FDISK_CREATE_SPACEAT        1551      /* Max avail space is %1 cyl at %2. */
#define MSG_FDISK_CREATE_STARTPROMP     1552      /* enter starting cylinder number... */
#define MSG_FDISK_CREATE_TITLE          1553      /* create DOS partition */
#define MSG_FDISK_CREATE_WHOLEDISK      1554      /* Do you want to use the entire fd y/n */
#define MSG_FDISK_DELETE_DONE           1555      /* DOS partition deleted */
#define MSG_FDISK_DELETE_NOPART         1556      /* No DOS partition to delete */
#define MSG_FDISK_DELETE_PROMPT         1557      /* Warning! Data in the DOS part lost */
#define MSG_FDISK_DELETE_TITLE          1558      /* Delete DOS partition yn */
#define MSG_FDISK_DISPLAY_FDISKSIZE     1559      /* Total disk space is %1 cylinders. */
#define MSG_FDISK_DISPLAY_NOPARTS       1560      /* No partitions defined */
#define MSG_FDISK_DISPLAY_PARTINFO      1561      /* Partition status type start endsize */
#define MSG_FDISK_DISPLAY_TITLE         1562      /* Display partition information */
#define MSG_FDISK_ERR_INVALIDNUMBER     1563      /* %1 is not a choice.  Please enter a c */
#define MSG_FDISK_ERR_INVALIDYN         1564      /* %1 is not a choice.  Please enter yn */
#define MSG_FDISK_ERR_NOFDISKS          1565      /* no fixed disks present */
#define MSG_FDISK_ERR_READ              1566      /* error reading fixed disk */
#define MSG_FDISK_ERR_WRITE             1567      /* error writing fixed disk */
#define MSG_FDISK_CURRENTDISK           1568      /* current fixed disk drive %1 */
#define MSG_FDISK_PRESSESC              1569      /* press esc to return to fdisk options */
#define MSG_FDISK_MUST_RESTART          1570      /* must restart */
#define MSG_FDISK_IN_USE                1571      /* fixed disk in use */
/* 1572 - 1574 unused */
#define MSG_PATCH_INV_NUM_PARMS         1575      /*invalid number of parameters */
#define MSG_PATCH_INV_PARM              1575      /* invalid parameter %1%2 */
/* 1576 not used */
#define MSG_PATCH_NO_CTL                1490      /* cannot open patch control file %1 */
#define MSG_PATCH_NO_EXE_FILE           1490      /* cannot open %1 to patch */
/* 1577 - 1578 not used */
#define MSG_PATCH_PATCHING              1579      /* patching %1 */
#define MSG_PATCH_CONTINUE              1580      /* continue patching %1? Y/N */
#define MSG_PATCH_NO_PATCHES            1581      /* No patches applied */
#define MSG_PATCH_PATCHES_ENTERED       1582      /* Patches entered for %1 */
#define MSG_PATCH_OK_TO_PATCH           1583      /* should these patches be appl to %1? */
#define MSG_PATCH_APPLIED               1584      /* patches applied to %1 */
#define MSG_PATCH_NOT_APPLIED           1585      /* No patches applied to %1 */
#define MSG_PATCH_CURRENT_EOF           1586      /* Current end of file is at %1 */
#define MSG_PATCH_OFFSET_PROMPT         1587      /* enter offset in hex of patch > */
#define MSG_PATCH_PAST_EOF_INT          1588      /* offset is past end of file */
#define MSG_PATCH_CANT_ALLOC            1589      /* Insufficient memory to save pat inf */
#define MSG_PATCH_NO_FILE               1590      /* no file to patch fond in pat con %1 */
#define MSG_PATCH_INV_CMD_COMBO         1591      /* %1 command found without a %2 cmd */
#define MSG_PATCH_INV_OFFSET            1592      /* %1 is not a valid offset for file %2 */
#define MSG_PATCH_INV_BYTES             1593      /* %1 is not a valid %2 byte stg for%3 */
#define MSG_PATCH_TOO_NEAR_EOF          1594      /* offset %1 for %2 too near orpst%3%4 */
#define MSG_PATCH_VERIFY_FAILED         1595      /* verification failed for %1 */
/* 1596 not used */
#define MSG_PATCH_PAST_EOF_AUTO         1597      /* ofst given %1 ofr %2 eof %3 */
#define MSG_PATCH_UNKNOWN_CMD           1598      /* unknown command */
#define MSG_PATCH_CANT_APPEND           1599      /* cannot append */
#define MSG_PATCH_NO_REQUEST            1600      /* no patch request specified */
#define MSG_MODE_INVAL_PARMS            1601      /* invalid number of parameters */
#define MSG_MODE_CPL_SET                1602      /* characters per line has been set */
#define MSG_MODE_LPI_SET                1603      /* lines per inch have been set */
#define MSG_MODE_INF_RET_SET            1604      /* infinite has been set */
#define MSG_MORE                        1605      /* -- More -- */
#define MSG_MODE_INF_RET_RESET          1606      /* infinite retry reset */
#define MSG_MODE_DEVICE_NAME            1607      /* invalid device name */
#define MSG_PRINT_ERROR                 29        /* printer error */
/* 1608 not used */
#define MSG_MODE_ASYNC_SET              1609      /* async protocol set */
/* 1610 not used */
#define MSG_MODE_NO_REDIR               1611      /* mode cannot direct output */
/* 1612 not used */
#define MSG_INVALID_PARITY              1613      /* open parity */
#define MSG_INVALID_DATABITS            1614      /* invalid databits */
#define MSG_INVALID_STOPBITS            1615      /* invalid stopbits */
#define MSG_INVALID_BAUD_RATE           1616      /* invalid baud rate */
#define MSG_INVALID_CHAR_PER_LINE       1617      /* invalid characters per line */
#define MSG_INVALID_LINES_PER_INCH      1618      /* invalid lines per inch */
#define MSG_INVALID_SYNTAX              1601      /* invalid syntax */
/* 1619 - 1621 not used */
#define MSG_MODE_OUT_RANGE              1622      /* mode out of range */
#define MSG_MODE_INV_PARM               1601      /* invalid parameter */
/* 1623 - 1625 unused */
#define MSG_INVAL_PARAMETER             1002      /* invalid parameter attrib */
#define MSG_FILEN_REQUIRED              2         /* filename required attrib */
/* 1626 - 1627 unused */
#define MSG_UNEX_DOS_ERROR              1628      /* unexpected dos error */
/* 1629 - 1633 unused */
