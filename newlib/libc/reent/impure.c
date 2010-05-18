#include <reent.h>

/* Note that there is a copy of this in sys/reent.h.  */
#ifndef __ATTRIBUTE_IMPURE_PTR__
#define __ATTRIBUTE_IMPURE_PTR__
#endif

#ifndef __ATTRIBUTE_IMPURE_DATA__
#define __ATTRIBUTE_IMPURE_DATA__
#endif

/* Redeclare these symbols locally as weak so that the file containing
   their definitions (along with a lot of other stuff) isn't sucked in
   unless they are actually used by other compilation units.  This is
   important to reduce image size for targets with very small amounts
   of memory.  */
#ifdef _REENT_SMALL
extern const struct __sFILE_fake __sf_fake_stdin _ATTRIBUTE ((weak));
extern const struct __sFILE_fake __sf_fake_stdout _ATTRIBUTE ((weak));
extern const struct __sFILE_fake __sf_fake_stderr _ATTRIBUTE ((weak));
#endif

static struct _reent __ATTRIBUTE_IMPURE_DATA__ global_impure_data = _REENT_INIT (global_impure_data);
static __thread struct _reent __ATTRIBUTE_IMPURE_DATA__ impure_data = _REENT_INIT (global_impure_data);
#ifdef __CYGWIN__
extern struct _reent reent_data __attribute__ ((alias("impure_data")));
#endif
__thread struct _reent *__ATTRIBUTE_IMPURE_PTR__ _impure_ptr = -1; //NULL; - try to avoid tbss until its alignment is fixed
struct _reent *_CONST __ATTRIBUTE_IMPURE_PTR__ _global_impure_ptr = &global_impure_data;

/*
 * This function should be called on thread startup (for each thread).
 */
void __newlib_thread_init()
{
  /*
   * Fix the initialization - REENT_INIT pointed
   * the pointers to the global structure.
   */
  impure_data._stdin = &impure_data.__sf[0];
  impure_data._stdout = &impure_data.__sf[1];
  impure_data._stderr = &impure_data.__sf[2];
  impure_data.__sdidinit = _GLOBAL_REENT->__sdidinit;
  impure_data.__cleanup = _GLOBAL_REENT->__cleanup;
  impure_data.__sglue._niobs = 3;
  impure_data.__sglue._iobs = &_GLOBAL_REENT->__sf[0];

  /* Set the pointer to point to the thread-specific structure. */
  _impure_ptr = &impure_data;
}

void __newlib_thread_exit()
{
  _cleanup_r (_REENT);
}
