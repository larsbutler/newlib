/*
 * ====================================================
 * Copyright (C) 2007 by Ellips BV. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

  #include "x86_64mach.h"

  .global SYM (memcpy)
  SOTYPE_FUNCTION(memcpy)

SYM (memcpy):
  movl    edi, eax                /* Store destination in return value */
  movl    esi, esi                /* Only need to do read sandboxing once */
  addq    r15, rsi
  cmpl    $16, edx
  jb      byte_copy

  movl    edi, r8d                /* Align destination on quad word boundary */
  andl    $7, r8d
  jz      quadword_aligned
  movl    $8, ecx
  subl    r8d, ecx
  subl    ecx, edx
  
  rep     movsb (rsi), %nacl:(rdi), r15

quadword_aligned:
  cmpl    $256, edx
  jb      quadword_copy

  pushq    rax
  pushq    r12
  pushq    r13
  pushq    r14

  movl    edx, ecx                /* Copy 128 bytes at a time with minimum cache polution */
  shrl    $7, ecx

  .p2align 4
loop:
  prefetchnta   768 (rsi)
  prefetchnta   832 (rsi)

  movq       (rsi), rax
  movq     8 (rsi), r8
  movq    16 (rsi), r9
  movq    24 (rsi), r10
  movq    32 (rsi), r11
  movq    40 (rsi), r12
  movq    48 (rsi), r13
  movq    56 (rsi), r14

  movntiq rax, %nacl:     (r15,rdi)
  movntiq r8 , %nacl:   8 (r15,rdi)
  movntiq r9 , %nacl:  16 (r15,rdi)
  movntiq r10, %nacl:  24 (r15,rdi)
  movntiq r11, %nacl:  32 (r15,rdi)
  movntiq r12, %nacl:  40 (r15,rdi)
  movntiq r13, %nacl:  48 (r15,rdi)
  movntiq r14, %nacl:  56 (r15,rdi)

  movq     64 (rsi), rax
  movq     72 (rsi), r8
  movq     80 (rsi), r9
  movq     88 (rsi), r10
  movq     96 (rsi), r11
  movq    104 (rsi), r12
  movq    112 (rsi), r13
  movq    120 (rsi), r14

  movntiq rax, %nacl:  64 (r15,rdi)
  movntiq r8 , %nacl:  72 (r15,rdi)
  movntiq r9 , %nacl:  80 (r15,rdi)
  movntiq r10, %nacl:  88 (r15,rdi)
  movntiq r11, %nacl:  96 (r15,rdi)
  movntiq r12, %nacl: 104 (r15,rdi)
  movntiq r13, %nacl: 112 (r15,rdi)
  movntiq r14, %nacl: 120 (r15,rdi)

  leaq    128 (rsi), rsi
  leal    128 (rdi), edi

  dec     ecx
  jnz     loop

  sfence
  movl    edx, ecx
  andl    $127, ecx
  rep     movsb (rsi), %nacl:(rdi), r15
  popq    r14
  popq    r13
  popq    r12
  popq    rax
  pop     r11
  nacljmp r11d, r15


byte_copy:
  movl    edx, ecx
  rep     movsb (rsi), %nacl:(rdi), r15
  pop     r11
  nacljmp r11d, r15


quadword_copy:
  movl    edx, ecx
  shrl    $3, ecx
  .p2align 4
  rep     movsq (rsi), %nacl:(rdi), r15
  movl    edx, ecx
  andl    $7, ecx
  rep     movsb (rsi), %nacl:(rdi), r15 /* Copy the remaining bytes */
  pop     r11
  nacljmp r11d, r15
