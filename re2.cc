/*
 * re2 (http://github.com/mudge/re2)
 * Ruby bindings to re2, an "efficient, principled regular expression library"
 *
 * Copyright (c) 2010, Paul Mucur (http://mucur.name)
 * Released under the BSD Licence, please see LICENSE.txt
 */

#include <re2/re2.h>

extern "C" {

  #include <ruby.h>

  #define BOOL2RUBY(v) (v ? Qtrue : Qfalse)
  #if !defined(RSTRING_LEN)
  #  define RSTRING_LEN(x) (RSTRING(x)->len)
  #endif

  typedef struct _re2p {
    RE2 *pattern;
  } re2_pattern;

  VALUE re2_cRE2;

  void
  re2_free(re2_pattern* self)
  {
    free(self);
  }

  VALUE
  re2_allocate(VALUE klass)
  {
    re2_pattern *p = (re2_pattern*)malloc(sizeof(re2_pattern));
    p->pattern = NULL;
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
    rb_str_buf_cat2(result, p->pattern->pattern().c_str());
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
    return rb_str_new2(p->pattern->pattern().c_str());
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
    return BOOL2RUBY(p->pattern->ok());
  }

  /*
   * call-seq:
   *   re2.error    -> error_str
   *
   * If the RE2 could not be created properly, returns an
   * error string.
   */

  VALUE
  re2_error(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return rb_str_new2(p->pattern->error().c_str());
  }

  /*
   * call-seq:
   *   re2.error_arg    -> error_str
   *
   * If the RE2 could not be created properly, returns
   * the offending portion of the regexp.
   */

  VALUE
  re2_error_arg(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return rb_str_new2(p->pattern->error_arg().c_str());
  }

  /*
   * call-seq:
   *   re2.program_size    -> size
   *
   * Returns the program size, a very approximate measure
   * of a regexp's "cost". Larger numbers are more expensive
   * than smaller numbers.
   */

  VALUE
  re2_program_size(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return INT2FIX(p->pattern->ProgramSize());
  }

  /*
   * call-seq:
   *   re2.options    -> options_hash
   *
   * Returns a hash of the options currently set for
   * <i>re2</i>.
   */

  VALUE
  re2_options(VALUE self)
  {
    VALUE options;
    re2_pattern *p;

    Data_Get_Struct(self, re2_pattern, p);
    options = rb_hash_new();

    rb_hash_aset(options, ID2SYM(rb_intern("utf8")),
        BOOL2RUBY(p->pattern->options().utf8()));

    rb_hash_aset(options, ID2SYM(rb_intern("posix_syntax")),
        BOOL2RUBY(p->pattern->options().posix_syntax()));

    rb_hash_aset(options, ID2SYM(rb_intern("longest_match")),
        BOOL2RUBY(p->pattern->options().longest_match()));

    rb_hash_aset(options, ID2SYM(rb_intern("log_errors")),
        BOOL2RUBY(p->pattern->options().log_errors()));

    rb_hash_aset(options, ID2SYM(rb_intern("max_mem")),
        INT2FIX(p->pattern->options().max_mem()));

    rb_hash_aset(options, ID2SYM(rb_intern("literal")),
        BOOL2RUBY(p->pattern->options().literal()));

    rb_hash_aset(options, ID2SYM(rb_intern("never_nl")),
        BOOL2RUBY(p->pattern->options().never_nl()));

    rb_hash_aset(options, ID2SYM(rb_intern("case_sensitive")),
        BOOL2RUBY(p->pattern->options().case_sensitive()));

    rb_hash_aset(options, ID2SYM(rb_intern("perl_classes")),
        BOOL2RUBY(p->pattern->options().perl_classes()));

    rb_hash_aset(options, ID2SYM(rb_intern("word_boundary")),
        BOOL2RUBY(p->pattern->options().word_boundary()));

    rb_hash_aset(options, ID2SYM(rb_intern("one_line")),
        BOOL2RUBY(p->pattern->options().one_line()));

    // This is a read-only hash after all...
    OBJ_FREEZE(options);

    return options;
  }

  /*
   * call-seq:
   *   re2.number_of_capturing_groups    -> int
   *
   * Returns the number of capturing subpatterns, or -1 if the regexp
   * wasn't valid on construction. The overall match ($0) does not
   * count: if the regexp is "(a)(b)", returns 2.
   */

  VALUE
  re2_number_of_capturing_groups(VALUE self)
  {
    re2_pattern *p;

    Data_Get_Struct(self, re2_pattern, p);
    return INT2FIX(p->pattern->NumberOfCapturingGroups());
  }

  /*
   * call-seq:
   *   re2.match(text)                 -> [match, match]
   *   re2.match(text, 0)              -> true or false
   *   re2.match(text, num_of_matches) -> [match, match]
   *
   * Looks for the pattern in <i>re2</i> in <i>text</i>; when specified
   * without a second argument, will return an array of the matching
   * pattern and all subpatterns. If the second argument is 0, a
   * simple true or false will be returned to indicate a successful
   * match. If the second argument is any integer greater than 0,
   * that number of matches will be returned (padded with nils if
   * there are insufficient matches).
   *
   *   r = RE2.new('w(o)(o)')
   *   r.match('woo')    #=> ["woo", "o", "o"]
   *   r.match('woo', 0) #=> true
   *   r.match('bob', 0) #=> false
   *   r.match('woo', 1) #=> ["woo", "o"]
   */

  VALUE
  re2_match(int argc, VALUE *argv, VALUE self)
  {
    int n;
    bool matched;
    re2_pattern *p;
    VALUE text, number_of_matches, matches;
    re2::StringPiece *string_matches, *text_as_string_piece;

    rb_scan_args(argc, argv, "11", &text, &number_of_matches);

    Data_Get_Struct(self, re2_pattern, p);

    if (RTEST(number_of_matches)) {
      n = NUM2INT(number_of_matches);
    } else {
      n = p->pattern->NumberOfCapturingGroups();
    }

    text_as_string_piece = new re2::StringPiece(StringValuePtr(text));

    if (n == 0) {
      return BOOL2RUBY(p->pattern->Match(*text_as_string_piece, 0, RE2::UNANCHORED, 0, 0));
    } else {

      /* Because match returns the whole match as well. */
      n += 1;

      string_matches = new re2::StringPiece[n];

      matched = p->pattern->Match(*text_as_string_piece, 0, RE2::UNANCHORED, string_matches, n);

      if (matched) {
        matches = rb_ary_new();

        for (int i = 0; i < n; i++) {
          if (!string_matches[i].empty()) {
            rb_ary_push(matches, rb_str_new2(string_matches[i].as_string().c_str()));
          } else {
            rb_ary_push(matches, Qnil);
          }
        }

        return matches;
      } else {
        return Qnil;
      }
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
    re2_pattern *p;

    if (rb_obj_is_kind_of(re, re2_cRE2)) {
      Data_Get_Struct(re, re2_pattern, p);
      result = RE2::FullMatch(StringValuePtr(text), *p->pattern);
    } else {
      result = RE2::FullMatch(StringValuePtr(text), StringValuePtr(re));
    }

    return BOOL2RUBY(result);
  }

  /*
   * call-seq:
   *   RE2::FullMatchN(text, re)    -> array of matches
   *
   * Returns an array of successful matches as defined in
   * <i>re</i> for <i>text</i>.
   *
   *   RE2::FullMatchN("woo", "w(oo)")   #=> ["oo"]
   */

  VALUE
  re2_FullMatchN(VALUE self, VALUE text, VALUE re)
  {
    int n;
    bool matched;
    re2_pattern *p;
    VALUE matches;
    RE2 *compiled_pattern;
    RE2::Arg *argv;
    const RE2::Arg **args;
    std::string *string_matches;

    if (rb_obj_is_kind_of(re, re2_cRE2)) {
      Data_Get_Struct(re, re2_pattern, p);
      compiled_pattern = p->pattern;
    } else {
      compiled_pattern = new RE2(StringValuePtr(re));
    }

    n = compiled_pattern->NumberOfCapturingGroups();

    argv = new RE2::Arg[n];
    args = new const RE2::Arg*[n];
    string_matches = new std::string[n];

    for (int i = 0; i < n; i++) {
      args[i] = &argv[i];
      argv[i] = &string_matches[i];
    }

    matched = RE2::FullMatchN(StringValuePtr(text), *compiled_pattern, args, n);

    if (matched) {
      matches = rb_ary_new();

      for (int i = 0; i < n; i++) {
        if (!string_matches[i].empty()) {
          rb_ary_push(matches, rb_str_new2(string_matches[i].c_str()));
        } else {
          rb_ary_push(matches, Qnil);
        }
      }

      return matches;
    } else {
      return Qnil;
    }
  }

  /*
   * call-seq:
   *   RE2::PartialMatchN(text, re)    -> array of matches
   *
   * Returns an array of successful matches as defined in
   * <i>re</i> for <i>text</i>.
   *
   *   RE2::PartialMatchN("woo", "w(oo)")   #=> ["oo"]
   */

  VALUE
  re2_PartialMatchN(VALUE self, VALUE text, VALUE re)
  {
    int n;
    bool matched;
    re2_pattern *p;
    VALUE matches;
    RE2 *compiled_pattern;
    RE2::Arg *argv;
    const RE2::Arg **args;
    std::string *string_matches;

    if (rb_obj_is_kind_of(re, re2_cRE2)) {
      Data_Get_Struct(re, re2_pattern, p);
      compiled_pattern = p->pattern;
    } else {
      compiled_pattern = new RE2(StringValuePtr(re));
    }

    n = compiled_pattern->NumberOfCapturingGroups();

    argv = new RE2::Arg[n];
    args = new const RE2::Arg*[n];
    string_matches = new std::string[n];

    for (int i = 0; i < n; i++) {
      args[i] = &argv[i];
      argv[i] = &string_matches[i];
    }

    matched = RE2::PartialMatchN(StringValuePtr(text), *compiled_pattern, args, n);

    if (matched) {
      matches = rb_ary_new();

      for (int i = 0; i < n; i++) {
        if (!string_matches[i].empty()) {
          rb_ary_push(matches, rb_str_new2(string_matches[i].c_str()));
        } else {
          rb_ary_push(matches, Qnil);
        }
      }

      return matches;
    } else {
      return Qnil;
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
    re2_pattern *p;

    if (rb_obj_is_kind_of(re, re2_cRE2)) {
      Data_Get_Struct(re, re2_pattern, p);
      result = RE2::PartialMatch(StringValuePtr(text), *p->pattern);
    } else {
      result = RE2::PartialMatch(StringValuePtr(text), StringValuePtr(re));
    }

    return BOOL2RUBY(result);
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
    VALUE repl;
    re2_pattern *p;

    // Convert all the inputs to be pumped into RE2::Replace.
    std::string str_as_string(StringValuePtr(str));
    re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));

    // Do the replacement.
    if (rb_obj_is_kind_of(pattern, re2_cRE2)) {
      Data_Get_Struct(pattern, re2_pattern, p);
      RE2::Replace(&str_as_string, *p->pattern, rewrite_as_string_piece);
    } else {
      RE2::Replace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);
    }

    // Save the replacement as a VALUE.
    repl = rb_str_new(str_as_string.c_str(), str_as_string.length());

    // Replace the original string with the replacement.
    rb_str_update(str, 0, RSTRING_LEN(str), repl);

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
    re2_pattern *p;
    std::string str_as_string(StringValuePtr(str));
    re2::StringPiece rewrite_as_string_piece(StringValuePtr(rewrite));
    VALUE repl;

    // Do the replacement.
    if (rb_obj_is_kind_of(pattern, re2_cRE2)) {
      Data_Get_Struct(pattern, re2_pattern, p);
      RE2::GlobalReplace(&str_as_string, *p->pattern, rewrite_as_string_piece);
    } else {
      RE2::GlobalReplace(&str_as_string, StringValuePtr(pattern), rewrite_as_string_piece);
    }

    // Save the replacement as a VALUE.
    repl = rb_str_new(str_as_string.c_str(), str_as_string.length());

    // Replace the original string with the replacement.
    rb_str_update(str, 0, RSTRING_LEN(str), repl);

    return str;
  }

  /*
   * call-seq:
   *   RE2::QuoteMeta(str)    -> str
   *
   * Returns a version of str with all potentially meaningful regexp
   * characters escaped. The returned string, used as a regular
   * expression, will exactly match the original string.
   *
   *   RE2::QuoteMeta("1.5-2.0?")    #=> "1\.5\-2\.0\?"
   */

  VALUE
  re2_QuoteMeta(VALUE self, VALUE unquoted)
  {
    re2::StringPiece unquoted_as_string_piece(StringValuePtr(unquoted));
    return rb_str_new2(RE2::QuoteMeta(unquoted_as_string_piece).c_str());
  }

  void
  Init_re2()
  {
    re2_cRE2 = rb_define_class("RE2", rb_cObject);
    rb_define_alloc_func(re2_cRE2, (VALUE (*)(VALUE))re2_allocate);
    rb_define_method(re2_cRE2, "initialize", (VALUE (*)(...))re2_initialize, -1);
    rb_define_method(re2_cRE2, "ok?", (VALUE (*)(...))re2_ok, 0);
    rb_define_method(re2_cRE2, "error", (VALUE (*)(...))re2_error, 0);
    rb_define_method(re2_cRE2, "error_arg", (VALUE (*)(...))re2_error_arg, 0);
    rb_define_method(re2_cRE2, "program_size", (VALUE (*)(...))re2_program_size, 0);
    rb_define_method(re2_cRE2, "options", (VALUE (*)(...))re2_options, 0);
    rb_define_method(re2_cRE2, "number_of_capturing_groups", (VALUE (*)(...))re2_number_of_capturing_groups, 0);
    rb_define_method(re2_cRE2, "match", (VALUE (*)(...))re2_match, -1);
    rb_define_method(re2_cRE2, "to_s", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "to_str", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "pattern", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "inspect", (VALUE (*)(...))re2_inspect, 0);
    rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
    rb_define_singleton_method(re2_cRE2, "FullMatchN", (VALUE (*)(...))re2_FullMatchN, 2);
    rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
    rb_define_singleton_method(re2_cRE2, "PartialMatchN", (VALUE (*)(...))re2_PartialMatchN, 2);
    rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
    rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
    rb_define_singleton_method(re2_cRE2, "QuoteMeta", (VALUE (*)(...))re2_QuoteMeta, 1);
  }
}
