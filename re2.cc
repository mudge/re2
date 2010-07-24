#include <ruby.h>
#include <re2/re2.h>

VALUE re2_cRE2;

extern "C" VALUE
re2_FullMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::FullMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

extern "C" VALUE
re2_PartialMatch(VALUE self, VALUE text, VALUE re)
{
  if (RE2::PartialMatch(StringValuePtr(text), StringValuePtr(re))) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

extern "C" VALUE
re2_Replace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
{

  // Convert all the inputs to be pumped into RE2::Replace.
  std::string str_as_string(StringValuePtr(str));
  re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));
  VALUE repl;

  // Do the replacement.
  RE2::Replace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);

  // Save the replacement as a VALUE.
  repl = rb_str_new(str_as_string.c_str(), str_as_string.length());

  // Ready str for modification 
  rb_str_modify(str);

  // Make sure it is as long as the new string.
  rb_str_resize(str, str_as_string.length());

  // Replace the string.
  memcpy(RSTRING_PTR(str), RSTRING_PTR(repl), RSTRING_LEN(repl));

  return str;
}

extern "C" VALUE
re2_GlobalReplace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
{

  // Convert all the inputs to be pumped into RE2::Replace.
  std::string str_as_string(StringValuePtr(str));
  re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));
  VALUE repl;

  // Do the replacement.
  RE2::GlobalReplace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);

  // Save the replacement as a VALUE.
  repl = rb_str_new(str_as_string.c_str(), str_as_string.length());

  // Ready str for modification 
  rb_str_modify(str);

  // Make sure it is as long as the new string.
  rb_str_resize(str, str_as_string.length());

  // Replace the string.
  memcpy(RSTRING_PTR(str), RSTRING_PTR(repl), RSTRING_LEN(repl));

  return str;
}

extern "C" void
Init_re2()
{
  re2_cRE2 = rb_define_class("RE2", rb_cObject);
  rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
  rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
  rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
  rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
}

