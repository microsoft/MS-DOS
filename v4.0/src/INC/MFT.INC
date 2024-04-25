BREAK   <MFT Definitions>

;**     MSDOS MFT definitions
;
;   The Master File Table (MFT) associates the cannonicalized pathnames, lock
;   records and SFTs for all files open on this machine.
;
;   The MFT implementation employs a single memory buffer which is used from
;   both ends.  This gives the effect (at least until they run into each
;   other) of two independent buffers.
;
;       MFT buffer
;       ==========
;   The MFT buffer contains MFT name records and free space.  It uses a
;   classic heap architecture:  freed name records are marked free and
;   conglomerated with any adjacent free space.  When one is to create a name
;   entry the free list is searched first-fit.  The list of name and free
;   records is always terminated by a single END record.
;
;       LOCK buffer
;       ===========
;   The lock buffer contains fixed format records containing record locking
;   information.  Since they are fixed format the space is handled as a series
;   of chains:  one for each MFT name record and one for the free list.  No
;   garbage collection is necessary.
;
;       Space allocation
;       ================
;   The MFT is managed as a heap.  Empty blocks are allocated on a first-fit
;   basis.  If there is no single large enough empty block the list is garbage
;   collected.
;
;       MFT name records:
;
;              8     16     8     16     32     16        n
;           |------|-----|-----|------|------|------|---------~~~~~~---------|
;           | FLAG | LEN | SUM | LPTR | SPTR | SERL |     <.asciz string>    |
;           --------------------------------------------------~~~~~~----------
;
;                       FLAG = record type flag
;                       LEN =  total byte length of record.
;                       SUM =  sum of bytes in asciz string.  Used to speed
;                              searches
;                       LPTR=  pointer to first record in lock chain segment
;                              is MFT segment
;                       SPTR= pointer to first sft in sft chain
;                       SERL= serial number
;                       <string> = name string, zero-byte terminated.  There
;                              may be garbage bytes following the 00 byte;
;                              these are counted in the LEN field.
;
;
;       MFT free records
;
;              8      16
;           |------|-----|----~~~~~~~~~~~~~~~~~~~~~~~~~~~---------|
;           | FLAG | LEN |         free                           |
;           ------------------~~~~~~~~~~~~~~~~~~~~~~~~~~~----------
;
;                       FLAG = record type flag
;                       LEN  = total byte length of record.
;
;
;       MFT END records
;
;                  8
;               |------|
;               | FLAG |
;               --------
;
;                       FLAG = record type flag

;**     MFT definitions
;*
;*      NOTE:  the flag and length fields are identical for all record types
;*              (except the END type has no length) This must remain so as
;*              some code depends upon it.
;*
;*      NOTE:  Many routines check for "n-1" of the N flag values and if no
;*              match is found assume the flag value must be the remaining
;*              possibility.  If you add or remove flag values you must check
;*              all references to mft_flag.

MFT_entry       STRUC

mft_flag        DB      ?               ; flag/len field
mft_len         DW      ?
mft_sum         DB      ?               ; string sum word
mft_lptr        DW      ?               ; LCK pointer
mft_sptr        DD      ?               ; sft pointer
mft_serl        DW      ?               ; serial number
mft_name        DB      ?               ; offset to start of name

MFT_entry       ENDS

MFLG_NAM        EQU     1               ; min value for name record
MFLG_FRE        EQU     0               ; free record
MFLG_END        EQU     -1              ; end record

;*      Record Lock Record (RLR):
;
;                  16       32       32       32
;               |-------|--------|--------|--------|
;               | NEXT  |  FBA   |  LBA   |  SPTR  |
;               |       | lo hi  | lo hi  |        |
;               ------------|--------|--------------
;
;                       CHAIN  = pointer to next RLR.  0 if end
;                       FBA    = offset of 1st  byte of locked region
;                       LBA    = offset of last byte of locked region
;                       SPTR   = pointer to SFT lock was issued on

RLR_entry       STRUC

rlr_next        DW      ?               ; chain to next RLR, 0 if end
rlr_fba         DW      ?               ; first byte addr (offset) of reigion
                DW      ?
rlr_lba         DW      ?               ; last byte addr of region
                DW      ?
rlr_sptr        DD      ?               ; SFT pointer
rlr_pid         dw      ?               ; process id of issuer
rlr_type        dw      ?               ; lock type
RLR_entry       ENDS

rlr_lall        equ     00h            ; lock all ops
rlr_lwr         equ     01h            ; lock write ops

;
;   A pictorial diagram for the linkages is as follows:
;
;          +---sptr------+
;          V             |
;        +---+<----------|---sptr------+------------+
;        |SFT+----+      |             |            |
;        +-+-+    |    +-+-+        +--+-+       +--+-+
;          V      +--->|MFT+-lptr->-|LOCK+-next->|LOCK+->0
;        +---+    |    +---+        +----+       +----+
;        |SFT+----+      ^
;        +-+-+           |
;          |             |
;          +-------------+
;
;

;**
;
;   Interesting behavior should be noted:
;
;       The sharer must maintain information on files in three forms:
;
;       local/remote handles.  These are normal handles and behave in no
;           strange manner.  They are identified by SF_mode not having the
;           sfIsFCB flag nor by having the sf_mode = 70.  No problems with
;           locking.  No problems with open.  No problems with close.
;           CloseByName will iterate closes until the mft disappears.
;           CloseUser will iterate closes until no SFT for the particular user
;           appears.  CloseProcess will iterate closes until no SFT for the
;           particular user/process appears.
;
;       local FCBs.  There are no corresponding SFT's for these as the SFTs
;           are cached but will be valid for the particular file.  There is
;           one SFT for each open on a file by a specific process.  These are
;           identified the sfIsFCB flag in the sf_mode field.  When multiple
;           opens occur, we merely find the sf pertinent to the file and
;           process.  Close decrements the ref count.  CloseByName, CloseUser,
;           CloseProcess will iterate closes until no more SFTs exist.
;
;       handles with mode 70.  These represent FCB's open across the network.
;           As such, identical sfts may have been collapsed by the $open code.
;           This results in a reuse of the same SFT.  The $Open code must
;           correctly set the ref-count for the sft to reflect the number of
;           collapses that have occurred.  These are identified by a 70 in the
;           SF_mode field.  There can be no locking on these SFTs.  Open must
;           scan the list of SFTs for the file and increment its ref count
;           appropriately.
