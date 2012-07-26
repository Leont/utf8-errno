#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef CopHINTHASH_get
#define CopHINTHASH_get(c) ((c)->cop_hints_hash)
#endif

#ifndef cophh_fetch_pvs
#define cophh_fetch_pvs(cophh, key, flags) Perl_refcounted_he_fetch(aTHX_ cophh, NULL, STR_WITH_LEN(key), 0, flags)
#endif


static int errno_utf8(pTHX) {
	SV* val = cophh_fetch_pvs(CopHINTHASH_get(PL_curcop), "errno_utf8", 0);
	if (val != &PL_sv_placeholder)
		return SvIV(val);
	return 0;
}

#define SvRTRIM(sv) STMT_START { \
    if (SvPOK(sv)) { \
        STRLEN len = SvCUR(sv); \
        char * const p = SvPVX(sv); \
	while (len > 0 && isSPACE(p[len-1])) \
	   --len; \
	SvCUR_set(sv, len); \
	p[len] = '\0'; \
    } \
} STMT_END

static int new_magic_get(pTHX_ SV *sv, MAGIC *mg) {
	dVAR;

	PERL_ARGS_ASSERT_MAGIC_SET;

	switch (*mg->mg_ptr) {
    case '!':
	{
		dSAVE_ERRNO;
	#ifdef VMS
		sv_setiv(sv, (IV)((errno == EVMSERR) ? vaxc$errno : errno));
	#else
		sv_setiv(sv, (IV)errno);
	#endif
	#ifdef OS2
		if (errno == errno_isOS2 || errno == errno_isOS2_set)
			sv_setpv(sv, os2error(Perl_rc));
		else
	#endif
		sv_setpv(sv, errno ? Strerror(errno) : "");
		if (SvPOKp(sv))
			SvPOK_on(sv);    /* may have got removed during taint processing */
		if (errno_utf8(aTHX))
			sv_utf8_decode(sv);
		RESTORE_ERRNO;
	}

	SvRTRIM(sv);
	SvIOK_on(sv);	/* what a wonderful hack! */
	break;
	}
}

MGVTBL* get_vtable(pTHX_ SV* sv) {
	static int inited = 0;
	static MGVTBL new_vtable;
	if (!inited) {
		MAGIC* original = mg_find(sv, PERL_MAGIC_sv);
		Copy(original->mg_virtual, &new_vtable, 1, MGVTBL);
		new_vtable.svt_get = new_magic_get;
		inited = 1;
	}
	return &new_vtable;
}

MODULE = utf8::errno				PACKAGE = utf8::errno

void
_reset_global(var)
	SV* var;
	CODE:
		MAGIC* magic = mg_find(var, PERL_MAGIC_sv);
		magic->mg_virtual = get_vtable(aTHX_ var);

