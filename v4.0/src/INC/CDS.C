/* cds utilities */
/* #include "types.h"  */
#include "sysvar.h"
#include "cds.h"
#include "dpb.h"
#include <dos.h>
#include "jointype.h"

extern struct sysVarsType SysVars ;

char fGetCDS(i, pLCDS)
int i ;
struct CDSType *pLCDS ;
{
        struct CDSType far *cptr ;
        int j ;
                                                /* Get pointer to CDS */
        if (i >= 0 && i < SysVars.cCDS) {
                *(long *)(&cptr) = SysVars.pCDS + (i * sizeof(*pLCDS)) ;

                                                /* Copy CDS to our program */
                for (j=0 ; j < sizeof(*pLCDS) ; j++)
                        *((char *)pLCDS+j) = *((char far *)cptr+j) ;

                return TRUE ;
        } ;
        return FALSE ;
}




char fPutCDS(i, pLCDS)
int i ;
struct CDSType *pLCDS ;
{
        struct CDSType far *cptr ;
        int j ;

        if (i >= 0 && i < SysVars.cCDS) {
                *(long *)(&cptr) = SysVars.pCDS + (i * sizeof(*pLCDS)) ;

                for (j=0 ; j < sizeof(*pLCDS) ; j++)
                        *((char far *)cptr+j) = *((char *)pLCDS+j) ;

                return TRUE ;
        } ;
        return FALSE ;
}

/* returns TRUE if drive i is a physical drive.  Physical means that logical
 * drive n corresponds with physical drive n.  This is the case ONLY if the
 * CDS is inuse and the DPB corresponding to the CDS has the physical drive
 * equal to the original drive.
 */

char fPhysical(i)
int i ;
{
        struct DPBType DPB ;
        struct DPBType *pd = &DPB ;
        struct DPBType far *dptr ;
        int j ;

        struct CDSType CDS ;

        if (!fGetCDS(i, &CDS))
                return FALSE ;

        if (TESTFLAG(CDS.flags,CDSNET | CDSSPLICE | CDSLOCAL))
                return FALSE ;

        *(long *)(&dptr) = CDS.pDPB ;

        for (j=0 ; j < sizeof(DPB) ; j++)
                 *((char *)pd+j) = *((char far *)dptr+j) ;

        return(i == DPB.drive) ;
}

/* return TRUE if the specified drive is a network drive.  i is a 0-based
 * quantity
 */

/*      MODIFICATION HISTORY
 *
 *  M000        June 5/85       Barrys
 *  Removed extra net check.
 */

char fNet(i)
int i ;
{
        union REGS ir ;
        register union REGS *iregs = &ir ;      /* Used for DOS calls      */

        struct CDSType CDS ;

        if (!fGetCDS(i, &CDS))
                return FALSE ;

        iregs->x.ax = IOCTL9 ;                  /* Function 0x4409         */
        iregs->x.bx = i + 1 ;
        intdos(iregs, iregs) ;

/***    M000
        return(TESTFLAG(CDS.flags,CDSNET) || TESTFLAG(iregs->x.dx,0x1000)) ;
/***/
        return(TESTFLAG(CDS.flags,CDSNET)) ;
}


/* return TRUE if the specified drive is a shared drive.  i is a 0-based
 * quantity
 */
char fShared(i)
int i ;
{
        struct CDSType CDS ;
        union REGS ir ;
        register union REGS *iregs = &ir ;      /* Used for DOS calls      */

        if (!fGetCDS(i, &CDS))
                return FALSE ;

        iregs->x.ax = IOCTL9 ;                  /* Function 0x4409         */
        iregs->x.bx = i + 1 ;
        intdos(iregs, iregs) ;

        return TESTFLAG(CDS.flags,CDSNET) || TESTFLAG(iregs->x.dx,0x0200) ;
}
