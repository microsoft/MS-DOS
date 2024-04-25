/*      SCCSID = @(#)utlerror.h	8.7 87/03/09 */
/* */
/* error codes for utilities */
/* */

#define ERROR_INVALID_DOSVER            1000      /* invalid dos version */
#define ERROR_LANGUAGE_NOT_SUPPORTED    1001      /* language not supported */
#define ERROR_INVALID_FILENAME          1002      /* invalid file name */
#define ERROR_MSGFILE_BAD_FORMAT        1010      /* bad message file format */
#define ERROR_MSGFILE_BAD_MID           1011      /* message file has bad mid */
#define ERROR_MSGFILE_OUTERROR          1012      /* error writing output file */
#define ERROR_MSGFILE_INPERROR          1013      /* error reading input file */
#define ERROR_MSGFILE_SYNTAX            1014      /* syntax error */
#define ERROR_MSGFILE_MSG_TOO_BIG       1015      /* message exceeds system limit */
#define ERROR_INSTALL_FAILED            1016      /* install failed */
#define ERROR_INVALID_VOL               1017      /* no volume with /s option */
#define ERROR_INVALID_INPUT_PARM        1018      /* invalid input parameter */
#define ERROR_FILE_SPEC_REQUIRED        1019      /* file specification required */
#define ERROR_SORT_FILE_TOO_BIG         1020      /* file size to big to sort */
#define ERROR_SORT_INVALID_COL          1021      /* invalid column number for sort */
#define ERROR_CHK_BAD_FAT               1022      /* fat bad on specified drive */
#define ERROR_CHK_BAD_ROOT              1023      /* root bad on specified drive */
#define ERROR_INVALID_PARM_NUMBER       1024      /* invalid parameter number */
#define ERROR_PARM_SYNTAX               1025      /* invalid parameter syntax */
#define ERROR_UTIL_TERMINATED           1026      /* program terminated by user */
#define ERROR_REST_NO_BACKUP            1027      /* source does not contain backup file */
#define ERROR_REST_SEQUENCE_ERROR       1028      /* file sequence error */
#define ERROR_REST_FILE_CREATE          1029      /* file creation error */
#define ERROR_FDISK_ERR_WRITE           1030      /* error writing fixed disk */
#define ERROR_FDISK_ERR_READ            1031      /* error reading fixed disk */
#define ERROR_FDISK_ERR_NOFDISKS        1032      /* no fixed disk present */
#define ERROR_PATCH_NO_CTL_FILE         1033      /* cannot open patch control file */
#define ERROR_PATCH_NO_EXE_FILE         1034      /* cannot open file to patch */
#define ERROR_PATCH_CANT_ALLOC          1035      /* insufficient memory to alloc patch */
#define ERROR_PATCH_INV_CMD_COMBO       1036      /* bad command sequence */
#define ERROR_PATCH_INV_OFFSET          1037      /* invalid offset */
#define ERROR_PATCH_INV_BYTES           1038      /* invalid byte string */
#define ERROR_PATCH_TOO_NEAR_EOF        1039      /* too close to end of file */
#define ERROR_PATCH_VERIFY_FAILED       1040      /* verification failed */
#define ERROR_PATCH_INC_VERIFY          1041      /* offset verification failed */
#define ERROR_SPOOL_INVAL_DEVICE        1042      /* invalid device */
#define ERROR_SPOOL_INVAL_IN_DEV_PAR    1043      /* invalid input device parm */
#define ERROR_SPOOL_INVAL_OUT_DEV_PAR   1044      /* invalid output device parm */
#define ERROR_SPOOL_INVAL_SUB           1045      /* invalid subdirectory */
#define ERROR_SPOOL_INTERN_ERROR        1046      /* internal error */
#define ERROR_SPOOL_DISK_FULL           1047      /* spool disk full */
#define ERROR_SPOOL_CANNOT_PT_NXT_FI    1048      /* cannot print next file */
#define ERROR_SPOOL_CANNOT_PTR_NOW_FI   1049      /* cannot print now */
#define ERROR_XCOPY_CANNOT_COPY_SUB     1050      /* cannot copy subdirectory */
#define ERROR_XCOPY_ITSELF              1051      /* cannot copy to itself */
#define ERROR_DISKC_DRIVE_SPEC          1052      /* drive mismatch in diskcomp/copy */
#define ERROR_FORMAT_FAIL               1053      /* format failed */
#define ERROR_FORMAT_INV_MEDIA          1054      /* format had invalid media */
#define ERROR_RAS_STCP                  1055      /* system trace command processor error */
#define ERROR_RAS_CREATEDD              1056      /* error in create dump diskette */
#define ERROR_XCOPY_UNAB_CREATE_DIR     1057      /* unable to create directory */
#define ERROR_XCOPY_PATH_TOO_LONG       1058      /* path to long */
#define ERROR_XCOPY_CANNOT_TO_RES_DEV   1059      /* can't copy to a reserved name */
#define ERROR_XCOPY_CANNOT_COPY_RES     1060      /* can't copy from a reserved name */
#define ERROR_XCOPY_INVAL_DATE          1061      /* invalid date */
#define ERROR_XCOPY_INTERNAL            1062      /* xcopy internal error */
#define ERROR_PRINT_INVALID_PARAMETER   1063      /* invalid parameter */
#define ERROR_PRINT_FILE_NOT_FOUND      1064      /* file not found */
#define ERROR_PRINT_INVALID_DRIVE       1065      /* invalid drive */
#define ERROR_PRINT_INVALID_DOSVER      1066      /* invalid DOS version */
#define ERROR_PRINT_BAD_ENVIRONMENT     1067      /* bad environment */
#define ERROR_PRINT_MSGFILE_BAD_MID     1068      /* bad message ID */
#define ERROR_PRINT_SYS_INTERNAL        1069      /* PRINT internal error */
#define ERROR_SYS_SYS_INTERNAL          1070      /* SYS internal error */
#define ERROR_SYS_MSGFILE_BAD_MID       1071      /* bad message ID */
#define ERROR_SYS_INVALID_DOSVER        1072      /* invalid DOS version */
#define ERROR_SYS_INVALID_DRIVE         1073      /* invalid drive */
#define ERROR_SYS_INVALID_MEDIA         1074      /* invalid media */
#define ERROR_SYS_INVALID_PARM          1076      /* invalid parameter */
#define ERROR_FORMAT_INTERRUPT          1077      /* format interrupted */
#define ERROR_FORMAT_NO_SYSXFER         1078      /* error in system xfer */
#define ERROR_FORMAT_USER_TERM          1079      /* terminated by N resp */
#define ERROR_BACK_NO_FILES             1080      /* no files found for backup */
#define ERROR_BACK_SHARE_ERROR          1081      /* sharing error during backup */
#define ERROR_BACK_FDISKFULL            1082      /* fixed disk is full during backup */
#define ERROR_BACK_INVTARGET            1083      /* invalid backup target disk */
#define ERROR_BACK_INVTIME              1084      /* invalid time parameter */
#define ERROR_BACK_NOSOURCE             1085      /* no source backup files */
#define ERROR_BACK_NOTARGET             1086      /* no target backup files */
#define ERROR_BACK_SRC_TGT_SAME         1087      /* backup source and target same */
#define ERROR_MSGFILE_DBCS              1088      /* error in message file dbcs */
#define ERROR_HELP_MID_LARGE            1089      /* error in message file dbcs */
#define ERROR_HELP_SYNTAX               1090      /* error in message file dbcs */
#define ERROR_HELP_BAD_MID              1091      /* error in message file dbcs */
#define ERROR_HELP_NO_HELP              1092      /* error in message file dbcs */
#define ERROR_SORT_RCD_SIZE_EXCEED      1093      /* sort record size exceeded */
#define ERROR_CM_EOF_REDIRECT           1094      /* eof found on redr input */
