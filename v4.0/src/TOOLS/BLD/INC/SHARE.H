/***
*share.h - defines file sharing modes for sopen
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the file sharing modes for sopen().
*
*******************************************************************************/

#define SH_COMPAT   0x00    /* compatibility mode */
#define SH_DENYRW   0x10    /* deny read/write mode */
#define SH_DENYWR   0x20    /* deny write mode */
#define SH_DENYRD   0x30    /* deny read mode */
#define SH_DENYNO   0x40    /* deny none mode */
