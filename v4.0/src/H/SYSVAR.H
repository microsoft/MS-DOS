struct sysVarsType
{
        long    pDPB ;          /* pointer to DPB chain                    */
        long    pSFT ;          /* pointer to System File Table            */
        long    pClock ;        /* pointer to clock device                 */
        long    pCon ;          /* pointer to CON device                   */
        unsigned maxSec ;       /* size of largest physical sector         */
        long    pBuf ;          /* pointer to buffer cache                 */
        long    pCDS ;          /* pointer to Current Dirs                 */
        long    pFCBSFT ;       /* pointer to FCB sftable                  */
        unsigned cKeep ;        /* number of un-recyclable FCBs            */
        char    cDrv ;          /* maximum number of physical drives       */
        char    cCDS ;          /* number of Current Dirs                  */
#ifdef DOS4
        long    pDEVHLP ;       /* ptr DOS DevHlp routine                  */
#endif
        long    pDEV ;          /* pointer to device list                  */
        unsigned attrNUL ;      /* attributes of NUL device                */
        unsigned stratNUL ;     /* strategy entry point of NUL dev         */
        unsigned intNUL ;       /* interrupt entry point of NUL dev        */
        char    namNUL[8] ;     /* name of NUL device                      */
        char    fSplice ;       /* TRUE => splices are in effect           */
        unsigned ibmdos_size ;  /* ;AN000; size in paragraphs              */
        long    ifs_doscall ;   /* ;AN000; IFS serv routine entry          */
        long    ifs ;           /* ;AN000; IFS header chain                */
        unsigned buffers ;      /* ;AN000; BUFFERS= values (m,n)           */
        char    boot_drive ;    /* ;AN000; boot drive A=1 B=2...           */
        char    dwmove ;        /* ;AN000; 1 if 386 machine                */
} ;
