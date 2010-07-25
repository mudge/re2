#include <ruby.h>
#include <re2/re2.h>

extern "C" {

  typedef struct _re2p {
    RE2 *pattern;
    VALUE pattern_as_string;
  } re2_pattern;

  VALUE re2_cRE2;

  void
  re2_free(re2_pattern* self)
  {
    free(self);
  }

  void
  re2_mark(re2_pattern* self)
  {
    rb_gc_mark(self->pattern_as_string);
  }

  VALUE
  re2_allocate(VALUE klass)
  {
    re2_pattern *p = (re2_pattern*)malloc(sizeof(re2_pattern));
    p->pattern = NULL;
    p->pattern_as_string = Qnil;
    return Data_Wrap_Struct(klass, 0, re2_free, p);
  }

  /*
   * call-seq:
   *   RE2.new(pattern)           #=> re2
   *   RE2.new(pattern, options)  #=> re2
   *
   * Returns a new RE2 object with a compiled version of
   * <i>pattern</i> stored inside.
   *
   * Options can be a hash with the following keys:
   *
   *   :utf8           - text and pattern are UTF-8; otherwise 
   *                     Latin-1 (default true)
   *
   *   :posix_syntax   - restrict regexps to POSIX egrep syntax
   *                     (default false)
   *
   *   :longest_match  - search for longest match, not first match
   *                     (default false)
   *
   *   :log_errors     - log syntax and execution errors to ERROR
   *                     (default true)
   *
   *   :max_mem        - approx. max memory footprint of RE2
   *
   *   :literal        - interpret string as literal, not regexp
   *                     (default false)
   *
   *   :never_nl       - never match \n, even if it is in regexp
   *                     (default false)
   *
   *   :case_sensitive - match is case-sensitive (regexp can override
   *                     with (?i) unless in posix_syntax mode)
   *                     (default true)
   *
   *   :perl_classes   - allow Perl's \d \s \w \D \S \W when in
   *                     posix_syntax mode (default false)
   *
   *   :word_boundary  - allow \b \B (word boundary and not) when
   *                     in posix_syntax mode (default false)
   *
   *   :one_line       - ^ and $ only match beginning and end of text
   *                     when in posix_syntax mode (default false)
   */

  VALUE
  re2_initialize(int argc, VALUE *argv, VALUE self)
  {
    VALUE pattern, options, utf8, posix_syntax, longest_match, log_errors,
          max_mem, literal, never_nl, case_sensitive, perl_classes, 
          word_boundary, one_line;
    re2_pattern *p;
    RE2::Options *re2_options;

    rb_scan_args(argc, argv, "11", &pattern, &options);
    Data_Get_Struct(self, re2_pattern, p);

    if (RTEST(options)) {
      if (TYPE(options) != T_HASH) {
        rb_raise(rb_eArgError, "options should be a hash");
      }

      re2_options = new RE2::Options();

      utf8 = rb_hash_aref(options, ID2SYM(rb_intern("utf8")));
      if (!NIL_P(utf8)) {
        re2_options->set_utf8(RTEST(utf8));
      }

      posix_syntax = rb_hash_aref(options, ID2SYM(rb_intern("posix_syntax")));
      if (!NIL_P(posix_syntax)) {
        re2_options->set_posix_syntax(RTEST(posix_syntax));
      }

      longest_match = rb_hash_aref(options, ID2SYM(rb_intern("longest_match")));
      if (!NIL_P(longest_match)) {
        re2_options->set_longest_match(RTEST(longest_match));
      }

      log_errors = rb_hash_aref(options, ID2SYM(rb_intern("log_errors")));
      if (!NIL_P(log_errors)) {
        re2_options->set_log_errors(RTEST(log_errors));
      }

      max_mem = rb_hash_aref(options, ID2SYM(rb_intern("max_mem")));
      if (!NIL_P(max_mem)) {
        re2_options->set_max_mem(NUM2INT(max_mem));
      }

      literal = rb_hash_aref(options, ID2SYM(rb_intern("literal")));
      if (!NIL_P(literal)) {
        re2_options->set_literal(RTEST(literal));
      }

      never_nl = rb_hash_aref(options, ID2SYM(rb_intern("never_nl")));
      if (!NIL_P(never_nl)) {
        re2_options->set_never_nl(RTEST(never_nl));
      }

      case_sensitive = rb_hash_aref(options, ID2SYM(rb_intern("case_sensitive")));
      if (!NIL_P(case_sensitive)) {
        re2_options->set_case_sensitive(RTEST(case_sensitive));
      }

      perl_classes = rb_hash_aref(options, ID2SYM(rb_intern("perl_classes")));
      if (!NIL_P(perl_classes)) {
        re2_options->set_perl_classes(RTEST(perl_classes));
      }

      word_boundary = rb_hash_aref(options, ID2SYM(rb_intern("word_boundary")));
      if (!NIL_P(word_boundary)) {
        re2_options->set_word_boundary(RTEST(word_boundary));
      }

      one_line = rb_hash_aref(options, ID2SYM(rb_intern("one_line")));
      if (!NIL_P(one_line)) {
        re2_options->set_one_line(RTEST(one_line));
      }

      p->pattern = new RE2(StringValuePtr(pattern), *re2_options);
    } else {
      p->pattern = new RE2(StringValuePtr(pattern));
    }

    p->pattern_as_string = StringValue(pattern);
    return self;
  }

  /*
   * call-seq:
   *   re2.inspect   -> string
   *
   * Returns a printable version of the regular expression __re2__,
   * surrounded by forward slashes.
   *
   *   re2 = RE2.new("woo?")
   *   re2.inspect    #=> "/woo?/"
   */

  VALUE
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

  /*
   * call-seq:
   *   re2.to_s    -> string
   *
   * Returns a string version of the regular expression __re2__.
   *
   *   re2 = RE2.new("woo?")
   *   re2.to_s    #=> "woo?"
   */

  VALUE
  re2_to_s(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return p->pattern_as_string;
  }

  /*
   * call-seq:
   *   re2.ok?    -> true or false
   *
   * Returns whether or not the regular expression __re2__
   * was compiled successfully or not.
   *
   *   re2 = RE2.new("woo?")
   *   re2.ok?    #=> true
   */

  VALUE
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

  /*
   * call-seq:
   *   RE2::FullMatch(text, re)    -> true or false
   *
   * Returns whether or not a full match for __re__ was
   * found in text.
   *
   *   RE2::FullMatch("woo", "wo+")    #=> true
   *   RE2::FullMatch("woo", "a")      #=> false
   *   re2 = RE2.new("woo")
   *   RE2::FullMatch("woo", re2)      #=> true
   */

  VALUE
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

  /*
   * call-seq:
   *   RE2::PartialMatch(text, re)    -> true or false
   *
   * Returns whether or not a partial match for __re__ was
   * found in text.
   *
   *   RE2::PartialMatch("woo", "o+")     #=> true
   *   RE2::PartialMatch("woo", "a")      #=> false
   *   re2 = RE2.new("oo?")
   *   RE2::PartialMatch("woo", re2)      #=> true
   */

  VALUE
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

  /*
   * call-seq:
   *   RE2::Replace(str, pattern, rewrite)    -> str
   *
   * Replaces the first occurrence __pattern__ in __str__ with 
   * __rewrite__ <i>in place</i>.
   *
   *   RE2::Replace("hello there", "hello", "howdy") #=> "howdy there"
   *   re2 = RE2.new("hel+o")
   *   RE2::Replace("hello there", re2, "yo")        #=> "yo there"
   *   text = "Good morning"
   *   RE2::Replace(text, "morn", "even")            #=> "Good evening"
   *   text                                          #=> "Good evening"
   */

  VALUE
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

  /*
   * call-seq:
   *   RE2::GlobalReplace(str, pattern, rewrite)    -> str
   *
   * Replaces every occurrence of __pattern__ in __str__ with 
   * __rewrite__ <i>in place</i>.
   *
   *   RE2::GlobalReplace("hello there", "e", "i")   #=> "hillo thiri"
   *   re2 = RE2.new("oo?")
   *   RE2::GlobalReplace("whoops-doops", re2, "e")  #=> "wheps-deps"
   *   text = "Good morning"
   *   RE2::GlobalReplace(text, "o", "ee")           #=> "Geeeed meerning"
   *   text                                          #=> "Geeeed meerning"
   */

  VALUE
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

  void
  Init_re2()
  {
    re2_cRE2 = rb_define_class("RE2", rb_cObject);
    rb_define_alloc_func(re2_cRE2, (VALUE (*)(VALUE))re2_allocate);
    rb_define_method(re2_cRE2, "initialize", (VALUE (*)(...))re2_initialize, -1);
    rb_define_method(re2_cRE2, "ok?", (VALUE (*)(...))re2_ok, 0);
    rb_define_method(re2_cRE2, "to_s", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "to_str", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "inspect", (VALUE (*)(...))re2_inspect, 0);
    rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
    rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
    rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
    rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
  }
}
