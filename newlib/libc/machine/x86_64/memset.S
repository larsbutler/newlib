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

  .global SYM (memset)
  SOTYPE_FUNCTION(memset)

SYM (memset):
  movl    esi, esi                /* Only need to do read sandboxing once */
  addq    r15 ,rsi
  movl    edi, r9d                /* Save return value */
  movl    esi, eax
  movl    edx, ecx
  cmpl    $16, edx
  jb      byte_set

  movl    edi, r8d                /* Align on quad word boundary */
  andl    $7, r8d
  jz      quadword_aligned
  movl    $8, ecx
  subl    r8d, ecx
  subl    ecx, edx
  rep     stosb al, %nacl:(rdi), r15
  movl    edx, ecx

quadword_aligned:
  movabs  $0x0101010101010101, r8
  movzbl  sil, eax
  imul    r8, rax
  cmpl    $256, edx
  jb      quadword_set

  shrl    $7, ecx                 /* Store 128 bytes at a time with minimum cache polution */

  .p2align 4
loop:
  movntiq rax, %nacl:     (r15,rdi)
  movntiq rax, %nacl:   8 (r15,rdi)
  movntiq rax, %nacl:  16 (r15,rdi)
  movntiq rax, %nacl:  24 (r15,rdi)
  movntiq rax, %nacl:  32 (r15,rdi)
  movntiq rax, %nacl:  40 (r15,rdi)
  movntiq rax, %nacl:  48 (r15,rdi)
  movntiq rax, %nacl:  56 (r15,rdi)
  movntiq rax, %nacl:  64 (r15,rdi)
  movntiq rax, %nacl:  72 (r15,rdi)
  movntiq rax, %nacl:  80 (r15,rdi)
  movntiq rax, %nacl:  88 (r15,rdi)
  movntiq rax, %nacl:  96 (r15,rdi)
  movntiq rax, %nacl: 104 (r15,rdi)
  movntiq rax, %nacl: 112 (r15,rdi)
  movntiq rax, %nacl: 120 (r15,rdi)

  leal    128 (rdi), edi

  dec     ecx
  jnz     loop

  sfence
  movl    edx, ecx
  andl    $127, ecx
  rep     stosb al, %nacl:(rdi), r15
  movl    r9d, eax
  pop     r11
  nacljmp r11d, r15


byte_set:
  rep     stosb al, %nacl:(rdi), r15
  movl    r9d, eax
  pop     r11
  nacljmp r11d, r15


quadword_set:
  shrl    $3, ecx
  .p2align 4
  rep     stosq rax, %nacl:(rdi), r15
  movl    edx, ecx
  andl    $7, ecx
  rep     stosb al, %nacl:(rdi), r15 /* Store the remaining bytes */
  movl    r9d, eax
  pop     r11
  nacljmp r11d, r15

