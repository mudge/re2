#include <ruby.h>
#include <re2/re2.h>

typedef struct _re2p {
  RE2 *pattern;
  VALUE pattern_as_string;
} re2_pattern;

VALUE re2_cRE2;

extern "C" void
re2_free(re2_pattern* self)
{
  free(self);
}

extern "C" void
re2_mark(re2_pattern* self)
{
  rb_gc_mark(self->pattern_as_string);
}

extern "C" VALUE
re2_allocate(VALUE klass)
{
  re2_pattern *p = (re2_pattern*)malloc(sizeof(re2_pattern));
  p->pattern = NULL;
  p->pattern_as_string = Qnil;
  return Data_Wrap_Struct(klass, 0, re2_free, p);
}

extern "C" VALUE
re2_initialize(VALUE self, VALUE pattern)
{
  re2_pattern *p;
  Data_Get_Struct(self, re2_pattern, p);
  p->pattern = new RE2(StringValuePtr(pattern));
  p->pattern_as_string = StringValue(pattern);
  return self;
}

extern "C" VALUE
re2_inspect(VALUE self)
{
  VALUE result = rb_str_buf_new(0);
  re2_pattern *p;

  rb_str_buf_cat2(result, "/");
  Data_Get_Struct(self, re2_pattern, p);
  rb_str_buf_cat2(result, StringValuePtr(p->pattern_as_string));
  rb_str_buf_cat2(result, "/");

  return result;
}

extern "C" VALUE
re2_to_s(VALUE self)
{
  re2_pattern *p;
  Data_Get_Struct(self, re2_pattern, p);
  return p->pattern_as_string;
}

extern "C" VALUE
re2_ok(VALUE self)
{
  re2_pattern *p;
  Data_Get_Struct(self, re2_pattern, p);
  if (p->pattern->ok()) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

extern "C" VALUE
re2_FullMatch(VALUE self, VALUE text, VALUE re)
{
  bool result;

  if (rb_obj_is_kind_of(re, re2_cRE2)) {
    re2_pattern *p;
    Data_Get_Struct(re, re2_pattern, p);
    result = RE2::FullMatch(StringValuePtr(text), *p->pattern);
  } else {
    result = RE2::FullMatch(StringValuePtr(text), StringValuePtr(re));
  }

  if (result) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

extern "C" VALUE
re2_PartialMatch(VALUE self, VALUE text, VALUE re)
{
  bool result;

  if (rb_obj_is_kind_of(re, re2_cRE2)) {
    re2_pattern *p;
    Data_Get_Struct(re, re2_pattern, p);
    result = RE2::PartialMatch(StringValuePtr(text), *p->pattern);
  } else {
    result = RE2::PartialMatch(StringValuePtr(text), StringValuePtr(re));
  }

  if (result) {
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
  if (rb_obj_is_kind_of(pattern, re2_cRE2)) {
    re2_pattern *p;
    Data_Get_Struct(pattern, re2_pattern, p);
    RE2::Replace(&str_as_string, *p->pattern, rewrite_as_string_piece);
  } else {
    RE2::Replace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);
  }

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

  // Convert all the inputs to be pumped into RE2::GlobalReplace.
  std::string str_as_string(StringValuePtr(str));
  re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));
  VALUE repl;

  // Do the replacement.
  if (rb_obj_is_kind_of(pattern, re2_cRE2)) {
    re2_pattern *p;
    Data_Get_Struct(pattern, re2_pattern, p);
    RE2::GlobalReplace(&str_as_string, *p->pattern, rewrite_as_string_piece);
  } else {
    RE2::GlobalReplace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);
  }

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
  rb_define_alloc_func(re2_cRE2, (VALUE (*)(VALUE))re2_allocate);
  rb_define_method(re2_cRE2, "initialize", (VALUE (*)(...))re2_initialize, 1);
  rb_define_method(re2_cRE2, "ok?", (VALUE (*)(...))re2_ok, 0);
  rb_define_method(re2_cRE2, "to_s", (VALUE (*)(...))re2_to_s, 0);
  rb_define_method(re2_cRE2, "inspect", (VALUE (*)(...))re2_inspect, 0);
  rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
  rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
  rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
  rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
}

