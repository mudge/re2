#include <ruby.h>
#include <re2/re2.h>

VALUE re2_mRE2;

VALUE FullMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::FullMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

VALUE PartialMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::PartialMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

extern "C" void Init_re2()
{
  re2_mRE2 = rb_define_module("RE2");
  rb_define_singleton_method(re2_mRE2, "FullMatch", (VALUE (*)(...))FullMatch, 2);
  rb_define_singleton_method(re2_mRE2, "PartialMatch", (VALUE (*)(...))PartialMatch, 2);
}

