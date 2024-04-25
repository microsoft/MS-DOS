/***
*sys\locking.h - flags for locking() function
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the flags for the locking() function.
*   [System V]
*
*******************************************************************************/

#define LK_UNLCK    0   /* unlock the file region */
#define LK_LOCK     1   /* lock the file region */
#define LK_NBLCK    2   /* non-blocking lock */
#define LK_RLCK     3   /* lock for writing */
#define LK_NBRLCK   4   /* non-blocking lock for writing */
