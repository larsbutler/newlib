/* wf_sqrt.c -- float version of w_sqrt.c.
 * Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
 */

/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice 
 * is preserved.
 * ====================================================
 */

/* 
 * wrapper sqrtf(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float sqrtf(float x)		/* wrapper sqrtf */
#else
	float sqrtf(x)			/* wrapper sqrtf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
#ifdef __llvm__
	/*
	 * Use the LLVM intrinsic to compute sqrt wherever possible.
	 * It is only defined for -0.0 and greater.
	 * For portable native client this allows the generation of portable
	 * bitcode that still uses hardware sqrt on platforms that support it.
	 */
	if (x>=(float)-0.0) {
	  float llvm_sqrtf(float) asm("llvm.sqrt.f32");
	  return llvm_sqrtf(x);
	}
#endif
	return __ieee754_sqrtf(x);
#else
	float z;
	struct exception exc;
#ifdef __llvm__
	/*
	 * Use the LLVM intrinsic to compute sqrt wherever possible.
	 * It is only defined for -0.0 and greater.
	 * For portable native client this allows the generation of portable
	 * bitcode that still uses hardware sqrt on platforms that support it.
	 */
	if (x>=(float)-0.0) {
	  float llvm_sqrtf(float) asm("llvm.sqrt.f32");
	  z = llvm_sqrtf(x);
	} else {
	  z = __ieee754_sqrtf(x);
        }
#else  /* __llvm__ */
	z = __ieee754_sqrtf(x);
#endif  /* __llvm__ */
	if(_LIB_VERSION == _IEEE_ || isnan(x)) return z;
	if(x<(float)0.0) {
            /* sqrtf(negative) */
            exc.type = DOMAIN;
            exc.name = "sqrtf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
            if (_LIB_VERSION == _SVID_)
              exc.retval = 0.0;
            else
              exc.retval = 0.0/0.0;
            if (_LIB_VERSION == _POSIX_) 
              errno = EDOM;
            else if (!matherr(&exc)) {
              errno = EDOM;
            }
            if (exc.err != 0)
	      errno = exc.err;
	    return (float)exc.retval; 
	} else
	    return z;
#endif
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double sqrt(double x)
#else
	double sqrt(x)
	double x;
#endif
{
	return (double) sqrtf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
