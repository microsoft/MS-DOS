;;STRUC--Stucture Macro Library
;;Optimizing Version 2.30  03/31/87

if1
$NoConj 	equ	0
$And		equ	1
$Or		equ	2
$Short		equ	3
$Near		equ	4
$NearToShort	equ	5
$ncxz		equ	6
$AndOr		=	0
$Temp		=	0
$Temp2		=	0
$Dist		=	0

$NoType 	equ	10
$ConjIfType	equ	11
$IfType 	equ	12
$ElseType	equ	13
$WhileType	equ	14
$ConjWhileType	equ	15
$RepeatType	equ	16
$ConjUntilType	equ	17
$ForType	equ	18
$ConjLeaveType	equ	19
$SelectType	equ	20
$WhenType	equ	21
$ConjWhenType	equ	22
$OtherwiseType	equ	$ElseType

$StrucError macro text
					Structure error -- text
endm

J	macro
endm
JN	macro
endm

$BuildJump   macro   j1,j2
	j1  macro   t
	    .xcref  j1
					j2 t
	endm
endm

irp	x,<<jeq,je>,<jlt,jl>,<jgt,jg>,<jneq,jne>,<jnlt,jnl>,<jngt,jng>,<jnpe,jpo>,<jnpo,jpe>>
	$BuildJump x
endm
irp	x,<<jzero,jz>,<jnzero,jnz>,<jnonzero,jnz>,<jnnonzero,jz>,<jand,jnz>,<jnand,jz>,<jnnand,jnz>>
	$BuildJump x
endm
irp	x,<a,ae,b,be,c,e,g,ge,l,le,o,p,s,z,cxz>
	$BuildJump jnn&x,j&x
endm

jncxz	macro	t
	if	$Dist eq $NearToShort
					jcxz $+5
					jmp t
	else
					jcxz $+4
					jmp short t
	endif
endm

purge	$BuildJump

$GetConj macro	p1,p2
	$AndOr	= $NoConj
	irp	parm,<p1,p2>
	    ifnb    <&parm>
		irp	x,<and,AND,or,OR>
		    ifidn   <parm>,<x>
			 $AndOr = $&&&x
			 exitm
		    endif
		endm
	    endif
	endm
endm

$GetDist macro	p1,p2
	irp	parm,<p1,p2>
	    ifnb    <parm>
		irp	x,<short,SHORT,near,NEAR>
		    ifidn   <parm>,<x>
			$Dist	= $&&&x
			 exitm
		     endif
		endm
	    endif
	endm
endm


$Poke	macro	n,m
	$st&n	= m
.xcref	$st&n
endm

$Peek	macro	x,n
	x	= $st&n
endm

$Push	macro	n
	$st	= $st+1
	$Poke	%$st,n
endm

$Pop	macro	x
	if	$st gt 0
	    $Peek   x,%$st
	    $st     = $st-1
	else
	    $StrucError <open structure>
	endif
endm

$EquateLabel macro last,this
	if	$LastLabelOrg eq $
	    $ll&last = this
	    .xcref  $ll&last
	endif
endm

$TraceLabel macro n,a,b
	if	$ll&a eq $ll&b
	    $ll&n   = b
	    .xcref  $ll&n
	else
	    $TraceLabel n,%$ll&a,%$ll&b
	endif
endm

$Label	 macro	 n
	if1
	    $EquateLabel %$LastLabel,n
	    $ll&n   = n
	    .xcref  $ll&n
	    $LastLabel = n
	    $LastLabelOrg = $
$l&n:
	else
	    if	    $ll&n eq n
$l&n:
	    else
		.xcref	$l&n
		.xcref	$ll&n
	    endif
	endif
endm

$CondJump macro l,tf,c
	if1
	    ifb     <c>
		$EquateLabel %$LastLabel,l
	    endif
	    ifndef  <$ll&l>
		$ll&l	= l
		.xcref	$ll&l
	    endif
	else
	    $TraceLabel l,l,%$ll&l
	endif
	$CondJump2 %$ll&l,tf,c
endm

$CondJump2 macro l,tf,c
	if	$Dist eq $Short
	    ifb     <c>
					jmp short $l&l
	    else
		ifidn <tf>,<f>
					jn&c $l&l
		else
					j&c $l&l
		endif
	    endif
	else
	    ifnb    <c>
		ifdef	$l&l
		    if	    (($ - $l&l) le 126) and (($l&l - $) le 129)
			$Dist	= $NearToShort
			$nops	= 3
			ifidn <tf>,<f>
					jn&c $l&l
			    ifdef   $n&c
				if	$n&c eq $ncxz
				    $nops = 0
				endif
			    endif
			    ifdef   $&c
				if	$&c eq $ncxz
				    $nops = 5
				endif
			    endif
			else
					j&c $l&l
			    ifdef   $n&c
				if	$n&c eq $ncxz
				    $nops = 5
				endif
			    endif
			    ifdef   $&c
				if	$&c eq $ncxz
				    $nops = 0
				endif
			    endif
			endif
			    rept $nops
				nop
			    endm
		    else
			ifidn <tf>,<f>
					j&c $+5
			else
					jn&c $+5
			endif
					jmp $l&l
		    endif
		else
		    ifidn <tf>,<f>
					j&c $+5
		    else
					jn&c $+5
		    endif
					jmp $l&l
		endif
	    else
		ifdef	$l&l
		    ifidn   <tf>,<NoFold>
					jmp $l&l
		    else
			if	(($ - $l&l) le 126) and (($l&l - $) le 129)
					jmp short $l&l
					nop
			else
					jmp $l&l
			endif
		    endif
		else
					jmp $l&l
		endif
	    endif
	endif
endm


$CondLoop macro l,c
					loop&c $l&l
endm

$Test	macro	tgt,a1,a2,a3,a4,x
	ifb	<a1>
	    $StrucError <invalid condition>
	else
	ifb	<a2>
	    $CondJump %&tgt,a1
	else
	ifb	<a3>
	    ifdif   <a1>,<zero>
	    ifdif   <a1>,<nonzero>
	    ifdif   <a1>,<ZERO>
	    ifdif   <a1>,<NONZERO>
		$StrucError <invalid condition>
		exitm
	    endif
	    endif
	    endif
	    endif
					or a2,a2
	    $CondJump %&tgt,a1
	else
	ifb	<a4>
					cmp a1,a3
	    $CondJump %&tgt,a2
	else
	ifb	<x>
	    ifdif   <a1>,<bit>
	    ifdif   <a1>,<BIT>
		$StrucError <invalid condition>
		exitm
	    endif
	    endif
					test a2,a4
	    $CondJump %&tgt,a3
	else
	    $StrucError <invalid condition>
	endif
	endif
	endif
	endif
	endif
endm

$TopTest macro	args,n,c,p4,p5
	$GetConj p4,p5
	$Dist	= $DefDist
	$GetDist p4,p5
	if	$AndOr eq $NoConj
	    $Test   <$sn-1,f>,args
	    $Pop    $Temp
	    if	    $OrFound
		$Label	%$Temp
	    endif
	    $Push   n
	else
	    if	    $AndOr eq $And
		$Test	<$sn-1,f>,args
	    else
		$OrFound = 1
		$Test	<$sn,t>,args
	    endif
	    $Push   c
	endif
endm
;;*****************************************************************************
.if	macro	t,p2,p3
	$Peek	$Temp,%$st
	if	$Temp eq $ConjIfType
	    $Pop    $Temp
	else
	    $OrFound = 0
	    $sn     = $sn+1
	    $Push   $sn
	    $sn     = $sn+1
	    $Push   $sn
	    $sn     = $sn+1
	    $Push   $sn
	endif
	$TopTest <t>,$IfType,$ConjIfType,p2,p3
endm
;;*****************************************************************************
.then	macro
	$Peek	$Temp,%$st
	if	$Temp ne $IfType
	if	$Temp ne $WhenType
	    $StrucError <then without if or when>
	endif
	endif
endm
;;*****************************************************************************
.elseif macro	t,p2,p3
	$Pop	$Temp
	if	$Temp ne $IfType
	    $StrucError <elseif without if>
	    exitm
	endif
	$OrFound = 0
	$Pop	$Temp
	$Peek	$Temp2,%$st
	$Dist	= $Near
	$CondJump %$Temp2
	$Label	%$Temp
	$sn	= $sn+1
	$Push	$sn
	$sn	= $sn+1
	$Push	$sn
	$TopTest <t>,$IfType,$ConjIfType,p2,p3
endm
;;*****************************************************************************
.else	macro	dist
	$Pop	$Temp
	if	$Temp ne $IfType
	if	$Temp ne $WhenType
	if	$Temp ne $SelectType
	    $StrucError <else without if, when or select>
	    exitm
	endif
	endif
	endif
	$sn	= $sn+1
	if	$Temp eq $SelectType
	    $Push   $sn
	else
	    $Dist   = $DefDist
	    $GetDist dist
	    $CondJump %$sn
	    $Pop    $Temp
	    $Label  %$Temp
	    $Push   $sn
	endif
	$push	$ElseType
endm
;;*****************************************************************************
.endif	macro
	$Pop	$Temp
	if	$Temp ne $IfType
	    if	    $Temp ne $ElseType
		$StrucError <endif without if>
		exitm
	    endif
	endif
	$Pop	$Temp
	$Label	%$Temp
	$Pop	$Temp
	$Label	%$Temp
endm
;;*****************************************************************************
.select macro	x
	$OrFound = 0
	$sn	= $sn+1
	$Push	$sn
	$Push	$SelectType
endm
;;*****************************************************************************
.when	macro	tst,p2,p3
	$Pop	$Temp
	if	$Temp ne $SelectType
	if	$Temp ne $WhenType
	if	$Temp ne $ConjWhenType
	    $StrucError <when without select>
	    exitm
	endif
	endif
	endif
	if	$Temp ne $ConjWhenType
	    $Dist   = $Near
	    $OrFound = 0
	    if	    $Temp eq $WhenType
		$Pop	$Temp2
		$Peek	$Temp,%$st
		$CondJump %$Temp
		$Label	 %$Temp2
	    endif
	    $sn     = $sn+1
	    $Push   $sn
	    $sn     = $sn+1
	    $Push   $sn
	endif
	$TopTest <tst>,$WhenType,$ConjWhenType,p2,p3
endm
;;*****************************************************************************
.otherwise	macro	dist
	$Pop	$Temp
	if	$Temp ne $WhenType
	if	$Temp ne $SelectType
	if	$Temp ne $IfType
	    $StrucError <otherwise without if, when or select>
	    exitm
	endif
	endif
	endif
	$sn	= $sn+1
	if	$Temp eq $SelectType
	    $Push   $sn
	else
	    $Dist   = $DefDist
	    $GetDist dist
	    $CondJump %$sn
	    $Pop    $Temp
	    $Label  %$Temp
	    $Push   $sn
	endif
	$push	$OtherwiseType
endm
;;*****************************************************************************
.endselect	macro
	$Pop	$Temp
	if	$Temp ne $WhenType
	if	$Temp ne $OtherwiseType
	if	$Temp ne $SelectType
	    $StrucError <endselect without select>
	    exitm
	endif
	endif
	endif
	$pop	$Temp2
	if	$Temp ne $SelectType
	    $Label  %$Temp2
	    $Pop    $Temp2
	    $Label  %$Temp2
	endif
endm
;;*****************************************************************************
.while	macro	t,p2,p3
	$Peek	$Temp,%$st
	if	$Temp eq $ConjWhileType
	    $Pop    $Temp
	else
	    $Push   $LoopEnd
	    $OrFound = 0
	    $sn     = $sn + 1
	    $Push   $sn
	    $Label  %$sn
	    $sn     = $sn + 2
	    $Push   $sn
	    $LoopEnd = $sn - 1
	endif
	$TopTest <t>,$WhileType,$ConjWhileType,p2,p3
endm
;;*****************************************************************************
.endwhile macro p1
	$Pop	$Temp
	if	$Temp ne $WhileType
	    $StrucError <endwhile without while>
	    exitm
	endif
	$Dist	= $Near
	$Pop	$Temp
	$CondJump %$Temp,NoFold
	$Label	%$Temp+1
	$Pop	$LoopEnd
endm
;;*****************************************************************************
.repeat macro
	$Push	$LoopEnd
	$Push	$LeaveFound
	$sn	= $sn+1
	$Label	%$sn
	$Push	$sn
	$Push	$RepeatType
	$sn	= $sn+1
	$LoopEnd = $sn
	$LeaveFound = 0
endm
;;*****************************************************************************
.until	macro	t,p2,p3
	$until2 p2,p3,t
endm
$until2 macro	p2,p3,a1,a2,a3,a4,x
	$Pop	$Temp
	if	$Temp ne $RepeatType
	    if	    $Temp ne $ConjUntilType
		$StrucError <until without repeat>
		exitm
	    endif
	else
	    $OrFound = 0
	endif
	$Dist	= $DefDist
	$GetDist p2,p3
	$GetConj p2,p3

	if	$AndOr eq $NoConj
	    $Pop    $Temp
	    ifb     <a1>
		$Dist	= $Near
		$CondJump %$Temp,NoFold
	    else
		$Test	 <$Temp,f>,<a1>,<a2>,<a3>,<a4>,<x>
	    endif
	    if	    $OrFound or $LeaveFound
		$Label	 %$Temp+1
	    endif
	    $Pop    $LeaveFound
	    $Pop    $LoopEnd
	else
	    $Peek   $Temp,%$st
	    if	    $AndOr eq $And
		$Test	 <$Temp,f>,<a1>,<a2>,<a3>,<a4>,<x>
	    else
		$OrFound = 1
		$Test	 <$Temp+1,t>,<a1>,<a2>,<a3>,<a4>,<x>
	    endif
	    $Push   $ConjUntilType
	endif
endm
;;*****************************************************************************
.loop	macro	cond
	$Pop	$Temp
	if	$Temp ne $RepeatType
	    $StrucError <loop without repeat>
	    exitm
	endif
	$Pop	$Temp
	$CondLoop %$Temp,cond
	if	$LeaveFound
	    $Label  %$Temp+1
	endif
	$Pop	$LeaveFound
	$Pop	$LoopEnd
endm
;;*****************************************************************************
.for	macro	index,equals,start,to,stop,by,step,dist
					mov index,start
	$Push	$LoopEnd
	$sn	= $sn+1
	$Push	$sn
	$Label	%$sn
	$sn	= $sn+1
	$LoopEnd = $sn
					cmp index,stop
	$Dist	= $DefDist
	ifb	<step>
	    $Push   1
	    $GetDist by
	    $CondJump %$sn,t,gt
	else
	    $GetDist dist
	    $Push   %(step)
	    if	    step lt 0
		$CondJump %$sn,t,lt
	    else
		$CondJump %$sn,t,gt
	    endif
	endif
	$Push	$ForType
endm
;;*****************************************************************************
.next	macro	index,dist
	$Pop	$Temp
	if	$Temp ne $ForType
	    $StrucError <next without for>
	    exitm
	endif
	$Pop	$Temp
	if	$Temp eq 1
					inc index
	else
	    if	    $Temp eq -1
					dec index
	    else
					add index,$Temp
	    endif
	endif
	$Pop	$Temp
	$Dist	= $Near
	$CondJump %$Temp,NoFold
	$Label	%$Temp+1
	$Pop	$LoopEnd
endm
;;*****************************************************************************
.leave	macro	t,p2,p3
	$leave2 p2,p3,t
endm
$leave2 macro  p2,p3,a1,a2,a3,a4,x
	ife	$LoopEnd
	    $StrucError <leave outside a loop>
	    exitm
	endif
	$LeaveFound = 1
	$Peek	$Temp,%$st
	if	$Temp eq $ConjLeaveType
	    $Pop    $Temp
	else
	    $OrFound = 0
	    $sn     = $sn + 1
	endif
	$Dist	= 0
	$GetDist <a1>
	if	$Dist
	    $CondJump %$LoopEnd
	    if	    $OrFound
		$Label	%$sn
	    endif
	else
	    $Dist   = $DefDist
	    $GetDist p2,p3
	    $GetConj p2,p3
	    if	    $AndOr eq $NoConj
		ifb	<a1>
		    $CondJump %$LoopEnd,t
		else
		    $Test   <$LoopEnd,t>,<a1>,<a2>,<a3>,<a4>,<x>
		endif
		if	$OrFound
		    $Label  %$sn
		endif
	    else
		if	$AndOr eq $And
		    $OrFound = 1
		    $Test   <$sn,f>,<a1>,<a2>,<a3>,<a4>,<x>
		else
		    $Test   <$LoopEnd,t>,<a1>,<a2>,<a3>,<a4>,<x>
		endif
		$Push	$ConjLeaveType
	    endif
	endif
endm
;;*****************************************************************************
else	       ;else for if1
$Pop	$Temp
;;if	   $Temp ne $NoType
if	$st ne 0
     $StrucError <open structure(s)>
endif
.xcref $NoConj,$And,$Or,$Short,$Near,$NearToShort,$AndOr,$Temp,$Temp2,$Dist
.xcref $NoType,$ConjIfType,$IfType,$ElseType,$WhileType,$ConjWhileType
.xcref $RepeatType,$ConjUntilType,$ForType,$ConjLeaveType,jncxz
.xcref $SelectType,$WhenType,$OtherwiseType,$ConjWhenType
.xcref jeq,jgt,jlt,jneq,jngt,jnlt,jnna,jnnae,jnnb,jnnbe,jnnc,jnncxz
.xcref jnne,jnng,jnnge,jnnl,jnnle,jnno,jnnp,jnns,jnnz,jnpe,jnpo,$BuildJump
.xcref $GetConj,$GetDist,$Poke,$Peek,$Push,$Pop,$Label,$CondJump,$CondLoop,$Test
.xcref $TopTest,$leave2,$until2,$StrucError,j,jn,jand,jnand,jnnand
.xcref jnnonzero,jnonzero,jnzero,jzero
.xcref $st,$sn,$OrFound,$LoopEnd,$LeaveFound,$DefDist
.xcref $LastLabel,$LastLabelOrg,$EquateLabel,$TraceLabel,$CondJump2,$ncxz
endif


$st	= 0
$sn	= 0
$OrFound = 0
$LoopEnd = 0
$LeaveFound = 0
$LastLabel = -1
$LastLabelOrg = $
$DefDist= $Short
$Push	%$NoType
