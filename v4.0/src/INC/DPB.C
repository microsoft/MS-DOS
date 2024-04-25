/* dpb.c - retrieve DPB for physical drive */

#include "types.h"
#include "sysvar.h"
#include "dpb.h"
#include "cds.h"

extern char NoMem[], ParmNum[], BadParm[] ;
extern struct sysVarsType SysVars ;


/* Walk the DPB list trying to find the appropriate DPB */

long GetDPB(i)
int i ;
{
        struct DPBType DPB ;
        struct DPBType *pd = &DPB ;
        struct DPBType far *dptr ;
        int j ;

        *(long *)(&dptr) = DPB.nextDPB = SysVars.pDPB ;
        DPB.drive = -1 ;

        while (DPB.drive != i) {
                if ((int)DPB.nextDPB == -1)
                        return -1L ;

                *(long *)(&dptr) = DPB.nextDPB ;

                for (j=0 ; j < sizeof(DPB) ; j++)
                         *((char *)pd+j) = *((char far *)dptr+j) ;

        } ;
        return (long)dptr ;
}

