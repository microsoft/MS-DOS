

/*  MAPDMA.C   - Ensures DMA Xfer area is physically contiguous. Swaps pages 
 *               if necessary.
 *
 *  Date    Author      Comments
    8/12/88 JHB         updated comments, checking for sufficient pages
                        available in DMA_Pages[] before remappping

    8/18/88 JHB         if incoming parameters appear to be wrong or
                        if any unmapped page found in the transfer area assume 
                        the Address and Count registers do not have valid values
                        and hence return without swapping pages.
                        Removed IFDEF DEBUG code
 */

#define HEX4K           0x1000
#define HEX16K          0x4000L
#define HEX64K          0x10000
#define HEX128K         0x20000
#define HEX256K         0x40000L
#define HEX640K         0xA0000L
#define HEX1MB          0x100000L

#define ALIGN128K       ~0x1FFFFL
#define ALIGN64K        ~0x0FFFFL
#define ALIGN16K        ~0x03FFFL

#define MAX_PHYS_PAGES  40

/* macros 
 * PT(a)       - pte from index a
 * INDEX(a)    - index from Linear Adr
 * OFFSET(a)   - offset from Linear Adr
 * LIN2PHY(l)  - Physical Adr from Linear Adr
 * DosPhyPage  - consider 16K pages from 0 to 1MB. Let Page at 256K be page 0.
 * DOSPHYPAGE(a) - DosPhyPage for Adr in 1 MB range
 * PFT(a)      - pick up ith entry in pft386[] 
 */

#define PT(a)           (GetPteFromIndex((a)))
#define INDEX(a)        ((((long)a)>>12) & 0x3FF)
#define OFFSET(a)       (((long)a) & 0xFFF)
#define LIN2PHY(l)      ((PT(INDEX(l)) & ~0xFFFL)+(long)OFFSET(l))
#define DOSPHYPAGE(a)   (((a)>>14)-16)
#define PFT(a)          (*(long *)(pft386+a))
struct mappable_page {
   unsigned short page_seg;            /* segment of physical page */
   unsigned short physical_page;       /* physical page number */
};

/* Xlates DosPhyPage into an index in mappable_pages[]. */
extern char EMM_MPindex[];    /* index from 4000H to 10000H in steps of 16K */
extern struct mappable_page mappable_pages[];
extern long *pft386;
extern unsigned DMA_Pages[];
extern DMA_PAGE_COUNT;                 /* size of DMA_Pages[] */
extern unsigned physical_page_count;

/* routines imported from elimtrap.asm */
extern long GetPte();                  /* get a PT entry given index */
extern SetPte();                       /* set a PT entry */
extern unsigned GetCRSEntry();   /* get CurRegSet entry for given EmmPhyPage */
extern long GetDMALinAdr();      /* Get Linear Adr for the DMA buffer */
extern Exchange16K();                  /* exchange page contents */
extern FatalError();

/* forward declarations */
long GetPteFromIndex();

/* 
 * SwapDMAPages()
 *    FromAdr - DMA Xfer addr
 *    Len - Xfer length
 *    bXfer - 0 for byte transfer, 1 for word transfer
 *
 * Check whether the DMA Xfer area starting at FromAdr is contiguous in 
 * physical memory. If it isn't, make it contiguous by exchanging pages
 * with the DMA buffer.
 */

long SwapDMAPages(FromAdr, Len, bXfer)
long FromAdr, Len;
unsigned bXfer;
{
unsigned Index, Offset, /* components of a PTE */
      n4KPages,         /* # of 4K Pages involved in the DMA transfer */
      PhyPages[8],      /* Emm Phy page numbers involved in the DMA transfer 
                           atmost 8.*/
      DMAPageK,         /* kth DMA Page - start exchanging pages from here */
      Page, MPIndex;

long  FromAdr16K,       /* FromAdr rounded down to 16K boundary */
      FromAdr64_128K,   /* FromAdr rounded down to 64/128K boundary */
      ToAdr,            /* Last Byte for the DMA trasfer */
      ToAdr16K,         /* ToAdr rounded down to 16K boundary */
      ExpectedAdr,   
      PgFrame,          /* PgFrame Address */
      First64_128K_Adr, Last64_128K_Adr,/* First and Last 4K page aligned on a 64/128 boundary */ 
      Adr, PhyAdr, LinAdr;          

int i, j, k, bSwap,
      n16KPages;        /* # of 16K Pages involved in the DMA transfer */


   if (FromAdr < HEX256K || FromAdr >= HEX1MB) 
      return LIN2PHY(FromAdr);   /* not in the EMM area */

/* Since the Address and count register are programmed a byte at a time
 * they might have invalid values in them (because of left overs).
 * If invalid parameters, i.e. Xfer area crosses 64K or 128K boundary,or count 
 * is invalid or the DMA Xfer area has unmapped pages - just return.
 */
   if ((!bXfer && (FromAdr + Len) > ((FromAdr & ALIGN64K) + HEX64K)) ||
       (bXfer && (FromAdr + Len) > ((FromAdr & ALIGN128K) + HEX128K)) ||
       (!bXfer && Len > HEX64K) || (bXfer && Len > HEX128K))
      return FromAdr;   /* assume DMA registers not programmed yet */

/* initialise PhyPages[] - unequal negative values */
   for (i = 0; i < 8; i++)
      PhyPages[i] = -(i+1);


/* The DMA buffer is part of the Emm pool.
 * Hence we can only swap pages which are 16K in size. Hence calculate 
 * n16KPages - # of 16K pages involved in the transfer.

 * ToAdr - Linear Address of the last byte where the DMA transfer 
 * is to take place 
 */
   ToAdr = FromAdr + Len - 1L;
   FromAdr16K = FromAdr & ALIGN16K;
   ToAdr16K = ToAdr & ALIGN16K;
   n16KPages = ((ToAdr16K - FromAdr16K)>>14) + 1; /* (ToAdr16K-FromAdr16K)/HEX16K + 1 */

/* If any unmapped page in the transfer area - assume DMA registers not 
 * fully programmed yet
 */
   for (i = 0, Adr = FromAdr16K; Adr <= ToAdr16K; Adr += HEX16K, i++)   {
      MPIndex = EMM_MPindex[DOSPHYPAGE(Adr)];
      if (MPIndex == -1)   /* Adr not mappable */
         return FromAdr;
      else  {
         PhyPages[i] = GetCRSEntry(mappable_pages[MPIndex].physical_page);
         if (PhyPages[i] == -1)  /* Adr not mapped currently */
            return FromAdr;
      }
   }
      
   for (j = 0; j < i; j++) {
      Page = PhyPages[j];
      for (k = j+1; k < i; k++)  {
         if (PhyPages[k] == Page) 
            FatalError("SwapDMAPages : Two Emm pages mapped to same logical page in the xfer area");
      }
   }

/* No unmapped page in the transfer area. Assume the Address and count registers
 * have meaningful values in them.
 */
   Index = INDEX(FromAdr);
   PgFrame = PT(Index) >> 12;
   Offset = OFFSET(FromAdr);
   PhyAdr = (((long)PgFrame) << 12) + Offset;

   if (Offset + Len <= HEX4K)  /* within a page */
      return PhyAdr;

/* calculate # of 4K pages involved in the DMA transfer */

   n4KPages = ((Offset + Len)>>12) + 1;   /* (Offset+Len)/4096K + 1 */
   if (((Offset + Len) % HEX4K) == 0)
      n4KPages--;

/* see if these n4KPages are physically contiguous */
   bSwap = 0;
   for (i = 1; i < n4KPages; i++)   {
      if ((PT(Index + i)>>12) != (PgFrame + i)) {
         bSwap = 1;
         break;
      }
   }

/* Suppose the Xfer area is physically contiguous. We may still need to swap
 * pages with the DMA buffer if the physical pages straddle a 64K/128K boundary
 * (the DMA will wrap around in this case). DOS would have tried to fix this
 * but it would have split the Linear Address - this is of very little use.
 * 
 * if (!bSwap && straddling 64/128K boundary) set bSwap;
 */
   if (!bSwap) {  /* the DMA Pages are contiguous, any straddling ? */
      if (!bXfer) {  /* byte transfer */
         First64_128K_Adr = PT(Index) & ALIGN64K;
         Last64_128K_Adr = PT(Index+n4KPages-1) & ALIGN64K;
      }
      else  {     /* word transfer */
         First64_128K_Adr = PT(Index) & ALIGN128K;
         Last64_128K_Adr = PT(Index+n4KPages-1) & ALIGN128K;
      }
      
      if (First64_128K_Adr != Last64_128K_Adr) 
         bSwap = 1;
   }

   if (!bSwap) 
      return PhyAdr;

/* The DMA transfer area is not contiguous. The DMA buffer is part of the Emm
 * pool. Hence we can only swap pages which are 16K in size. n16KPages is the
 * # of 16K pages involved in the transfer.
 */

/* Round down FromAdr to 64/128K boundary */
   if (bXfer)  /* word transfer ? */
      FromAdr64_128K = FromAdr & ALIGN128K; /* Align on 128K boundary */
   else
      FromAdr64_128K = FromAdr & ALIGN64K;    /* Align on 64K boundary */

/* Swap pages so that the DMA Xfer area is physically contiguous.
   
               |        |                      |        |
 FromAdr     ->|        |                      |        |
               |        |                      |        |
               |        |                      |        |
 FromAdr16K  ->|        | - - - DMAPage[k]  -->|        |
               |        |                      |        |
               |        |                      |        |
FromAdr64_128k-|        |       DMAPage[0]  -->|        |
               ----------                      ----------

   DMA transfer area starts at FromAdr.
   Map kth DMA page to FromAdr16K and so on until all the transfer area is mapped 
 
 */

/* Linear Adr of user page which has to be relocated */
   LinAdr = FromAdr16K;

/* corresponding DMA Page - k value in the above figure */
   DMAPageK = (FromAdr16K - FromAdr64_128K) >> 14;
   
   ExpectedAdr = PFT(DMA_Pages[DMAPageK]);

   if (DMAPageK + n16KPages > DMA_PAGE_COUNT)
      FatalError("Insufficient DMA pages in the DMA Buffer");

   for (k = DMAPageK; k < DMAPageK + n16KPages; k++, LinAdr += HEX16K,
                                                     ExpectedAdr += HEX16K)   {
      /* Already mapped correctly ? */
      if (LIN2PHY(LinAdr) == ExpectedAdr) 
         continue;
      /* Swap the 16K page(4 4K pages) at LinAdr with the kth DMA Page */
      SwapAPage(LinAdr, k);
   }
   
   return LIN2PHY(FromAdr);
}

/* Swap the 16K page(4 4K pages) at LinAdr with the kth DMA Page.
 * Update the Emm Data Structures to reflect this remapping.
 * Update the Page Table too.
 */
SwapAPage(LinAdr, k)
long LinAdr;
unsigned k;
{
unsigned DosPhyPage, /* each page 16K in size, page at 256K is Page 0 */
         EmmPhyPage, /* Phy page numbering according to Emm */
         UserPFTIndex;  /* index into pft386 for Emm phy page at LinAdr */

long DMAPhyAdr, DMALinAdr;
int i, j;

/* Updating Emm data structures */

/* Find the pft386 entry for LinAdr */
   DosPhyPage = DOSPHYPAGE(LinAdr); /* Page at 256K is page zero */
   EmmPhyPage = mappable_pages[EMM_MPindex[DosPhyPage]].physical_page;

/* get the CurRegSet entry for this physical page. */
   UserPFTIndex = GetCRSEntry(EmmPhyPage);
   
   if (UserPFTIndex == -1)
      FatalError("Cannot find PFT386 entry for EMM page corresponding to LinAdr");   
      
/* exchange pft386 entries at UserPFTIndex and DMA_Pages[k] */

   DMAPhyAdr = PFT(DMA_Pages[k]);
   PFT(DMA_Pages[k]) = PFT(UserPFTIndex);
   PFT(UserPFTIndex) = DMAPhyAdr;

/* Fix Page table entries .
 * The contents of the user page and DMA buffer page are exchanged always.
 *  - because a mapping for this page may exist in a saved context,
 *  - can do a one way copy if the non-existence of such a mapping is detected
 *    by scanning emm_pages[]. Will optimize this later. 8/12/88 - JHB
 *
 * The PT entry for the user page has to be updated.
 * There may or may not exist a PT entry for the DMA page. There exists
 * an entry only if there exists a mapping in the CurRegSet. If there exists
 * an entry it should be updated too.
 */

/* Does PT Entry exist for the DMA buffer below 1 MB? */

   for (i = 0; i < physical_page_count; i++) {
      if (GetCRSEntry(i) == DMA_Pages[k])
         break;
   }

   if (i == physical_page_count) {  
      /* No Phy page mapped to the DMA page - so no pte to be updated for DMA Page */       
      Exchange16K(LinAdr, GetDMALinAdr(DMAPhyAdr));
      UpdateUserPTE(LinAdr, UserPFTIndex);
   }
   else  {
      /* ith EmmPhyPage mapped to DMA buffer 
       * Scan mappable_pages[] array and find the Linear address that maps to it.
       */
      for (j = 0; j < MAX_PHYS_PAGES; j++)   {
         if (mappable_pages[j].physical_page == i)
            break;
      }
      if (j == MAX_PHYS_PAGES)
         FatalError(); /* invalid Phy page # - doesn't exist in mappable_pages[] */
      else
         DMALinAdr = ((long )mappable_pages[j].page_seg) << 4;
      
      Exchange16K(LinAdr, DMALinAdr);
      ExchangePTEs(LinAdr, DMALinAdr);
   }
   
/* UserPFTIndex is present in DMA_Pages[] we should exchange the entries in
 * DMA_Pages[] */
   for (i = 0; i < DMA_PAGE_COUNT; i++)   {
      if (DMA_Pages[i] == UserPFTIndex)   {
         DMA_Pages[i] = DMA_Pages[k];
         break;
      }
   }

/* Now, DMA_Pages[k] has a different index into the pft386[] array */
   DMA_Pages[k] = UserPFTIndex; 
}

/* Update PT entry for LinAdr to map to pft386[UserPFTIndex] */
UpdateUserPTE(LinAdr, UserPFTIndex)
long LinAdr;
unsigned UserPFTIndex;
{
unsigned index;
long pte;

   index = INDEX(LinAdr);

   pte = PFT(UserPFTIndex) & ~0xfff;   /* Pg Frame Adr in 20 MSBs */

   SetPteFromIndex(index, pte);
   SetPteFromIndex(index+1, pte+HEX4K);
   SetPteFromIndex(index+2, pte+HEX4K*2);
   SetPteFromIndex(index+3, pte+HEX4K*3);
}

/* exchange 4 ptes at LinAdr1 and LinAdr2 */
ExchangePTEs(LinAdr1, LinAdr2)
long LinAdr1, LinAdr2;
{
unsigned index1, index2;
long tPte;
int i;

   index1 = INDEX(LinAdr1);
   index2 = INDEX(LinAdr2);
   
   for (i = 0; i < 4; i++) {
      tPte = PT(index1+i);
      SetPteFromIndex(index1+i, PT(index2+i));
      SetPteFromIndex(index2+i, tPte);
   }
}

/* sanity check on the index, and then call GetPte */
long GetPteFromIndex(index)
unsigned index;
{
unsigned i;
long PhyAdr;

   PhyAdr = ((long) index) << 12;
   
   if (PhyAdr < HEX256K || PhyAdr >= HEX1MB)
      return (PhyAdr);
   
   i = EMM_MPindex[DOSPHYPAGE(PhyAdr)];

   if (i != -1)
      return GetPte(index);
   else  
      return PhyAdr; 
}

/* sanity check on the index and then call SetPte */
SetPteFromIndex(index, pte)
unsigned index;
long pte;
{
unsigned i;
long PhyAdr;

   PhyAdr = ((long) index) << 12;
   
   if (PhyAdr < HEX256K || PhyAdr >= HEX1MB)
      return;
   
   i = EMM_MPindex[DOSPHYPAGE(PhyAdr)];

   if (i != -1)
      return SetPte(index, pte);
   else  
      return;
}



