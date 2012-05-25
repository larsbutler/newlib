/* Copyright (c) 2010-2011, Linaro Limited
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

      * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

      * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

      * Neither the name of Linaro Limited nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   Written by Dave Gilbert <david.gilbert@linaro.org>

   This memchr routine is optimised on a Cortex-A9 and should work on
   all ARMv7 processors.   It has a fast path for short sizes, and has
   an optimised path for large data sets; the worst case is finding the
   match early in a large data set. */

@ 2011-02-07 david.gilbert@linaro.org
@    Extracted from local git a5b438d861
@ 2011-07-14 david.gilbert@linaro.org
@    Import endianness fix from local git ea786f1b
@ 2011-10-11 david.gilbert@linaro.org
@    Import from cortex-strings bzr rev 63
@    Flip to ldrd (as suggested by Greta Yorsh)
@    Make conditional on CPU type
@    tidy

	.syntax unified
	.arch armv7-a

#include "arm_asm.h"

@ NOTE: This ifdef MUST match the one in memchr-stub.c
#if defined(_ISA_ARM_7) || defined(__ARM_ARCH_6T2__)

@ this lets us check a flag in a 00/ff byte easily in either endianness
#ifdef __ARMEB__
#define CHARTSTMASK(c) 1<<(31-(c*8))
#else
#define CHARTSTMASK(c) 1<<(c*8)
#endif
	.text

#ifndef __native_client__
	.thumb
	.thumb_func
#endif

	.p2align 4,,15
	.global memchr
	.type memchr,%function
memchr:
	@ r0 = start of memory to scan
	@ r1 = character to look for
	@ r2 = length
	@ returns r0 = pointer to character or NULL if not found
	and	r1,r1,#0xff	@ Don't trust the caller to pass a char

	cmp	r2,#16		@ If short don't bother with anything clever
	blt	20f

	tst	r0, #7		@ If it's already aligned skip the next bit
	beq	10f

	@ Work up to an aligned point
5:
	SFI_BREG(r0) \
	ldrb	r3, [r0],#1
	subs	r2, r2, #1
	cmp	r3, r1
	beq	50f		@ If it matches exit found
#ifdef __native_client__
	cmp	r2, #0
	beq	40f		@ If we run off the end, exit not found
	tst	r0, #7
	bne	5b		@ If not aligned yet then do next byte
#else
	tst	r0, #7
	cbz	r2, 40f		@ If we run off the end, exit not found
	bne	5b		@ If not aligned yet then do next byte
#endif

10:
	@ We are aligned, we know we have at least 8 bytes to work with
	push	{r4,r5,r6,r7}
	all1	.req	r5
	rp0	.req	r6
	rp1	.req	r7
	orr	r1, r1, r1, lsl #8	@ expand the match word across all bytes
	orr	r1, r1, r1, lsl #16
	bic	r4, r2, #7	@ Number of double words to work with * 8
	mvns	all1, #0		@ all F's
	movs	r3, #0

15:
	SFI_BREG(r0) \
	ldrd    rp0,rp1,[r0],#8
#ifndef __native_client__
	subs	r4, r4, #8
#endif
	eor	rp0,rp0, r1	@ rp0,rp1 have 00's where bytes match the target
	eor	rp1,rp1, r1
	uadd8	rp0, rp0, all1	@ Par add 0xff - sets GE bits for bytes!=0
	sel	rp0, r3, all1	@ bytes are 00 for none-00 bytes,
				@ or ff for 00 bytes - NOTE INVERSION
	uadd8	rp1, rp1, all1	@ Par add 0xff - sets GE bits for bytes!=0
	sel	rp1, rp0, all1	@ chained....bytes are 00 for none-00 bytes
				@ or ff for 00 bytes - NOTE INVERSION
#ifdef __native_client__
	cmp	rp1, #0
	bne	60f
	subs	r4, r4, #8
	bne	15b
#else
	cbnz	rp1, 60f
	bne	15b		@ (Flags from the subs above)
#endif

	pop	{r4,r5,r6,r7}
	and	r1,r1,#0xff	@ r1 back to a single character
	and	r2,r2,#7	@ Leave the count remaining as the number
				@ after the double words have been done

20:
#ifdef __native_client__
	cmp	r2, #0
	beq	40f		@ 0 length or hit the end already then not found
#else
	cbz	r2, 40f		@ 0 length or hit the end already then not found
#endif

21:  @ Post aligned section, or just a short call
	SFI_BREG(r0) \
	ldrb	r3,[r0],#1
#ifdef __native_client__
	eors	r3,r3,r1	@ r3 = 0 if match
	beq	50f
	subs	r2,r2,#1
	bne	21b
#else
	subs	r2,r2,#1
	eor	r3,r3,r1	@ r3 = 0 if match - doesn't break flags from sub
	cbz	r3, 50f
	bne	21b		@ on r2 flags
#endif

40:
	movs	r0,#0		@ not found
	RETURN

50:
	subs	r0,r0,#1	@ found
	RETURN

60:  @ We're here because the fast path found a hit
     @ now we have to track down exactly which word it was
     @ r0 points to the start of the double word after the one tested
     @ rp0 has the 00/ff pattern for the first word, rp1 has the chained value
	cmp	rp0, #0
	itte	eq
	moveq	rp0, rp1	@ the end is in the 2nd word
	subeq	r0,r0,#3	@ Points to 2nd byte of 2nd word
	subne	r0,r0,#7	@ or 2nd byte of 1st word

	@ r0 currently points to the 2nd byte of the word containing the hit
	tst	rp0, # CHARTSTMASK(0)	@ 1st character
	bne	61f
	adds	r0,r0,#1
	tst	rp0, # CHARTSTMASK(1)	@ 2nd character
	ittt	eq
	addeq	r0,r0,#1
	tsteq	rp0, # (3<<15)		@ 2nd & 3rd character
	@ If not the 3rd must be the last one
	addeq	r0,r0,#1

61:
	pop	{r4,r5,r6,r7}
	subs	r0,r0,#1
	RETURN

#endif
