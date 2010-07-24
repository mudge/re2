#include <ruby.h>
#include <re2/re2.h>

#if !defined(RSTRING_PTR)
#  define RSTRING_LEN(x) (RSTRING(x)->len)
#  define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

VALUE re2_cRE2;

VALUE re2_FullMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::FullMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

VALUE re2_PartialMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::PartialMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

VALUE re2_AnyReplace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite, int (*replaceFunction)(std::string*, const re2::RE2&, const re2::StringPiece&))
{
  // Ensure that str is a string.
  Check_Type(str, T_STRING);

  // The original string.
  char* original_str = RSTRING_PTR(str);

  char* replaced_str;

  // The final result.
  VALUE final_str;

  // Convert all the inputs to be pumped into RE2::Replace.
  std::string str_as_string(original_str);
  RE2 pattern_as_re2(StringValuePtr(pattern));
  re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));

  // Do the replacement.
  (*replaceFunction)(&str_as_string, pattern_as_re2, rewrite_as_string_piece);

  // Convert the result into a C string.
  replaced_str = (char*)str_as_string.c_str();

  // Set str to be the new string.
  final_str = rb_str_new(replaced_str, str_as_string.length());
  RSTRING_PTR(str) = RSTRING_PTR(final_str);
  RSTRING_LEN(str) = RSTRING_LEN(final_str);

  return str;
}

VALUE re2_Replace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
{
  return re2_AnyReplace(self, str, pattern, rewrite, (int (*)(std::string*, const re2::RE2&, const re2::StringPiece&))&RE2::Replace);
}

VALUE re2_GlobalReplace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
{
  return re2_AnyReplace(self, str, pattern, rewrite, &RE2::GlobalReplace);
}

extern "C" void Init_re2()
{
  re2_cRE2 = rb_define_class("RE2", rb_cObject);
  rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
  rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
  rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
  rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
}

