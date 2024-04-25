/***
*sys\types.h - types returned by system level calls for file and time info
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines types used in defining values returned by system
*   level calls for file status and time information.
*   [System V]
*
*******************************************************************************/

#ifndef _INO_T_DEFINED
typedef unsigned short ino_t;       /* i-node number (not used on DOS) */
#define _INO_T_DEFINED
#endif

#ifndef _TIME_T_DEFINED
typedef long time_t;
#define _TIME_T_DEFINED
#endif

#ifndef _DEV_T_DEFINED
typedef short dev_t;                /* device code */
#define _DEV_T_DEFINED
#endif

#ifndef _OFF_T_DEFINED
typedef long off_t;                 /* file offset value */
#define _OFF_T_DEFINED
#endif
