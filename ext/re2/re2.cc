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
  #define UNUSED(x) ((void)x)

  #if !defined(RSTRING_LEN)
  #  define RSTRING_LEN(x) (RSTRING(x)->len)
  #endif

  typedef struct _re2p {
    RE2 *pattern;
  } re2_pattern;

  VALUE re2_cRE2;

  /* Symbols used in RE2 options. */
  static ID id_utf8, id_posix_syntax, id_longest_match, id_log_errors,
             id_max_mem, id_literal, id_never_nl, id_case_sensitive,
             id_perl_classes, id_word_boundary, id_one_line;

  void
  re2_free(re2_pattern* self)
  {
    if (self->pattern) {
      delete self->pattern;
    }
    free(self);
  }

  static VALUE
  re2_allocate(VALUE klass)
  {
    re2_pattern *p = (re2_pattern*)malloc(sizeof(re2_pattern));
    p->pattern = NULL;
    return Data_Wrap_Struct(klass, 0, re2_free, p);
  }

  /*
   * call-seq:
   *   RE2(pattern)                  -> re2
   *   RE2(pattern, options)         -> re2
   *
   * Returns a new RE2 object with a compiled version of
   * +pattern+ stored inside. Equivalent to +RE2.new+.
   */
  static VALUE
  re2_re2(int argc, VALUE *argv, VALUE self)
  {
    UNUSED(self);
    return rb_class_new_instance(argc, argv, re2_cRE2);
  }

  /*
   * call-seq:
   *   RE2.new(pattern)               -> re2
   *   RE2.new(pattern, options)      -> re2
   *   RE2.compile(pattern)           -> re2
   *   RE2.compile(pattern, options)  -> re2
   *
   * Returns a new RE2 object with a compiled version of
   * +pattern+ stored inside.
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
  static VALUE
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

      utf8 = rb_hash_aref(options, ID2SYM(id_utf8));
      if (!NIL_P(utf8)) {
        re2_options->set_utf8(RTEST(utf8));
      }

      posix_syntax = rb_hash_aref(options, ID2SYM(id_posix_syntax));
      if (!NIL_P(posix_syntax)) {
        re2_options->set_posix_syntax(RTEST(posix_syntax));
      }

      longest_match = rb_hash_aref(options, ID2SYM(id_longest_match));
      if (!NIL_P(longest_match)) {
        re2_options->set_longest_match(RTEST(longest_match));
      }

      log_errors = rb_hash_aref(options, ID2SYM(id_log_errors));
      if (!NIL_P(log_errors)) {
        re2_options->set_log_errors(RTEST(log_errors));
      }

      max_mem = rb_hash_aref(options, ID2SYM(id_max_mem));
      if (!NIL_P(max_mem)) {
        re2_options->set_max_mem(NUM2INT(max_mem));
      }

      literal = rb_hash_aref(options, ID2SYM(id_literal));
      if (!NIL_P(literal)) {
        re2_options->set_literal(RTEST(literal));
      }

      never_nl = rb_hash_aref(options, ID2SYM(id_never_nl));
      if (!NIL_P(never_nl)) {
        re2_options->set_never_nl(RTEST(never_nl));
      }

      case_sensitive = rb_hash_aref(options, ID2SYM(id_case_sensitive));
      if (!NIL_P(case_sensitive)) {
        re2_options->set_case_sensitive(RTEST(case_sensitive));
      }

      perl_classes = rb_hash_aref(options, ID2SYM(id_perl_classes));
      if (!NIL_P(perl_classes)) {
        re2_options->set_perl_classes(RTEST(perl_classes));
      }

      word_boundary = rb_hash_aref(options, ID2SYM(id_word_boundary));
      if (!NIL_P(word_boundary)) {
        re2_options->set_word_boundary(RTEST(word_boundary));
      }

      one_line = rb_hash_aref(options, ID2SYM(id_one_line));
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
   * Returns a printable version of the regular expression +re2+,
   * surrounded by forward slashes.
   *
   *   re2 = RE2.new("woo?")
   *   re2.inspect    #=> "/woo?/"
   */
  static VALUE
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
   *   re2.to_s       -> string
   *   re2.to_str     -> string
   *   re2.pattern    -> string
   *   re2.source     -> string
   *   re2.inspect    -> string
   *
   * Returns a string version of the regular expression +re2+.
   *
   *   re2 = RE2.new("woo?")
   *   re2.to_s    #=> "woo?"
   */
  static VALUE
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
   * Returns whether or not the regular expression +re2+
   * was compiled successfully or not.
   *
   *   re2 = RE2.new("woo?")
   *   re2.ok?    #=> true
   */
  static VALUE
  re2_ok(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->ok());
  }

  /*
   * call-seq:
   *   re2.utf8?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the utf8 option set to true.
   *
   *   re2 = RE2.new("woo?", :utf8 => true)
   *   re2.utf8?    #=> true
   */
  static VALUE
  re2_utf8(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().utf8());
  }

  /*
   * call-seq:
   *   re2.posix_syntax?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the posix_syntax option set to true.
   *
   *   re2 = RE2.new("woo?", :posix_syntax => true)
   *   re2.posix_syntax?    #=> true
   */
  static VALUE
  re2_posix_syntax(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().posix_syntax());
  }

  /*
   * call-seq:
   *   re2.longest_match?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the longest_match option set to true.
   *
   *   re2 = RE2.new("woo?", :longest_match => true)
   *   re2.longest_match?    #=> true
   */
  static VALUE
  re2_longest_match(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().longest_match());
  }

  /*
   * call-seq:
   *   re2.log_errors?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the log_errors option set to true.
   *
   *   re2 = RE2.new("woo?", :log_errors => true)
   *   re2.log_errors?    #=> true
   */
  static VALUE
  re2_log_errors(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().log_errors());
  }

  /*
   * call-seq:
   *   re2.max_mem    -> int
   *
   * Returns the max_mem setting for the regular expression
   * +re2+.
   *
   *   re2 = RE2.new("woo?", :max_mem => 1024)
   *   re2.max_mem    #=> 1024
   */
  static VALUE
  re2_max_mem(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return INT2FIX(p->pattern->options().max_mem());
  }

  /*
   * call-seq:
   *   re2.literal?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the literal option set to true.
   *
   *   re2 = RE2.new("woo?", :literal => true)
   *   re2.literal?    #=> true
   */
  static VALUE
  re2_literal(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().literal());
  }

  /*
   * call-seq:
   *   re2.never_nl?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the never_nl option set to true.
   *
   *   re2 = RE2.new("woo?", :never_nl => true)
   *   re2.never_nl?    #=> true
   */
  static VALUE
  re2_never_nl(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().never_nl());
  }

  /*
   * call-seq:
   *   re2.case_sensitive?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the case_sensitive option set to true.
   *
   *   re2 = RE2.new("woo?", :case_sensitive => true)
   *   re2.case_sensitive?    #=> true
   */
  static VALUE
  re2_case_sensitive(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().case_sensitive());
  }

  /*
   * call-seq:
   *   re2.case_insensitive?    -> true or false
   *   re2.casefold?            -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the case_sensitive option set to false.
   *
   *   re2 = RE2.new("woo?", :case_sensitive => true)
   *   re2.case_insensitive?    #=> false
   */
  static VALUE
  re2_case_insensitive(VALUE self)
  {
    return BOOL2RUBY(re2_case_sensitive(self) != Qtrue);
  }

  /*
   * call-seq:
   *   re2.perl_classes?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the perl_classes option set to true.
   *
   *   re2 = RE2.new("woo?", :perl_classes => true)
   *   re2.perl_classes?    #=> true
   */
  static VALUE
  re2_perl_classes(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().perl_classes());
  }

  /*
   * call-seq:
   *   re2.word_boundary?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the word_boundary option set to true.
   *
   *   re2 = RE2.new("woo?", :word_boundary => true)
   *   re2.word_boundary?    #=> true
   */
  static VALUE
  re2_word_boundary(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().word_boundary());
  }

  /*
   * call-seq:
   *   re2.one_line?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the one_line option set to true.
   *
   *   re2 = RE2.new("woo?", :one_line => true)
   *   re2.one_line?    #=> true
   */
  static VALUE
  re2_one_line(VALUE self)
  {
    re2_pattern *p;
    Data_Get_Struct(self, re2_pattern, p);
    return BOOL2RUBY(p->pattern->options().one_line());
  }

  /*
   * call-seq:
   *   re2.error    -> error_str
   *
   * If the RE2 could not be created properly, returns an
   * error string.
   */
  static VALUE
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
  static VALUE
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
  static VALUE
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
   * +re2+.
   */
  static VALUE
  re2_options(VALUE self)
  {
    VALUE options;
    re2_pattern *p;

    Data_Get_Struct(self, re2_pattern, p);
    options = rb_hash_new();

    rb_hash_aset(options, ID2SYM(id_utf8),
        BOOL2RUBY(p->pattern->options().utf8()));

    rb_hash_aset(options, ID2SYM(id_posix_syntax),
        BOOL2RUBY(p->pattern->options().posix_syntax()));

    rb_hash_aset(options, ID2SYM(id_longest_match),
        BOOL2RUBY(p->pattern->options().longest_match()));

    rb_hash_aset(options, ID2SYM(id_log_errors),
        BOOL2RUBY(p->pattern->options().log_errors()));

    rb_hash_aset(options, ID2SYM(id_max_mem),
        INT2FIX(p->pattern->options().max_mem()));

    rb_hash_aset(options, ID2SYM(id_literal),
        BOOL2RUBY(p->pattern->options().literal()));

    rb_hash_aset(options, ID2SYM(id_never_nl),
        BOOL2RUBY(p->pattern->options().never_nl()));

    rb_hash_aset(options, ID2SYM(id_case_sensitive),
        BOOL2RUBY(p->pattern->options().case_sensitive()));

    rb_hash_aset(options, ID2SYM(id_perl_classes),
        BOOL2RUBY(p->pattern->options().perl_classes()));

    rb_hash_aset(options, ID2SYM(id_word_boundary),
        BOOL2RUBY(p->pattern->options().word_boundary()));

    rb_hash_aset(options, ID2SYM(id_one_line),
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
  static VALUE
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
   * Looks for the pattern in +re2+ in +text+; when specified
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
  static VALUE
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
   *   re2.match?(text)  -> true or false
   *   re2 =~ text  -> true or false
   *
   * Returns true or false to indicate a successful match.
   * Equivalent to +re2.match(text, 0)+.
   */
  static VALUE
  re2_match_query(VALUE self, VALUE text)
  {
    VALUE argv[2];
    argv[0] = text;
    argv[1] = INT2FIX(0);

    return re2_match(2, argv, self);
  }

  /*
   * call-seq:
   *   re2 !~ text  -> true or false
   *
   * Returns true or false to indicate an unsuccessful match.
   * Equivalent to +!re2.match(text, 0)+.
   */
  static VALUE
  re2_bang_tilde(VALUE self, VALUE text)
  {
    return BOOL2RUBY(re2_match_query(self, text) != Qtrue);
  }

  /*
   * call-seq:
   *   RE2::FullMatch(text, re)    -> true or false
   *
   * Returns whether or not a full match for +re2+ was
   * found in text.
   *
   *   RE2::FullMatch("woo", "wo+")    #=> true
   *   RE2::FullMatch("woo", "a")      #=> false
   *   re2 = RE2.new("woo")
   *   RE2::FullMatch("woo", re2)      #=> true
   */
  static VALUE
  re2_FullMatch(VALUE self, VALUE text, VALUE re)
  {
    UNUSED(self);
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
   * +re+ for +text+.
   *
   *   RE2::FullMatchN("woo", "w(oo)")   #=> ["oo"]
   */
  static VALUE
  re2_FullMatchN(VALUE self, VALUE text, VALUE re)
  {
    UNUSED(self);
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
   * +re+ for +text+.
   *
   *   RE2::PartialMatchN("woo", "w(oo)")   #=> ["oo"]
   */
  static VALUE
  re2_PartialMatchN(VALUE self, VALUE text, VALUE re)
  {
    UNUSED(self);
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
   * Returns whether or not a partial match for +re2+ was
   * found in text.
   *
   *   RE2::PartialMatch("woo", "o+")     #=> true
   *   RE2::PartialMatch("woo", "a")      #=> false
   *   re2 = RE2.new("oo?")
   *   RE2::PartialMatch("woo", re2)      #=> true
   */
  static VALUE
  re2_PartialMatch(VALUE self, VALUE text, VALUE re)
  {
    UNUSED(self);
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
   * Replaces the first occurrence +pattern+ in +str+ with 
   * +rewrite+ <i>in place</i>.
   *
   *   RE2::Replace("hello there", "hello", "howdy") #=> "howdy there"
   *   re2 = RE2.new("hel+o")
   *   RE2::Replace("hello there", re2, "yo")        #=> "yo there"
   *   text = "Good morning"
   *   RE2::Replace(text, "morn", "even")            #=> "Good evening"
   *   text                                          #=> "Good evening"
   */
  static VALUE
  re2_Replace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
  {
    UNUSED(self);
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
   * Replaces every occurrence of +pattern+ in +str+ with 
   * +rewrite+ <i>in place</i>.
   *
   *   RE2::GlobalReplace("hello there", "e", "i")   #=> "hillo thiri"
   *   re2 = RE2.new("oo?")
   *   RE2::GlobalReplace("whoops-doops", re2, "e")  #=> "wheps-deps"
   *   text = "Good morning"
   *   RE2::GlobalReplace(text, "o", "ee")           #=> "Geeeed meerning"
   *   text                                          #=> "Geeeed meerning"
   */
  static VALUE
  re2_GlobalReplace(VALUE self, VALUE str, VALUE pattern, VALUE rewrite)
  {
    UNUSED(self);

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
   *   RE2.escape(str)        -> str
   *   RE2.quote(str)         -> str
   *
   * Returns a version of str with all potentially meaningful regexp
   * characters escaped. The returned string, used as a regular
   * expression, will exactly match the original string.
   *
   *   RE2::QuoteMeta("1.5-2.0?")    #=> "1\.5\-2\.0\?"
   */
  static VALUE
  re2_QuoteMeta(VALUE self, VALUE unquoted)
  {
    UNUSED(self);
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
    rb_define_method(re2_cRE2, "match?", (VALUE (*)(...))re2_match_query, 1);
    rb_define_method(re2_cRE2, "=~", (VALUE (*)(...))re2_match_query, 1);
    rb_define_method(re2_cRE2, "===", (VALUE (*)(...))re2_match_query, 1);
    rb_define_method(re2_cRE2, "!~", (VALUE (*)(...))re2_bang_tilde, 1);
    rb_define_method(re2_cRE2, "to_s", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "to_str", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "pattern", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "source", (VALUE (*)(...))re2_to_s, 0);
    rb_define_method(re2_cRE2, "inspect", (VALUE (*)(...))re2_inspect, 0);
    rb_define_method(re2_cRE2, "utf8?", (VALUE (*)(...))re2_utf8, 0);
    rb_define_method(re2_cRE2, "posix_syntax?", (VALUE (*)(...))re2_posix_syntax, 0);
    rb_define_method(re2_cRE2, "longest_match?", (VALUE (*)(...))re2_longest_match, 0);
    rb_define_method(re2_cRE2, "log_errors?", (VALUE (*)(...))re2_log_errors, 0);
    rb_define_method(re2_cRE2, "max_mem", (VALUE (*)(...))re2_max_mem, 0);
    rb_define_method(re2_cRE2, "literal?", (VALUE (*)(...))re2_literal, 0);
    rb_define_method(re2_cRE2, "never_nl?", (VALUE (*)(...))re2_never_nl, 0);
    rb_define_method(re2_cRE2, "case_sensitive?", (VALUE (*)(...))re2_case_sensitive, 0);
    rb_define_method(re2_cRE2, "case_insensitive?", (VALUE (*)(...))re2_case_insensitive, 0);
    rb_define_method(re2_cRE2, "casefold?", (VALUE (*)(...))re2_case_insensitive, 0);
    rb_define_method(re2_cRE2, "perl_classes?", (VALUE (*)(...))re2_perl_classes, 0);
    rb_define_method(re2_cRE2, "word_boundary?", (VALUE (*)(...))re2_word_boundary, 0);
    rb_define_method(re2_cRE2, "one_line?", (VALUE (*)(...))re2_one_line, 0);
    rb_define_singleton_method(re2_cRE2, "FullMatch", (VALUE (*)(...))re2_FullMatch, 2);
    rb_define_singleton_method(re2_cRE2, "FullMatchN", (VALUE (*)(...))re2_FullMatchN, 2);
    rb_define_singleton_method(re2_cRE2, "PartialMatch", (VALUE (*)(...))re2_PartialMatch, 2);
    rb_define_singleton_method(re2_cRE2, "PartialMatchN", (VALUE (*)(...))re2_PartialMatchN, 2);
    rb_define_singleton_method(re2_cRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
    rb_define_singleton_method(re2_cRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
    rb_define_singleton_method(re2_cRE2, "QuoteMeta", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRE2, "escape", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRE2, "quote", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRE2, "compile", (VALUE (*)(...))rb_class_new_instance, -1);
    rb_define_global_function("RE2", (VALUE (*)(...))re2_re2, -1);

    /* Create the symbols used in options. */
    id_utf8 = rb_intern("utf8");
    id_posix_syntax = rb_intern("posix_syntax");
    id_longest_match = rb_intern("longest_match");
    id_log_errors = rb_intern("log_errors");
    id_max_mem = rb_intern("max_mem");
    id_literal = rb_intern("literal");
    id_never_nl = rb_intern("never_nl");
    id_case_sensitive = rb_intern("case_sensitive");
    id_perl_classes = rb_intern("perl_classes");
    id_word_boundary = rb_intern("word_boundary");
    id_one_line = rb_intern("one_line");
  }
}
