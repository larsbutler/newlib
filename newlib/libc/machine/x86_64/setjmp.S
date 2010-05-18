/*
 * ====================================================
 * Copyright (C) 2007 by Ellips BV. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

 /*
 **  jmp_buf:
 **   rbx r12 r13 r14 rip ebp esp
 **   0   8   16  24  32  40  44
 */

  #include "x86_64mach.h"

  .global SYM (setjmp)
  .global SYM (longjmp)
  SOTYPE_FUNCTION(setjmp)
  SOTYPE_FUNCTION(longjmp)

SYM (setjmp):
  movq    rbx, %nacl:  0 (r15,rdi)
  movq    r12, %nacl:  8 (r15,rdi)
  movq    r13, %nacl: 16 (r15,rdi)
  movq    r14, %nacl: 24 (r15,rdi)
  movq    (rsp), rax
  movq    rax, %nacl: 32 (r15,rdi)
  leaq    8 (rsp), rax
  movl    ebp, %nacl: 40 (r15,rdi)
  movl    eax, %nacl: 44 (r15,rdi)
  movq    $0, rax
  pop     r11
  nacljmp r11d, r15

SYM (longjmp):
  movl    edi, edi        /* Sandbox */
  movq    rsi, rax        /* Return value */

  naclrestbp 40 (r15,rdi), r15

  __CLI
  naclrestsp 44 (r15,rdi), r15
  pushq   32 (r15,rdi)
  movq     0 (r15,rdi), rbx
  movq     8 (r15,rdi), r12
  movq    16 (r15,rdi), r13
  movq    24 (r15,rdi), r14
  __STI

  pop     r11
  nacljmp r11d, r15
