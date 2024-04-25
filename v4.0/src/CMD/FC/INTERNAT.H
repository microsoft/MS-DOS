/*
	Data structure for international table
 */

struct InterTbl
{
	unsigned dateform ;	/* Date format				   */
	char	currsym[5] ;	/* Currency symbol as ASCIZ string	   */
	char	thousp[2] ;	/* Thousands separator as ASCIZ string	   */
	char	decsp[2] ;	/* Decimal   separator as ASCIZ string	   */
	char	datesp[2] ;	/* Date      separator as ASCIZ string	   */
	char	timesp[2] ;	/* Time      separator as ASCIZ string	   */
	unsigned char bits ;	/* Bit field				   */
	unsigned char numdig ;	/* Number of signifigant decimal digits    */
	unsigned char timeform ;/* Time format				   */
	unsigned long casecall ;/* Case mapping call			   */
	char	datasp[2] ;	/* Data list separator as ASCIZ string	   */
	int	reserv[5] ;	/* RESERVED				   */
} ;


#define DATEFORM_USA	0
#define DATEFORM_EUROPE 1
#define DATEFORM_JAPAN	2

#define BITS_CURRENCY	0x0001
#define BITS_NUMSPC	0x0002

#define TIMEFORM_12	0
#define TIMEFORM_24	1
