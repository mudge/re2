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

  typedef struct {
    RE2 *pattern;
  } re2_pattern;

  typedef struct {
    re2::StringPiece *matches;
    int number_of_matches;
    VALUE regexp, string;
  } re2_matchdata;

  VALUE re2_mRE2, re2_cRegexp, re2_cMatchData;

  /* Symbols used in RE2 options. */
  static ID id_utf8, id_posix_syntax, id_longest_match, id_log_errors,
            id_max_mem, id_literal, id_never_nl, id_case_sensitive,
            id_perl_classes, id_word_boundary, id_one_line;

  void re2_matchdata_mark(re2_matchdata* self)
  {
    rb_gc_mark(self->regexp);
    rb_gc_mark(self->string);
  }

  void re2_matchdata_free(re2_matchdata* self)
  {
    if (self->matches) {
      delete[] self->matches;
    }
    free(self);
  }

  void
  re2_regexp_free(re2_pattern* self)
  {
    if (self->pattern) {
      delete self->pattern;
    }
    free(self);
  }

  static VALUE
  re2_matchdata_allocate(VALUE klass)
  {
    re2_matchdata *m;
    return Data_Make_Struct(klass, re2_matchdata, re2_matchdata_mark, re2_matchdata_free, m);
  }

  /*
   * call-seq:
   *   match.string  -> string
   *
   * Returns a frozen copy of the string passed into +match+.
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m.string  #=> "bob 123"
   */
  static VALUE
  re2_matchdata_string(VALUE self)
  {
    re2_matchdata *m;
    Data_Get_Struct(self, re2_matchdata, m);

    return m->string;
  }

  /*
   * call-seq:
   *   match.size    -> integer
   *   match.length  -> integer
   *
   * Returns the number of elements in the match array (including nils).
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m.length    #=> 2
   *   m.size      #=> 2
   */
  static VALUE
  re2_matchdata_size(VALUE self)
  {
    re2_matchdata *m;
    Data_Get_Struct(self, re2_matchdata, m);

    return INT2FIX(m->number_of_matches);
  }

  /*
   * call-seq:
   *   match.regexp   -> RE2::Regexp
   *
   * Return the RE2::Regexp used in the match.
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m.regexp    #=> #<RE2::Regexp /(\d+)/>
   */
  static VALUE
  re2_matchdata_regexp(VALUE self)
  {
    re2_matchdata *m;
    Data_Get_Struct(self, re2_matchdata, m);
    return m->regexp;
  }

  static VALUE
  re2_regexp_allocate(VALUE klass)
  {
    re2_pattern *p;
    return Data_Make_Struct(klass, re2_pattern, 0, re2_regexp_free, p);
  }

  /*
   * call-seq:
   *   match.to_a    -> array
   *
   * Returns the array of matches.
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m.to_a    #=> ["123", "123"]
   */
  static VALUE
  re2_matchdata_to_a(VALUE self)
  {
    int i;
    re2_matchdata *m;
    Data_Get_Struct(self, re2_matchdata, m);
    VALUE array = rb_ary_new2(m->number_of_matches);
    for (i = 0; i < m->number_of_matches; i++) {
      if (m->matches[i].empty()) {
        rb_ary_store(array, i, Qnil);
      } else {
        rb_ary_store(array, i, rb_str_new2(m->matches[i].as_string().c_str()));
      }
    }
    return array;
  }

  static VALUE
  re2_matchdata_nth_match(int nth, VALUE self)
  {
    re2_matchdata *m;
    Data_Get_Struct(self, re2_matchdata, m);

    if (nth >= m->number_of_matches || m->matches[nth].empty()) {
      return Qnil;
    } else {
      return rb_str_new2(m->matches[nth].as_string().c_str());
    }
  }

  /*
   * call-seq:
   *   match[i]              -> string
   *   match[start, length]  -> array
   *   match[range]          -> array
   *
   * Access the match data as an array.
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m[0]      #=> "123"
   *   m[0, 1]   #=> ["123"]
   *   m[0...1]  #=> ["123"]
   *   m[0..1]   #=> ["123", "123"]
   */
  static VALUE
  re2_matchdata_aref(int argc, VALUE *argv, VALUE self)
  {
    VALUE idx, rest;
    rb_scan_args(argc, argv, "11", &idx, &rest);

    if (!NIL_P(rest) || !FIXNUM_P(idx) || FIX2INT(idx) < 0) {
      return rb_ary_aref(argc, argv, re2_matchdata_to_a(self));
    } else {
      return re2_matchdata_nth_match(FIX2INT(idx), self);
    }
  }

  /*
   * call-seq:
   *   match.to_s    -> string
   *
   * Returns the entire matched string.
   */
  static VALUE
  re2_matchdata_to_s(VALUE self)
  {
    return re2_matchdata_nth_match(0, self);
  }

  /*
   * call-seq:
   *   match.inspect   -> string
   *
   * Returns a printable version of the match.
   *
   *   m = RE2('(\d+)').match("bob 123")
   *   m.inspect    #=> "#<RE2::MatchData \"123\" 1:\"123\">"
   */
  static VALUE
  re2_matchdata_inspect(VALUE self)
  {
    int i;
    re2_matchdata *m;
    VALUE match, result;

    Data_Get_Struct(self, re2_matchdata, m);

    result = rb_str_buf_new2("#<RE2::MatchData");

    for (i = 0; i < m->number_of_matches; i++) {
      rb_str_buf_cat2(result, " ");

      if (i > 0) {
        char buf[sizeof(i)*3+1];
        snprintf(buf, sizeof(buf), "%d", i);
        rb_str_buf_cat2(result, buf);
        rb_str_buf_cat2(result, ":");
      }

      match = re2_matchdata_nth_match(i, self);

      if (match == Qnil) {
        rb_str_buf_cat2(result, "nil");
      } else {
        rb_str_buf_append(result, rb_str_inspect(match));
      }
    }
    rb_str_buf_cat2(result, ">");

    return result;
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
    return rb_class_new_instance(argc, argv, re2_cRegexp);
  }

  /*
   * call-seq:
   *   RE2::Regexp.new(pattern)               -> re2
   *   RE2::Regexp.new(pattern, options)      -> re2
   *   RE2::Regexp.compile(pattern)           -> re2
   *   RE2::Regexp.compile(pattern, options)  -> re2
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
  re2_regexp_initialize(int argc, VALUE *argv, VALUE self)
  {
    VALUE pattern, options, utf8, posix_syntax, longest_match, log_errors,
          max_mem, literal, never_nl, case_sensitive, perl_classes, 
          word_boundary, one_line;
    re2_pattern *p;

    rb_scan_args(argc, argv, "11", &pattern, &options);
    Data_Get_Struct(self, re2_pattern, p);

    if (RTEST(options)) {
      if (TYPE(options) != T_HASH) {
        rb_raise(rb_eArgError, "options should be a hash");
      }

      RE2::Options re2_options;

      utf8 = rb_hash_aref(options, ID2SYM(id_utf8));
      if (!NIL_P(utf8)) {
        re2_options.set_utf8(RTEST(utf8));
      }

      posix_syntax = rb_hash_aref(options, ID2SYM(id_posix_syntax));
      if (!NIL_P(posix_syntax)) {
        re2_options.set_posix_syntax(RTEST(posix_syntax));
      }

      longest_match = rb_hash_aref(options, ID2SYM(id_longest_match));
      if (!NIL_P(longest_match)) {
        re2_options.set_longest_match(RTEST(longest_match));
      }

      log_errors = rb_hash_aref(options, ID2SYM(id_log_errors));
      if (!NIL_P(log_errors)) {
        re2_options.set_log_errors(RTEST(log_errors));
      }

      max_mem = rb_hash_aref(options, ID2SYM(id_max_mem));
      if (!NIL_P(max_mem)) {
        re2_options.set_max_mem(NUM2INT(max_mem));
      }

      literal = rb_hash_aref(options, ID2SYM(id_literal));
      if (!NIL_P(literal)) {
        re2_options.set_literal(RTEST(literal));
      }

      never_nl = rb_hash_aref(options, ID2SYM(id_never_nl));
      if (!NIL_P(never_nl)) {
        re2_options.set_never_nl(RTEST(never_nl));
      }

      case_sensitive = rb_hash_aref(options, ID2SYM(id_case_sensitive));
      if (!NIL_P(case_sensitive)) {
        re2_options.set_case_sensitive(RTEST(case_sensitive));
      }

      perl_classes = rb_hash_aref(options, ID2SYM(id_perl_classes));
      if (!NIL_P(perl_classes)) {
        re2_options.set_perl_classes(RTEST(perl_classes));
      }

      word_boundary = rb_hash_aref(options, ID2SYM(id_word_boundary));
      if (!NIL_P(word_boundary)) {
        re2_options.set_word_boundary(RTEST(word_boundary));
      }

      one_line = rb_hash_aref(options, ID2SYM(id_one_line));
      if (!NIL_P(one_line)) {
        re2_options.set_one_line(RTEST(one_line));
      }

      p->pattern = new (std::nothrow) RE2(StringValuePtr(pattern), re2_options);
    } else {
      p->pattern = new (std::nothrow) RE2(StringValuePtr(pattern));
    }

    if (p->pattern == 0) {
      rb_raise(rb_eNoMemError, "not enough memory to allocate RE2 object");
    }

    return self;
  }

  /*
   * call-seq:
   *   re2.inspect   -> string
   *
   * Returns a printable version of the regular expression +re2+.
   *
   *   re2 = RE2::Regexp.new("woo?")
   *   re2.inspect    #=> "#<RE2::Regexp /woo?/>"
   */
  static VALUE
  re2_regexp_inspect(VALUE self)
  {
    re2_pattern *p;
    VALUE result = rb_str_buf_new2("#<RE2::Regexp /");

    Data_Get_Struct(self, re2_pattern, p);
    rb_str_buf_cat2(result, p->pattern->pattern().c_str());
    rb_str_buf_cat2(result, "/>");

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
   *   re2 = RE2::Regexp.new("woo?")
   *   re2.to_s    #=> "woo?"
   */
  static VALUE
  re2_regexp_to_s(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?")
   *   re2.ok?    #=> true
   */
  static VALUE
  re2_regexp_ok(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :utf8 => true)
   *   re2.utf8?    #=> true
   */
  static VALUE
  re2_regexp_utf8(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :posix_syntax => true)
   *   re2.posix_syntax?    #=> true
   */
  static VALUE
  re2_regexp_posix_syntax(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :longest_match => true)
   *   re2.longest_match?    #=> true
   */
  static VALUE
  re2_regexp_longest_match(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :log_errors => true)
   *   re2.log_errors?    #=> true
   */
  static VALUE
  re2_regexp_log_errors(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :max_mem => 1024)
   *   re2.max_mem    #=> 1024
   */
  static VALUE
  re2_regexp_max_mem(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :literal => true)
   *   re2.literal?    #=> true
   */
  static VALUE
  re2_regexp_literal(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :never_nl => true)
   *   re2.never_nl?    #=> true
   */
  static VALUE
  re2_regexp_never_nl(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :case_sensitive => true)
   *   re2.case_sensitive?    #=> true
   */
  static VALUE
  re2_regexp_case_sensitive(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :case_sensitive => true)
   *   re2.case_insensitive?    #=> false
   */
  static VALUE
  re2_regexp_case_insensitive(VALUE self)
  {
    return BOOL2RUBY(re2_regexp_case_sensitive(self) != Qtrue);
  }

  /*
   * call-seq:
   *   re2.perl_classes?    -> true or false
   *
   * Returns whether or not the regular expression +re2+
   * was compiled with the perl_classes option set to true.
   *
   *   re2 = RE2::Regexp.new("woo?", :perl_classes => true)
   *   re2.perl_classes?    #=> true
   */
  static VALUE
  re2_regexp_perl_classes(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :word_boundary => true)
   *   re2.word_boundary?    #=> true
   */
  static VALUE
  re2_regexp_word_boundary(VALUE self)
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
   *   re2 = RE2::Regexp.new("woo?", :one_line => true)
   *   re2.one_line?    #=> true
   */
  static VALUE
  re2_regexp_one_line(VALUE self)
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
  re2_regexp_error(VALUE self)
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
  re2_regexp_error_arg(VALUE self)
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
  re2_regexp_program_size(VALUE self)
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
  re2_regexp_options(VALUE self)
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
  re2_regexp_number_of_capturing_groups(VALUE self)
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
   *   r = RE2::Regexp.new('w(o)(o)')
   *   r.match('woo')    #=> ["woo", "o", "o"]
   *   r.match('woo', 0) #=> true
   *   r.match('bob', 0) #=> false
   *   r.match('woo', 1) #=> ["woo", "o"]
   */
  static VALUE
  re2_regexp_match(int argc, VALUE *argv, VALUE self)
  {
    int n;
    bool matched;
    re2_pattern *p;
    re2_matchdata *m;
    VALUE text, number_of_matches, matchdata;

    rb_scan_args(argc, argv, "11", &text, &number_of_matches);

    Data_Get_Struct(self, re2_pattern, p);

    if (RTEST(number_of_matches)) {
      n = NUM2INT(number_of_matches);
    } else {
      n = p->pattern->NumberOfCapturingGroups();
    }

    re2::StringPiece text_as_string_piece(StringValuePtr(text));

    if (n == 0) {
      matched = p->pattern->Match(text_as_string_piece, 0, RE2::UNANCHORED, 0, 0);
      return BOOL2RUBY(matched);
    } else {

      /* Because match returns the whole match as well. */
      n += 1;

      matchdata = rb_class_new_instance(0, 0, re2_cMatchData);
      Data_Get_Struct(matchdata, re2_matchdata, m);
      m->matches = new (std::nothrow) re2::StringPiece[n];
      m->regexp = self;
      m->string = rb_str_dup_frozen(text);

      if (m->matches == 0) {
        rb_raise(rb_eNoMemError, "not enough memory to allocate StringPieces for matches");
      }

      m->number_of_matches = n;

      matched = p->pattern->Match(text_as_string_piece, 0, RE2::UNANCHORED, m->matches, n);

      if (matched) {
        return matchdata;
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
  re2_regexp_match_query(VALUE self, VALUE text)
  {
    VALUE argv[2];
    argv[0] = text;
    argv[1] = INT2FIX(0);

    return re2_regexp_match(2, argv, self);
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
    if (rb_obj_is_kind_of(pattern, re2_cRegexp)) {
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
    if (rb_obj_is_kind_of(pattern, re2_cRegexp)) {
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
   *   RE2::Regexp.escape(str)        -> str
   *   RE2::Regexp.quote(str)         -> str
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
    re2_mRE2 = rb_define_module("RE2");
    re2_cRegexp = rb_define_class_under(re2_mRE2, "Regexp", rb_cObject);
    re2_cMatchData = rb_define_class_under(re2_mRE2, "MatchData", rb_cObject);

    rb_define_alloc_func(re2_cRegexp, (VALUE (*)(VALUE))re2_regexp_allocate);
    rb_define_alloc_func(re2_cMatchData, (VALUE (*)(VALUE))re2_matchdata_allocate);

    rb_define_method(re2_cMatchData, "string", (VALUE (*)(...))re2_matchdata_string, 0);
    rb_define_method(re2_cMatchData, "regexp", (VALUE (*)(...))re2_matchdata_regexp, 0);
    rb_define_method(re2_cMatchData, "to_a", (VALUE (*)(...))re2_matchdata_to_a, 0);
    rb_define_method(re2_cMatchData, "size", (VALUE (*)(...))re2_matchdata_size, 0);
    rb_define_method(re2_cMatchData, "length", (VALUE (*)(...))re2_matchdata_size, 0);
    rb_define_method(re2_cMatchData, "[]", (VALUE (*)(...))re2_matchdata_aref, -1);
    rb_define_method(re2_cMatchData, "to_s", (VALUE (*)(...))re2_matchdata_to_s, 0);
    rb_define_method(re2_cMatchData, "inspect", (VALUE (*)(...))re2_matchdata_inspect, 0);

    rb_define_method(re2_cRegexp, "initialize", (VALUE (*)(...))re2_regexp_initialize, -1);
    rb_define_method(re2_cRegexp, "ok?", (VALUE (*)(...))re2_regexp_ok, 0);
    rb_define_method(re2_cRegexp, "error", (VALUE (*)(...))re2_regexp_error, 0);
    rb_define_method(re2_cRegexp, "error_arg", (VALUE (*)(...))re2_regexp_error_arg, 0);
    rb_define_method(re2_cRegexp, "program_size", (VALUE (*)(...))re2_regexp_program_size, 0);
    rb_define_method(re2_cRegexp, "options", (VALUE (*)(...))re2_regexp_options, 0);
    rb_define_method(re2_cRegexp, "number_of_capturing_groups", (VALUE (*)(...))re2_regexp_number_of_capturing_groups, 0);
    rb_define_method(re2_cRegexp, "match", (VALUE (*)(...))re2_regexp_match, -1);
    rb_define_method(re2_cRegexp, "match?", (VALUE (*)(...))re2_regexp_match_query, 1);
    rb_define_method(re2_cRegexp, "=~", (VALUE (*)(...))re2_regexp_match_query, 1);
    rb_define_method(re2_cRegexp, "===", (VALUE (*)(...))re2_regexp_match_query, 1);
    rb_define_method(re2_cRegexp, "to_s", (VALUE (*)(...))re2_regexp_to_s, 0);
    rb_define_method(re2_cRegexp, "to_str", (VALUE (*)(...))re2_regexp_to_s, 0);
    rb_define_method(re2_cRegexp, "pattern", (VALUE (*)(...))re2_regexp_to_s, 0);
    rb_define_method(re2_cRegexp, "source", (VALUE (*)(...))re2_regexp_to_s, 0);
    rb_define_method(re2_cRegexp, "inspect", (VALUE (*)(...))re2_regexp_inspect, 0);
    rb_define_method(re2_cRegexp, "utf8?", (VALUE (*)(...))re2_regexp_utf8, 0);
    rb_define_method(re2_cRegexp, "posix_syntax?", (VALUE (*)(...))re2_regexp_posix_syntax, 0);
    rb_define_method(re2_cRegexp, "longest_match?", (VALUE (*)(...))re2_regexp_longest_match, 0);
    rb_define_method(re2_cRegexp, "log_errors?", (VALUE (*)(...))re2_regexp_log_errors, 0);
    rb_define_method(re2_cRegexp, "max_mem", (VALUE (*)(...))re2_regexp_max_mem, 0);
    rb_define_method(re2_cRegexp, "literal?", (VALUE (*)(...))re2_regexp_literal, 0);
    rb_define_method(re2_cRegexp, "never_nl?", (VALUE (*)(...))re2_regexp_never_nl, 0);
    rb_define_method(re2_cRegexp, "case_sensitive?", (VALUE (*)(...))re2_regexp_case_sensitive, 0);
    rb_define_method(re2_cRegexp, "case_insensitive?", (VALUE (*)(...))re2_regexp_case_insensitive, 0);
    rb_define_method(re2_cRegexp, "casefold?", (VALUE (*)(...))re2_regexp_case_insensitive, 0);
    rb_define_method(re2_cRegexp, "perl_classes?", (VALUE (*)(...))re2_regexp_perl_classes, 0);
    rb_define_method(re2_cRegexp, "word_boundary?", (VALUE (*)(...))re2_regexp_word_boundary, 0);
    rb_define_method(re2_cRegexp, "one_line?", (VALUE (*)(...))re2_regexp_one_line, 0);

    rb_define_module_function(re2_mRE2, "Replace", (VALUE (*)(...))re2_Replace, 3);
    rb_define_module_function(re2_mRE2, "GlobalReplace", (VALUE (*)(...))re2_GlobalReplace, 3);
    rb_define_module_function(re2_mRE2, "QuoteMeta", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRegexp, "escape", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRegexp, "quote", (VALUE (*)(...))re2_QuoteMeta, 1);
    rb_define_singleton_method(re2_cRegexp, "compile", (VALUE (*)(...))rb_class_new_instance, -1);

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
