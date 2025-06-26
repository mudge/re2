/*
 * re2 (https://github.com/mudge/re2)
 * Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
 * backtracking regular expression engines like those used in PCRE, Perl, and
 * Python".
 *
 * Copyright (c) 2010, Paul Mucur (https://mudge.name)
 * Released under the BSD Licence, please see LICENSE.txt
 */

#include <stdint.h>

#include <map>
#include <sstream>
#include <string>
#include <vector>

#include <re2/re2.h>
#include <re2/set.h>
#include <ruby.h>
#include <ruby/encoding.h>

#define BOOL2RUBY(v) (v ? Qtrue : Qfalse)

typedef struct {
  RE2 *pattern;
} re2_pattern;

typedef struct {
  re2::StringPiece *matches;
  int number_of_matches;
  VALUE regexp, text;
} re2_matchdata;

typedef struct {
  re2::StringPiece *input;
  int number_of_capturing_groups;
  bool eof;
  VALUE regexp, text;
} re2_scanner;

typedef struct {
  RE2::Set *set;
} re2_set;

VALUE re2_mRE2, re2_cRegexp, re2_cMatchData, re2_cScanner, re2_cSet,
      re2_eSetMatchError, re2_eSetUnsupportedError, re2_eRegexpUnsupportedError;

/* Symbols used in RE2 options. */
static ID id_utf8, id_posix_syntax, id_longest_match, id_log_errors,
          id_max_mem, id_literal, id_never_nl, id_case_sensitive,
          id_perl_classes, id_word_boundary, id_one_line, id_unanchored,
          id_anchor, id_anchor_start, id_anchor_both, id_exception,
          id_submatches, id_startpos, id_endpos;

inline VALUE encoded_str_new(const char *str, long length, RE2::Options::Encoding encoding) {
  if (encoding == RE2::Options::EncodingUTF8) {
    return rb_utf8_str_new(str, length);
  }

  VALUE string = rb_str_new(str, length);
  rb_enc_associate_index(string, rb_enc_find_index("ISO-8859-1"));

  return string;
}

static void parse_re2_options(RE2::Options* re2_options, const VALUE options) {
  if (TYPE(options) != T_HASH) {
    rb_raise(rb_eArgError, "options should be a hash");
  }

  VALUE utf8 = rb_hash_aref(options, ID2SYM(id_utf8));
  if (!NIL_P(utf8)) {
    re2_options->set_encoding(RTEST(utf8) ? RE2::Options::EncodingUTF8 : RE2::Options::EncodingLatin1);
  }

  VALUE posix_syntax = rb_hash_aref(options, ID2SYM(id_posix_syntax));
  if (!NIL_P(posix_syntax)) {
    re2_options->set_posix_syntax(RTEST(posix_syntax));
  }

  VALUE longest_match = rb_hash_aref(options, ID2SYM(id_longest_match));
  if (!NIL_P(longest_match)) {
    re2_options->set_longest_match(RTEST(longest_match));
  }

  VALUE log_errors = rb_hash_aref(options, ID2SYM(id_log_errors));
  if (!NIL_P(log_errors)) {
    re2_options->set_log_errors(RTEST(log_errors));
  }

  VALUE max_mem = rb_hash_aref(options, ID2SYM(id_max_mem));
  if (!NIL_P(max_mem)) {
    re2_options->set_max_mem(NUM2INT(max_mem));
  }

  VALUE literal = rb_hash_aref(options, ID2SYM(id_literal));
  if (!NIL_P(literal)) {
    re2_options->set_literal(RTEST(literal));
  }

  VALUE never_nl = rb_hash_aref(options, ID2SYM(id_never_nl));
  if (!NIL_P(never_nl)) {
    re2_options->set_never_nl(RTEST(never_nl));
  }

  VALUE case_sensitive = rb_hash_aref(options, ID2SYM(id_case_sensitive));
  if (!NIL_P(case_sensitive)) {
    re2_options->set_case_sensitive(RTEST(case_sensitive));
  }

  VALUE perl_classes = rb_hash_aref(options, ID2SYM(id_perl_classes));
  if (!NIL_P(perl_classes)) {
    re2_options->set_perl_classes(RTEST(perl_classes));
  }

  VALUE word_boundary = rb_hash_aref(options, ID2SYM(id_word_boundary));
  if (!NIL_P(word_boundary)) {
    re2_options->set_word_boundary(RTEST(word_boundary));
  }

  VALUE one_line = rb_hash_aref(options, ID2SYM(id_one_line));
  if (!NIL_P(one_line)) {
    re2_options->set_one_line(RTEST(one_line));
  }
}

/* For compatibility with Ruby < 2.7 */
#ifdef HAVE_RB_GC_MARK_MOVABLE
#define re2_compact_callback(x) (x),
#else
#define rb_gc_mark_movable(x) rb_gc_mark(x)
#define re2_compact_callback(x)
#endif

static void re2_matchdata_mark(void *ptr) {
  re2_matchdata *m = reinterpret_cast<re2_matchdata *>(ptr);
  rb_gc_mark_movable(m->regexp);
  rb_gc_mark_movable(m->text);
}

#ifdef HAVE_RB_GC_MARK_MOVABLE
static void re2_matchdata_compact(void *ptr) {
  re2_matchdata *m = reinterpret_cast<re2_matchdata *>(ptr);
  m->regexp = rb_gc_location(m->regexp);
  m->text = rb_gc_location(m->text);
}
#endif

static void re2_matchdata_free(void *ptr) {
  re2_matchdata *m = reinterpret_cast<re2_matchdata *>(ptr);
  if (m->matches) {
    delete[] m->matches;
  }
  xfree(m);
}

static size_t re2_matchdata_memsize(const void *ptr) {
  const re2_matchdata *m = reinterpret_cast<const re2_matchdata *>(ptr);
  size_t size = sizeof(*m);
  if (m->matches) {
    size += sizeof(*m->matches) * m->number_of_matches;
  }

  return size;
}

static const rb_data_type_t re2_matchdata_data_type = {
  "RE2::MatchData",
  {
    re2_matchdata_mark,
    re2_matchdata_free,
    re2_matchdata_memsize,
    re2_compact_callback(re2_matchdata_compact)
  },
  0,
  0,
  // IMPORTANT: WB_PROTECTED objects must only use the RB_OBJ_WRITE()
  // macro to update VALUE references, as to trigger write barriers.
  RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static void re2_scanner_mark(void *ptr) {
  re2_scanner *s = reinterpret_cast<re2_scanner *>(ptr);
  rb_gc_mark_movable(s->regexp);
  rb_gc_mark_movable(s->text);
}

#ifdef HAVE_RB_GC_MARK_MOVABLE
static void re2_scanner_compact(void *ptr) {
  re2_scanner *s = reinterpret_cast<re2_scanner *>(ptr);
  s->regexp = rb_gc_location(s->regexp);
  s->text = rb_gc_location(s->text);
}
#endif

static void re2_scanner_free(void *ptr) {
  re2_scanner *s = reinterpret_cast<re2_scanner *>(ptr);
  if (s->input) {
    delete s->input;
  }
  xfree(s);
}

static size_t re2_scanner_memsize(const void *ptr) {
  const re2_scanner *s = reinterpret_cast<const re2_scanner *>(ptr);
  size_t size = sizeof(*s);
  if (s->input) {
    size += sizeof(*s->input);
  }

  return size;
}

static const rb_data_type_t re2_scanner_data_type = {
  "RE2::Scanner",
  {
    re2_scanner_mark,
    re2_scanner_free,
    re2_scanner_memsize,
    re2_compact_callback(re2_scanner_compact)
  },
  0,
  0,
  // IMPORTANT: WB_PROTECTED objects must only use the RB_OBJ_WRITE()
  // macro to update VALUE references, as to trigger write barriers.
  RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static void re2_regexp_free(void *ptr) {
  re2_pattern *p = reinterpret_cast<re2_pattern *>(ptr);
  if (p->pattern) {
    delete p->pattern;
  }
  xfree(p);
}

static size_t re2_regexp_memsize(const void *ptr) {
  const re2_pattern *p = reinterpret_cast<const re2_pattern *>(ptr);
  size_t size = sizeof(*p);
  if (p->pattern) {
    size += sizeof(*p->pattern);
  }

  return size;
}

static const rb_data_type_t re2_regexp_data_type = {
  "RE2::Regexp",
  {
    0,
    re2_regexp_free,
    re2_regexp_memsize,
  },
  0,
  0,
  // IMPORTANT: WB_PROTECTED objects must only use the RB_OBJ_WRITE()
  // macro to update VALUE references, as to trigger write barriers.
  RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static VALUE re2_matchdata_allocate(VALUE klass) {
  re2_matchdata *m;

  return TypedData_Make_Struct(klass, re2_matchdata, &re2_matchdata_data_type,
      m);
}

static VALUE re2_scanner_allocate(VALUE klass) {
  re2_scanner *c;

  return TypedData_Make_Struct(klass, re2_scanner, &re2_scanner_data_type, c);
}

/*
 * Returns a frozen copy of the text supplied when matching.
 *
 * If the text was already a frozen string, returns the original.
 *
 * @return [String] a frozen string with the text supplied when matching
 * @example
 *   m = RE2::Regexp.new('(\d+)').partial_match("bob 123")
 *   m.string #=> "bob 123"
 */
static VALUE re2_matchdata_string(const VALUE self) {
  re2_matchdata *m;
  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);

  return m->text;
}

/*
 * Returns the text supplied when incrementally matching with
 * {RE2::Regexp#scan}.
 *
 * @return [String] the original string passed to {RE2::Regexp#scan}
 * @example
 *   c = RE2::Regexp.new('(\d+)').scan("foo")
 *   c.string #=> "foo"
 */
static VALUE re2_scanner_string(const VALUE self) {
  re2_scanner *c;
  TypedData_Get_Struct(self, re2_scanner, &re2_scanner_data_type, c);

  return c->text;
}

/*
 * Returns whether the {RE2::Scanner} has consumed all input or not.
 *
 * @return [Boolean] whether the {RE2::Scanner} has consumed all input or not
 * @example
 *   c = RE2::Regexp.new('(\d+)').scan("foo")
 *   c.eof? #=> true
 */
static VALUE re2_scanner_eof(const VALUE self) {
  re2_scanner *c;
  TypedData_Get_Struct(self, re2_scanner, &re2_scanner_data_type, c);

  return BOOL2RUBY(c->eof);
}

/*
 * Rewind the {RE2::Scanner} to the start of the string.
 *
 * @example
 *   s = RE2::Regexp.new('(\d+)').scan("1 2 3")
 *   e = s.to_enum
 *   e.scan #=> ["1"]
 *   e.scan #=> ["2"]
 *   s.rewind
 *   e.scan #=> ["1"]
 */
static VALUE re2_scanner_rewind(VALUE self) {
  re2_scanner *c;
  TypedData_Get_Struct(self, re2_scanner, &re2_scanner_data_type, c);

  delete c->input;
  c->input = new(std::nothrow) re2::StringPiece(
      RSTRING_PTR(c->text), RSTRING_LEN(c->text));
  c->eof = false;

  return self;
}

/*
 * Scan the given text incrementally for matches using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L447-L463
 * `FindAndConsume`}, returning an array of submatches on each subsequent
 * call. Returns `nil` if no matches are found or an empty array for every
 * match if the pattern has no capturing groups.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [Array<String>] if the pattern has capturing groups
 * @return [[]] if the pattern does not have capturing groups
 * @return [nil] if no matches are found
 * @example
 *   s = RE2::Regexp.new('(\w+)').scan("Foo bar baz")
 *   s.scan #=> ["Foo"]
 *   s.scan #=> ["bar"]
 */
static VALUE re2_scanner_scan(VALUE self) {
  re2_pattern *p;
  re2_scanner *c;

  TypedData_Get_Struct(self, re2_scanner, &re2_scanner_data_type, c);
  TypedData_Get_Struct(c->regexp, re2_pattern, &re2_regexp_data_type, p);

  std::vector<RE2::Arg> argv(c->number_of_capturing_groups);
  std::vector<RE2::Arg*> args(c->number_of_capturing_groups);
  std::vector<re2::StringPiece> matches(c->number_of_capturing_groups);

  if (c->eof) {
    return Qnil;
  }

  re2::StringPiece::size_type original_input_size = c->input->size();

  for (int i = 0; i < c->number_of_capturing_groups; ++i) {
    argv[i] = &matches[i];
    args[i] = &argv[i];
  }

  if (RE2::FindAndConsumeN(c->input, *p->pattern, args.data(),
        c->number_of_capturing_groups)) {
    re2::StringPiece::size_type new_input_size = c->input->size();
    bool input_advanced = new_input_size < original_input_size;

    VALUE result = rb_ary_new2(c->number_of_capturing_groups);

    for (int i = 0; i < c->number_of_capturing_groups; ++i) {
      if (matches[i].empty()) {
        rb_ary_push(result, Qnil);
      } else {
        rb_ary_push(result, encoded_str_new(matches[i].data(),
              matches[i].size(),
              p->pattern->options().encoding()));
      }
    }

    /* Check whether we've exhausted the input yet. */
    c->eof = new_input_size == 0;

    /* If the match didn't advance the input, we need to do this ourselves. */
    if (!input_advanced && new_input_size > 0) {
      c->input->remove_prefix(1);
    }

    return result;
  } else {
    return Qnil;
  }
}

static re2::StringPiece *re2_matchdata_find_match(VALUE idx, const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  int id;

  if (FIXNUM_P(idx)) {
    id = FIX2INT(idx);
  } else if (SYMBOL_P(idx)) {
    const std::map<std::string, int>& groups = p->pattern->NamedCapturingGroups();
    std::map<std::string, int>::const_iterator search = groups.find(rb_id2name(SYM2ID(idx)));

    if (search != groups.end()) {
      id = search->second;
    } else {
      return NULL;
    }
  } else {
    StringValue(idx);

    const std::map<std::string, int>& groups = p->pattern->NamedCapturingGroups();
    std::map<std::string, int>::const_iterator search = groups.find(std::string(RSTRING_PTR(idx), RSTRING_LEN(idx)));

    if (search != groups.end()) {
      id = search->second;
    } else {
      return NULL;
    }
  }

  if (id >= 0 && id < m->number_of_matches) {
    re2::StringPiece *match = &m->matches[id];

    if (!match->empty()) {
      return match;
    }
  }

  return NULL;
}

/*
 * Returns the number of elements in the {RE2::MatchData} (including the
 * overall match, submatches and any `nils`).
 *
 * @return [Integer] the number of elements
 * @example
 *   m = RE2::Regexp.new('(\d+)').match("bob 123")
 *   m.size   #=> 2
 *   m.length #=> 2
 */
static VALUE re2_matchdata_size(const VALUE self) {
  re2_matchdata *m;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);

  return INT2FIX(m->number_of_matches);
}

/*
 * Returns the offset of the start of the nth element of the {RE2::MatchData}.
 *
 * @param [Integer, String, Symbol] n the name or number of the submatch
 * @return [Integer, nil] the offset of the start of the match or `nil` if
 *   there is no such submatch
 * @example
 *   m = RE2::Regexp.new('ob (\d+)').match("bob 123")
 *   m.begin(0) #=> 1
 *   m.begin(1) #=> 4
 */
static VALUE re2_matchdata_begin(const VALUE self, VALUE n) {
  re2_matchdata *m;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);

  re2::StringPiece *match = re2_matchdata_find_match(n, self);
  if (match == NULL) {
    return Qnil;
  } else {
    long offset = match->data() - RSTRING_PTR(m->text);

    return LONG2NUM(rb_str_sublen(m->text, offset));
  }
}

/*
 * Returns the offset of the character following the end of the nth element of
 * the {RE2::MatchData}.
 *
 * @param [Integer, String, Symbol] n the name or number of the match
 * @return [Integer, nil] the offset of the character following the end of the
 *   match or `nil` if there is no such match
 * @example
 *   m = RE2::Regexp.new('ob (\d+) b').match("bob 123 bob")
 *   m.end(0) #=> 9
 *   m.end(1) #=> 7
 */
static VALUE re2_matchdata_end(const VALUE self, VALUE n) {
  re2_matchdata *m;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);

  re2::StringPiece *match = re2_matchdata_find_match(n, self);
  if (match == NULL) {
    return Qnil;
  } else {
    long offset = (match->data() - RSTRING_PTR(m->text)) + match->size();

    return LONG2NUM(rb_str_sublen(m->text, offset));
  }
}

/*
 * Returns the {RE2::Regexp} used in the match.
 *
 * @return [RE2::Regexp] the regular expression used in the match
 * @example
 *   m = RE2::Regexp.new('(\d+)').match("bob 123")
 *   m.regexp #=> #<RE2::Regexp /(\d+)/>
 */
static VALUE re2_matchdata_regexp(const VALUE self) {
  re2_matchdata *m;
  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);

  return m->regexp;
}

/*
 * Returns the {RE2::Regexp} used in the {RE2::Scanner}.
 *
 * @return [RE2::Regexp] the regular expression used in the {RE2::Scanner}
 * @example
 *   c = RE2::Regexp.new('(\d+)').scan("bob 123")
 *   c.regexp #=> #<RE2::Regexp /(\d+)/>
 */
static VALUE re2_scanner_regexp(const VALUE self) {
  re2_scanner *c;
  TypedData_Get_Struct(self, re2_scanner, &re2_scanner_data_type, c);

  return c->regexp;
}

static VALUE re2_regexp_allocate(VALUE klass) {
  re2_pattern *p;

  return TypedData_Make_Struct(klass, re2_pattern, &re2_regexp_data_type, p);
}

/*
 * Returns the array of matches including the overall match, submatches and any
 * `nil`s.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [Array<String, nil>] the array of matches
 * @example
 *   m = RE2::Regexp.new('(\d+)').match("bob 123")
 *   m.to_a #=> ["123", "123"]
 */
static VALUE re2_matchdata_to_a(const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  VALUE array = rb_ary_new2(m->number_of_matches);
  for (int i = 0; i < m->number_of_matches; ++i) {
    re2::StringPiece *match = &m->matches[i];

    if (match->empty()) {
      rb_ary_push(array, Qnil);
    } else {
      rb_ary_push(array, encoded_str_new(match->data(), match->size(),
            p->pattern->options().encoding()));
    }
  }

  return array;
}

static VALUE re2_matchdata_nth_match(int nth, const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  if (nth < 0 || nth >= m->number_of_matches) {
    return Qnil;
  } else {
    re2::StringPiece *match = &m->matches[nth];

    if (match->empty()) {
      return Qnil;
    } else {
      return encoded_str_new(match->data(), match->size(),
          p->pattern->options().encoding());
    }
  }
}

static VALUE re2_matchdata_named_match(const std::string &name, const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  const std::map<std::string, int>& groups = p->pattern->NamedCapturingGroups();
  std::map<std::string, int>::const_iterator search = groups.find(name);

  if (search != groups.end()) {
    return re2_matchdata_nth_match(search->second, self);
  } else {
    return Qnil;
  }
}

/*
 * Retrieve zero, one or more matches by index or name.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @overload [](index)
 *   Access a particular match by index.
 *
 *   @param [Integer] index the index of the match to fetch
 *   @return [String, nil] the specified match or `nil` if it isn't present
 *   @example
 *     m = RE2::Regexp.new('(\d+)').match("bob 123")
 *     m[0] #=> "123"
 *
 * @overload [](start, length)
 *   Access a range of matches by starting index and length.
 *
 *   @param [Integer] start the index from which to start
 *   @param [Integer] length the number of elements to fetch
 *   @return [Array<String, nil>] the specified matches
 *   @example
 *     m = RE2::Regexp.new('(\d+)').match("bob 123")
 *     m[0, 1] #=> ["123"]
 *
 * @overload [](range)
 *   Access a range of matches by index.
 *
 *   @param [Range] range the range of match indexes to fetch
 *   @return [Array<String, nil>] the specified matches
 *   @example
 *     m = RE2::Regexp.new('(\d+)').match("bob 123")
 *     m[0..1] #=> "[123", "123"]
 *
 * @overload [](name)
 *   Access a particular match by name.
 *
 *   @param [String, Symbol] name the name of the match to fetch
 *   @return [String, nil] the specific match or `nil` if it isn't present
 *   @example
 *     m = RE2::Regexp.new('(?P<number>\d+)').match("bob 123")
 *     m["number"] #=> "123"
 *     m[:number]  #=> "123"
 */
static VALUE re2_matchdata_aref(int argc, VALUE *argv, const VALUE self) {
  VALUE idx, rest;
  rb_scan_args(argc, argv, "11", &idx, &rest);

  if (TYPE(idx) == T_STRING) {
    return re2_matchdata_named_match(
        std::string(RSTRING_PTR(idx), RSTRING_LEN(idx)), self);
  } else if (SYMBOL_P(idx)) {
    return re2_matchdata_named_match(rb_id2name(SYM2ID(idx)), self);
  } else if (!NIL_P(rest) || !FIXNUM_P(idx) || FIX2INT(idx) < 0) {
    return rb_ary_aref(argc, argv, re2_matchdata_to_a(self));
  } else {
    return re2_matchdata_nth_match(FIX2INT(idx), self);
  }
}

/*
 * Returns the entire matched string.
 *
 * @return [String] the entire matched string
 */
static VALUE re2_matchdata_to_s(const VALUE self) {
  return re2_matchdata_nth_match(0, self);
}

/*
 * Returns a printable version of the match.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [String] a printable version of the match
 * @example
 *   m = RE2::Regexp.new('(\d+)').match("bob 123")
 *   m.inspect #=> "#<RE2::MatchData \"123\" 1:\"123\">"
 */
static VALUE re2_matchdata_inspect(const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  std::ostringstream output;
  output << "#<RE2::MatchData";

  for (int i = 0; i < m->number_of_matches; ++i) {
    output << " ";

    if (i > 0) {
      output << i << ":";
    }

    VALUE match = re2_matchdata_nth_match(i, self);

    if (match == Qnil) {
      output << "nil";
    } else {
      output << "\"";
      output.write(RSTRING_PTR(match), RSTRING_LEN(match));
      output << "\"";
    }
  }

  output << ">";

  return encoded_str_new(output.str().data(), output.str().length(),
      p->pattern->options().encoding());
}

/*
 * Returns the array of submatches for pattern matching.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is
 * undefined).
 *
 * @return [Array<String, nil>] the array of submatches
 * @example
 *   m = RE2::Regexp.new('(\d+)').match("bob 123")
 *   m.deconstruct #=> ["123"]
 *
 * @example pattern matching
 *   case RE2::Regexp.new('(\d+) (\d+)').match("bob 123 456")
 *   in x, y
 *     puts "Matched #{x} #{y}"
 *   else
 *     puts "Unrecognised match"
 *   end
 */
static VALUE re2_matchdata_deconstruct(const VALUE self) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  VALUE array = rb_ary_new2(m->number_of_matches - 1);
  for (int i = 1; i < m->number_of_matches; ++i) {
    re2::StringPiece *match = &m->matches[i];

    if (match->empty()) {
      rb_ary_push(array, Qnil);
    } else {
      rb_ary_push(array, encoded_str_new(match->data(), match->size(),
            p->pattern->options().encoding()));
    }
  }

  return array;
}

/*
 * Returns a hash of capturing group names to submatches for pattern matching.
 *
 * As this is used by Ruby's pattern matching, it will return an empty hash if given
 * more keys than there are capturing groups. Given keys will populate the hash in
 * order but an invalid name will cause the hash to be immediately returned.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [Hash] a hash of capturing group names to submatches
 * @param [Array<Symbol>, nil] keys an array of `Symbol` capturing group names
 *   or `nil` to return all names
 * @example
 *   m = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')
 *   m.deconstruct_keys(nil)                #=> {numbers: "123", letters: "abc"}
 *   m.deconstruct_keys([:numbers])         #=> {numbers: "123"}
 *   m.deconstruct_keys([:fruit])           #=> {}
 *   m.deconstruct_keys([:letters, :fruit]) #=> {letters: "abc"}
 *
 * @example pattern matching
 *   case RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')
 *   in numbers:, letters:
 *     puts "Numbers: #{numbers}, letters: #{letters}"
 *   else
 *     puts "Unrecognised match"
 *   end
 */
static VALUE re2_matchdata_deconstruct_keys(const VALUE self, const VALUE keys) {
  re2_matchdata *m;
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_matchdata, &re2_matchdata_data_type, m);
  TypedData_Get_Struct(m->regexp, re2_pattern, &re2_regexp_data_type, p);

  const std::map<std::string, int>& groups = p->pattern->NamedCapturingGroups();
  VALUE capturing_groups = rb_hash_new();

  if (NIL_P(keys)) {
    for (std::map<std::string, int>::const_iterator it = groups.begin(); it != groups.end(); ++it) {
      rb_hash_aset(capturing_groups,
          ID2SYM(rb_intern(it->first.data())),
          re2_matchdata_nth_match(it->second, self));
    }
  } else {
    Check_Type(keys, T_ARRAY);

    if (p->pattern->NumberOfCapturingGroups() >= RARRAY_LEN(keys)) {
      for (int i = 0; i < RARRAY_LEN(keys); ++i) {
        VALUE key = rb_ary_entry(keys, i);
        Check_Type(key, T_SYMBOL);
        const char *name = rb_id2name(SYM2ID(key));
        std::map<std::string, int>::const_iterator search = groups.find(name);

        if (search != groups.end()) {
          rb_hash_aset(capturing_groups, key, re2_matchdata_nth_match(search->second, self));
        } else {
          break;
        }
      }
    }
  }

  return capturing_groups;
}

/*
 * Shorthand to compile a new {RE2::Regexp}.
 *
 * @see RE2::Regexp#initialize
 */
static VALUE re2_re2(int argc, VALUE *argv, VALUE) {
  return rb_class_new_instance(argc, argv, re2_cRegexp);
}

/*
 * Returns a new {RE2::Regexp} object with a compiled version of
 * `pattern` stored inside.
 *
 * @overload initialize(pattern)
 *   Returns a new {RE2::Regexp} object with a compiled version of
 *   `pattern` stored inside with the default options.
 *
 *   @param [String] pattern the pattern to compile
 *   @return [RE2::Regexp] a {RE2::Regexp} with the specified pattern
 *   @raise [TypeError] if the given pattern can't be coerced to a `String`
 *   @raise [NoMemoryError] if memory could not be allocated for the compiled
 *     pattern
 *
 * @overload initialize(pattern, options)
 *   Returns a new {RE2::Regexp} object with a compiled version of
 *   `pattern` stored inside with the specified options.
 *
 *   @param [String] pattern the pattern to compile
 *   @param [Hash] options the options with which to compile the pattern
 *   @option options [Boolean] :utf8 (true) text and pattern are UTF-8; otherwise Latin-1
 *   @option options [Boolean] :posix_syntax (false) restrict regexps to POSIX egrep syntax
 *   @option options [Boolean] :longest_match (false) search for longest match, not first match
 *   @option options [Boolean] :log_errors (true) log syntax and execution errors to ERROR
 *   @option options [Integer] :max_mem approx. max memory footprint of RE2
 *   @option options [Boolean] :literal (false) interpret string as literal, not regexp
 *   @option options [Boolean] :never_nl (false) never match `\n`, even if it is in regexp
 *   @option options [Boolean] :case_sensitive (true) match is case-sensitive (regexp can override with `(?i)` unless in `posix_syntax` mode)
 *   @option options [Boolean] :perl_classes (false) allow Perl's `\d` `\s` `\w` `\D` `\S` `\W` when in `posix_syntax` mode
 *   @option options [Boolean] :word_boundary (false) allow `\b` `\B` (word boundary and not) when in `posix_syntax` mode
 *   @option options [Boolean] :one_line (false) `^` and `$` only match beginning and end of text when in `posix_syntax` mode
 *   @return [RE2::Regexp] a {RE2::Regexp} with the specified pattern and options
 *   @raise [TypeError] if the given pattern can't be coerced to a `String`
 *   @raise [NoMemoryError] if memory could not be allocated for the compiled pattern
 */
static VALUE re2_regexp_initialize(int argc, VALUE *argv, VALUE self) {
  VALUE pattern, options;
  re2_pattern *p;

  rb_scan_args(argc, argv, "11", &pattern, &options);

  /* Ensure pattern is a string. */
  StringValue(pattern);

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  if (RTEST(options)) {
    RE2::Options re2_options;
    parse_re2_options(&re2_options, options);

    p->pattern = new(std::nothrow) RE2(
        re2::StringPiece(RSTRING_PTR(pattern), RSTRING_LEN(pattern)), re2_options);
  } else {
    p->pattern = new(std::nothrow) RE2(
        re2::StringPiece(RSTRING_PTR(pattern), RSTRING_LEN(pattern)));
  }

  if (p->pattern == 0) {
    rb_raise(rb_eNoMemError, "not enough memory to allocate RE2 object");
  }

  return self;
}

/*
 * Returns a printable version of the regular expression.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is
 * undefined).
 *
 * @return [String] a printable version of the regular expression
 * @example
 *   re2 = RE2::Regexp.new("woo?")
 *   re2.inspect #=> "#<RE2::Regexp /woo?/>"
 */
static VALUE re2_regexp_inspect(const VALUE self) {
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  std::ostringstream output;

  output << "#<RE2::Regexp /" << p->pattern->pattern() << "/>";

  return encoded_str_new(output.str().data(), output.str().length(),
      p->pattern->options().encoding());
}

/*
 * Returns a string version of the regular expression.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [String] a string version of the regular expression
 * @example
 *   re2 = RE2::Regexp.new("woo?")
 *   re2.to_s #=> "woo?"
 */
static VALUE re2_regexp_to_s(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return encoded_str_new(p->pattern->pattern().data(),
      p->pattern->pattern().size(),
      p->pattern->options().encoding());
}

/*
 * Returns whether or not the regular expression was compiled successfully.
 *
 * @return [Boolean] whether or not compilation was successful
 * @example
 *   re2 = RE2::Regexp.new("woo?")
 *   re2.ok? #=> true
 */
static VALUE re2_regexp_ok(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->ok());
}

/*
 * Returns whether or not the regular expression was compiled with the `utf8`
 * option set to `true`.
 *
 * @return [Boolean] the `utf8` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", utf8: true)
 *   re2.utf8? #=> true
 */
static VALUE re2_regexp_utf8(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().encoding() == RE2::Options::EncodingUTF8);
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `posix_syntax` option set to `true`.
 *
 * @return [Boolean] the `posix_syntax` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", posix_syntax: true)
 *   re2.posix_syntax? #=> true
 */
static VALUE re2_regexp_posix_syntax(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().posix_syntax());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `longest_match` option set to `true`.
 *
 * @return [Boolean] the `longest_match` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", longest_match: true)
 *   re2.longest_match? #=> true
 */
static VALUE re2_regexp_longest_match(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().longest_match());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `log_errors` option set to `true`.
 *
 * @return [Boolean] the `log_errors` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", log_errors: true)
 *   re2.log_errors? #=> true
 */
static VALUE re2_regexp_log_errors(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().log_errors());
}

/*
 * Returns the `max_mem` setting for the regular expression.
 *
 * @return [Integer] the `max_mem` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", max_mem: 1024)
 *   re2.max_mem #=> 1024
 */
static VALUE re2_regexp_max_mem(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return INT2FIX(p->pattern->options().max_mem());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `literal` option set to `true`.
 *
 * @return [Boolean] the `literal` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", literal: true)
 *   re2.literal? #=> true
 */
static VALUE re2_regexp_literal(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().literal());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `never_nl` option set to `true`.
 *
 * @return [Boolean] the `never_nl` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", never_nl: true)
 *   re2.never_nl? #=> true
 */
static VALUE re2_regexp_never_nl(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().never_nl());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `case_sensitive` option set to `true`.
 *
 * @return [Boolean] the `case_sensitive` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", case_sensitive: true)
 *   re2.case_sensitive? #=> true
 */
static VALUE re2_regexp_case_sensitive(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().case_sensitive());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `case_sensitive` option set to `false`.
 *
 * @return [Boolean] the inverse of the `case_sensitive` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", case_sensitive: true)
 *   re2.case_insensitive? #=> false
 *   re2.casefold?         #=> false
 */
static VALUE re2_regexp_case_insensitive(const VALUE self) {
  return BOOL2RUBY(re2_regexp_case_sensitive(self) != Qtrue);
}

/*
 * Returns whether or not the regular expression was compiled with the
 * perl_classes option set to `true`.
 *
 * @return [Boolean] the `perl_classes` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", perl_classes: true)
 *   re2.perl_classes? #=> true
 */
static VALUE re2_regexp_perl_classes(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().perl_classes());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `word_boundary` option set to `true`.
 *
 * @return [Boolean] the `word_boundary` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", word_boundary: true)
 *   re2.word_boundary? #=> true
 */
static VALUE re2_regexp_word_boundary(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().word_boundary());
}

/*
 * Returns whether or not the regular expression was compiled with the
 * `one_line` option set to `true`.
 *
 * @return [Boolean] the `one_line` option
 * @example
 *   re2 = RE2::Regexp.new("woo?", one_line: true)
 *   re2.one_line? #=> true
 */
static VALUE re2_regexp_one_line(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(p->pattern->options().one_line());
}

/*
 * If the {RE2::Regexp} could not be created properly, returns an error string
 * otherwise returns `nil`.
 *
 * @return [String, nil] the error string or `nil`
 */
static VALUE re2_regexp_error(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  if (p->pattern->ok()) {
    return Qnil;
  } else {
    return rb_str_new(p->pattern->error().data(), p->pattern->error().size());
  }
}

/*
 * If the {RE2::Regexp} could not be created properly, returns
 * the offending portion of the regexp otherwise returns `nil`.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [String, nil] the offending portion of the regexp or `nil`
 */
static VALUE re2_regexp_error_arg(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  if (p->pattern->ok()) {
    return Qnil;
  } else {
    return encoded_str_new(p->pattern->error_arg().data(),
        p->pattern->error_arg().size(),
        p->pattern->options().encoding());
  }
}

/*
 * Returns the program size, a very approximate measure
 * of a regexp's "cost". Larger numbers are more expensive
 * than smaller numbers.
 *
 * @return [Integer] the regexp "cost"
 */
static VALUE re2_regexp_program_size(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return INT2FIX(p->pattern->ProgramSize());
}

/*
 * Returns a hash of the options currently set for the {RE2::Regexp}.
 *
 * @return [Hash] the options
 */
static VALUE re2_regexp_options(const VALUE self) {
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);
  VALUE options = rb_hash_new();

  rb_hash_aset(options, ID2SYM(id_utf8),
      BOOL2RUBY(p->pattern->options().encoding() == RE2::Options::EncodingUTF8));

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

  /* This is a read-only hash after all... */
  rb_obj_freeze(options);

  return options;
}

/*
 * Returns the number of capturing subpatterns, or -1 if the regexp
 * wasn't valid on construction. The overall match (`$0`) does not
 * count: if the regexp is `"(a)(b)"`, returns 2.
 *
 * @return [Integer] the number of capturing subpatterns
 */
static VALUE re2_regexp_number_of_capturing_groups(const VALUE self) {
  re2_pattern *p;
  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return INT2FIX(p->pattern->NumberOfCapturingGroups());
}

/*
 * Returns a hash of names to capturing indices of groups.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @return [Hash] a hash of names to capturing indices
 */
static VALUE re2_regexp_named_capturing_groups(const VALUE self) {
  re2_pattern *p;

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);
  const std::map<std::string, int>& groups = p->pattern->NamedCapturingGroups();
  VALUE capturing_groups = rb_hash_new();

  for (std::map<std::string, int>::const_iterator it = groups.begin(); it != groups.end(); ++it) {
    rb_hash_aset(capturing_groups,
        encoded_str_new(it->first.data(), it->first.size(),
          p->pattern->options().encoding()),
        INT2FIX(it->second));
  }

  return capturing_groups;
}

/*
 * General matching: match the pattern against the given `text` using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L562-L588
 * `Match`} and return a {RE2::MatchData} instance with the specified number of
 * submatches (defaults to the total number of capturing groups) or a boolean
 * (if no submatches are required).
 *
 * The number of submatches has a significant impact on performance: requesting
 * one submatch is much faster than requesting more than one and requesting
 * zero submatches is faster still.
 *
 * @overload match(text)
 *   Returns a {RE2::MatchData} containing the matching pattern and all
 *   submatches resulting from looking for the regexp in `text` if the pattern
 *   contains capturing groups.
 *
 *   Returns either `true` or `false` indicating whether a successful match was
 *   made if the pattern contains no capturing groups.
 *
 *   @param [String] text the text to search
 *   @return [RE2::MatchData, nil] if the pattern contains capturing groups
 *   @return [Boolean] if the pattern does not contain capturing groups
 *   @raise [NoMemoryError] if there was not enough memory to allocate the submatches
 *   @raise [TypeError] if given text that cannot be coerced to a `String`
 *   @example Matching with capturing groups
 *     r = RE2::Regexp.new('w(o)(o)')
 *     r.match('woo') #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
 *   @example Matching without capturing groups
 *     r = RE2::Regexp.new('woo')
 *     r.match('woo') #=> true
 *
 * @overload match(text, options)
 *   See `match(text)` but with customisable offsets for starting and ending
 *   matches, optional anchoring to the start or both ends of the text and a
 *   specific number of submatches to extract (padded with `nil`s if
 *   necessary).
 *
 *   @param [String] text the text to search
 *   @param [Hash] options the options with which to perform the match
 *   @option options [Integer] :startpos (0) offset at which to start matching
 *   @option options [Integer] :endpos offset at which to stop matching, defaults to the text length
 *   @option options [Symbol] :anchor (:unanchored) one of :unanchored, :anchor_start, :anchor_both to anchor the match
 *   @option options [Integer] :submatches how many submatches to extract (0 is
 *     fastest), defaults to the number of capturing groups
 *   @return [RE2::MatchData, nil] if extracting any submatches
 *   @return [Boolean] if not extracting any submatches
 *   @raise [ArgumentError] if given a negative number of submatches, invalid
 *     anchor or invalid startpos, endpos pair
 *   @raise [NoMemoryError] if there was not enough memory to allocate the matches
 *   @raise [TypeError] if given non-String text, non-numeric number of
 *     submatches, non-symbol anchor or non-hash options
 *   @raise [RE2::Regexp::UnsupportedError] if given an endpos argument on a
 *     version of RE2 that does not support it
 *   @example Matching with capturing groups
 *     r = RE2::Regexp.new('w(o)(o)')
 *     r.match('woo', submatches: 1) #=> #<RE2::MatchData "woo" 1:"o">
 *     r.match('woo', submatches: 3) #=> #<RE2::MatchData "woo" 1:"o" 2:"o" 3:nil>
 *     r.match('woot', anchor: :anchor_both, submatches: 0)
 *     #=> false
 *     r.match('woot', anchor: :anchor_start, submatches: 0)
 *     #=> true
 *   @example Matching without capturing groups
 *     r = RE2::Regexp.new('wo+')
 *     r.match('woot', anchor: :anchor_both)  #=> false
 *     r.match('woot', anchor: :anchor_start) #=> true
 *
 * @overload match(text, submatches)
 *   @deprecated Legacy syntax for matching against `text` with a specific
 *     number of submatches to extract. Use `match(text, submatches: n)` instead.
 *
 *   @param [String] text the text to search
 *   @param [Integer] submatches the number of submatches to extract
 *   @return [RE2::MatchData, nil] if extracting any submatches
 *   @return [Boolean] if not extracting any submatches
 *   @raise [NoMemoryError] if there was not enough memory to allocate the submatches
 *   @raise [TypeError] if given non-numeric number of submatches
 *   @example
 *     r = RE2::Regexp.new('w(o)(o)')
 *     r.match('woo', 0) #=> true
 *     r.match('woo', 1) #=> #<RE2::MatchData "woo" 1:"o">
 *     r.match('woo', 2) #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
 */
static VALUE re2_regexp_match(int argc, VALUE *argv, const VALUE self) {
  re2_pattern *p;
  re2_matchdata *m;
  VALUE text, options;

  rb_scan_args(argc, argv, "11", &text, &options);

  /* Ensure text is a string. */
  StringValue(text);

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  int n;
  int startpos = 0;
  int endpos = RSTRING_LEN(text);
  RE2::Anchor anchor = RE2::UNANCHORED;

  if (RTEST(options)) {
    if (FIXNUM_P(options)) {
      n = NUM2INT(options);

      if (n < 0) {
        rb_raise(rb_eArgError, "number of matches should be >= 0");
      }
    } else {
      if (TYPE(options) != T_HASH) {
        options = rb_Hash(options);
      }

      VALUE endpos_option = rb_hash_aref(options, ID2SYM(id_endpos));
      if (!NIL_P(endpos_option)) {
#ifdef HAVE_ENDPOS_ARGUMENT
        Check_Type(endpos_option, T_FIXNUM);

        endpos = NUM2INT(endpos_option);

        if (endpos < 0) {
          rb_raise(rb_eArgError, "endpos should be >= 0");
        }
#else
        rb_raise(re2_eRegexpUnsupportedError, "current version of RE2::Match() does not support endpos argument");
#endif
      }

      VALUE anchor_option = rb_hash_aref(options, ID2SYM(id_anchor));
      if (!NIL_P(anchor_option)) {
        Check_Type(anchor_option, T_SYMBOL);

        ID id_anchor_option = SYM2ID(anchor_option);
        if (id_anchor_option == id_unanchored) {
          anchor = RE2::UNANCHORED;
        } else if (id_anchor_option == id_anchor_start) {
          anchor = RE2::ANCHOR_START;
        } else if (id_anchor_option == id_anchor_both) {
          anchor = RE2::ANCHOR_BOTH;
        } else {
          rb_raise(rb_eArgError, "anchor should be one of: :unanchored, :anchor_start, :anchor_both");
        }
      }

      VALUE submatches_option = rb_hash_aref(options, ID2SYM(id_submatches));
      if (!NIL_P(submatches_option)) {
        Check_Type(submatches_option, T_FIXNUM);

        n = NUM2INT(submatches_option);

        if (n < 0) {
          rb_raise(rb_eArgError, "number of matches should be >= 0");
        }
      } else {
        if (!p->pattern->ok()) {
          return Qnil;
        }

        n = p->pattern->NumberOfCapturingGroups();
      }

      VALUE startpos_option = rb_hash_aref(options, ID2SYM(id_startpos));
      if (!NIL_P(startpos_option)) {
        Check_Type(startpos_option, T_FIXNUM);

        startpos = NUM2INT(startpos_option);

        if (startpos < 0) {
          rb_raise(rb_eArgError, "startpos should be >= 0");
        }
      }
    }
  } else {
    if (!p->pattern->ok()) {
      return Qnil;
    }

    n = p->pattern->NumberOfCapturingGroups();
  }

  if (startpos > endpos) {
    rb_raise(rb_eArgError, "startpos should be <= endpos");
  }

  if (n == 0) {
#ifdef HAVE_ENDPOS_ARGUMENT
    bool matched = p->pattern->Match(
        re2::StringPiece(RSTRING_PTR(text), RSTRING_LEN(text)),
        startpos, endpos, anchor, 0, 0);
#else
    bool matched = p->pattern->Match(
        re2::StringPiece(RSTRING_PTR(text), RSTRING_LEN(text)),
        startpos, anchor, 0, 0);
#endif
    return BOOL2RUBY(matched);
  } else {
    /* Because match returns the whole match as well. */
    n += 1;

    VALUE matchdata = rb_class_new_instance(0, 0, re2_cMatchData);
    TypedData_Get_Struct(matchdata, re2_matchdata, &re2_matchdata_data_type, m);
    m->matches = new(std::nothrow) re2::StringPiece[n];
    RB_OBJ_WRITE(matchdata, &m->regexp, self);
    if (!RTEST(rb_obj_frozen_p(text))) {
      text = rb_str_freeze(rb_str_dup(text));
    }
    RB_OBJ_WRITE(matchdata, &m->text, text);

    if (m->matches == 0) {
      rb_raise(rb_eNoMemError,
               "not enough memory to allocate StringPieces for matches");
    }

    m->number_of_matches = n;

#ifdef HAVE_ENDPOS_ARGUMENT
    bool matched = p->pattern->Match(
        re2::StringPiece(RSTRING_PTR(m->text), RSTRING_LEN(m->text)),
        startpos, endpos, anchor, m->matches, n);
#else
    bool matched = p->pattern->Match(
        re2::StringPiece(RSTRING_PTR(m->text), RSTRING_LEN(m->text)),
        startpos, anchor, m->matches, n);
#endif
    if (matched) {
      return matchdata;
    } else {
      return Qnil;
    }
  }
}

/*
 * Returns true if the pattern matches any substring of the given text using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L413-L427
 * `PartialMatch`}.
 *
 * @return [Boolean] whether the match was successful
 * @raise [TypeError] if text cannot be coerced to a `String`
 */
static VALUE re2_regexp_match_p(const VALUE self, VALUE text) {
  re2_pattern *p;

  /* Ensure text is a string. */
  StringValue(text);

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(RE2::PartialMatch(
        re2::StringPiece(RSTRING_PTR(text), RSTRING_LEN(text)), *p->pattern));
}

/*
 * Returns true if the pattern matches the given text using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L376-L411
 * `FullMatch`}.
 *
 * @return [Boolean] whether the match was successful
 * @raise [TypeError] if text cannot be coerced to a `String`
 */
static VALUE re2_regexp_full_match_p(const VALUE self, VALUE text) {
  re2_pattern *p;

  /* Ensure text is a string. */
  StringValue(text);

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);

  return BOOL2RUBY(RE2::FullMatch(
        re2::StringPiece(RSTRING_PTR(text), RSTRING_LEN(text)), *p->pattern));
}

/*
 * Returns a {RE2::Scanner} for scanning the given text incrementally with
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L447-L463
 * `FindAndConsume`}.
 *
 * @param [text] text the text to scan incrementally
 * @return [RE2::Scanner] an `Enumerable` {RE2::Scanner} object
 * @raise [TypeError] if `text` cannot be coerced to a `String`
 * @example
 *   c = RE2::Regexp.new('(\w+)').scan("Foo bar baz")
 *   #=> #<RE2::Scanner:0x0000000000000001>
 */
static VALUE re2_regexp_scan(const VALUE self, VALUE text) {
  /* Ensure text is a string. */
  StringValue(text);

  re2_pattern *p;
  re2_scanner *c;

  TypedData_Get_Struct(self, re2_pattern, &re2_regexp_data_type, p);
  VALUE scanner = rb_class_new_instance(0, 0, re2_cScanner);
  TypedData_Get_Struct(scanner, re2_scanner, &re2_scanner_data_type, c);

  c->input = new(std::nothrow) re2::StringPiece(
      RSTRING_PTR(text), RSTRING_LEN(text));
  RB_OBJ_WRITE(scanner, &c->regexp, self);
  RB_OBJ_WRITE(scanner, &c->text, text);

  if (p->pattern->ok()) {
    c->number_of_capturing_groups = p->pattern->NumberOfCapturingGroups();
  } else {
    c->number_of_capturing_groups = 0;
  }

  c->eof = false;

  return scanner;
}

/*
 * Returns whether the underlying RE2 version supports passing an `endpos`
 * argument to
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L562-L588
 * Match}. If not, {RE2::Regexp#match} will raise an error if attempting to
 * pass an `endpos`.
 *
 * @return [Boolean] whether the underlying
 *   {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L562-L588
 *   Match} has an endpos argument
 */
static VALUE re2_regexp_match_has_endpos_argument_p(VALUE) {
#ifdef HAVE_ENDPOS_ARGUMENT
  return Qtrue;
#else
  return Qfalse;
#endif
}

/*
 * Returns a copy of `str` with the first occurrence `pattern` replaced with
 * `rewrite` using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L465-L480
 * `Replace`}.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @param [String] str the string to modify
 * @param [String, RE2::Regexp] pattern a regexp matching text to be replaced
 * @param [String] rewrite the string to replace with
 * @return [String] the resulting string
 * @raise [TypeError] if the given rewrite or pattern (if not provided as a
 *   {RE2::Regexp}) cannot be coerced to `String`s
 * @example
 *   RE2.Replace("hello there", "hello", "howdy") #=> "howdy there"
 *   re2 = RE2::Regexp.new("hel+o")
 *   RE2.Replace("hello there", re2, "yo")        #=> "yo there"
 */
static VALUE re2_Replace(VALUE, VALUE str, VALUE pattern,
    VALUE rewrite) {
  /* Ensure rewrite is a string. */
  StringValue(rewrite);

  re2_pattern *p;

  /* Take a copy of str so it can be modified in-place by
   * RE2::Replace.
   */
  StringValue(str);
  std::string str_as_string(RSTRING_PTR(str), RSTRING_LEN(str));

  /* Do the replacement. */
  if (rb_obj_is_kind_of(pattern, re2_cRegexp)) {
    TypedData_Get_Struct(pattern, re2_pattern, &re2_regexp_data_type, p);
    RE2::Replace(&str_as_string, *p->pattern,
        re2::StringPiece(RSTRING_PTR(rewrite), RSTRING_LEN(rewrite)));

    return encoded_str_new(str_as_string.data(), str_as_string.size(),
        p->pattern->options().encoding());
  } else {
    /* Ensure pattern is a string. */
    StringValue(pattern);

    RE2::Replace(&str_as_string,
        re2::StringPiece(RSTRING_PTR(pattern), RSTRING_LEN(pattern)),
        re2::StringPiece(RSTRING_PTR(rewrite), RSTRING_LEN(rewrite)));

    return encoded_str_new(str_as_string.data(), str_as_string.size(), RE2::Options::EncodingUTF8);
  }
}

/*
 * Return a copy of `str` with `pattern` replaced by `rewrite` using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L482-L497
 * `GlobalReplace`}.
 *
 * Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
 * returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
 * {RE2::Regexp} is set to `false` (any other encoding's behaviour is undefined).
 *
 * @param [String] str the string to modify
 * @param [String, RE2::Regexp] pattern a regexp matching text to be replaced
 * @param [String] rewrite the string to replace with
 * @raise [TypeError] if the given rewrite or pattern (if not provided as a
 *   {RE2::Regexp}) cannot be coerced to `String`s
 * @return [String] the resulting string
 * @example
 *   re2 = RE2::Regexp.new("oo?")
 *   RE2.GlobalReplace("whoops-doops", re2, "e") #=> "wheps-deps"
 *   RE2.GlobalReplace("hello there", "e", "i")  #=> "hillo thiri"
 */
static VALUE re2_GlobalReplace(VALUE, VALUE str, VALUE pattern,
                               VALUE rewrite) {
  /* Ensure rewrite is a string. */
  StringValue(rewrite);

  /* Take a copy of str so it can be modified in-place by
   * RE2::GlobalReplace.
   */
  re2_pattern *p;
  StringValue(str);
  std::string str_as_string(RSTRING_PTR(str), RSTRING_LEN(str));

  /* Do the replacement. */
  if (rb_obj_is_kind_of(pattern, re2_cRegexp)) {
    TypedData_Get_Struct(pattern, re2_pattern, &re2_regexp_data_type, p);
    RE2::GlobalReplace(&str_as_string, *p->pattern,
        re2::StringPiece(RSTRING_PTR(rewrite), RSTRING_LEN(rewrite)));

    return encoded_str_new(str_as_string.data(), str_as_string.size(),
        p->pattern->options().encoding());
  } else {
    /* Ensure pattern is a string. */
    StringValue(pattern);

    RE2::GlobalReplace(&str_as_string,
        re2::StringPiece(RSTRING_PTR(pattern), RSTRING_LEN(pattern)),
        re2::StringPiece(RSTRING_PTR(rewrite), RSTRING_LEN(rewrite)));

    return encoded_str_new(str_as_string.data(), str_as_string.size(), RE2::Options::EncodingUTF8);
  }
}

/*
 * Returns a version of `str` with all potentially meaningful regexp characters
 * escaped using
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/re2.h#L512-L518
 * `QuoteMeta`}. The returned string, used as a regular expression, will
 * exactly match the original string.
 *
 * @param [String] unquoted the unquoted string
 * @raise [TypeError] if the given unquoted string cannot be coerced to a `String`
 * @return [String] the escaped string
 * @example
 *   RE2::Regexp.escape("1.5-2.0?") #=> "1\.5\-2\.0\?"
 */
static VALUE re2_QuoteMeta(VALUE, VALUE unquoted) {
  StringValue(unquoted);

  std::string quoted_string = RE2::QuoteMeta(
      re2::StringPiece(RSTRING_PTR(unquoted), RSTRING_LEN(unquoted)));

  return rb_str_new(quoted_string.data(), quoted_string.size());
}

static void re2_set_free(void *ptr) {
  re2_set *s = reinterpret_cast<re2_set *>(ptr);
  if (s->set) {
    delete s->set;
  }
  xfree(s);
}

static size_t re2_set_memsize(const void *ptr) {
  const re2_set *s = reinterpret_cast<const re2_set *>(ptr);
  size_t size = sizeof(*s);
  if (s->set) {
    size += sizeof(*s->set);
  }

  return size;
}

static const rb_data_type_t re2_set_data_type = {
  "RE2::Set",
  {
    0,
    re2_set_free,
    re2_set_memsize,
  },
  0,
  0,
  // IMPORTANT: WB_PROTECTED objects must only use the RB_OBJ_WRITE()
  // macro to update VALUE references, as to trigger write barriers.
  RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static VALUE re2_set_allocate(VALUE klass) {
  re2_set *s;
  VALUE result = TypedData_Make_Struct(klass, re2_set, &re2_set_data_type, s);

  return result;
}

/*
 * Returns a new {RE2::Set} object, a collection of patterns that can be
 * searched for simultaneously.
 *
 * @return [RE2::Set]
 *
 * @overload initialize
 *   Returns a new {RE2::Set} object for unanchored patterns with the default
 *   options.
 *
 *   @raise [NoMemoryError] if memory could not be allocated for the compiled pattern
 *   @return [RE2::Set]
 *
 * @overload initialize(anchor)
 *   Returns a new {RE2::Set} object for the specified anchor with the default
 *   options.
 *
 *   @param [Symbol] anchor one of `:unanchored`, `:anchor_start`, `:anchor_both`
 *   @raise [ArgumentError] if anchor is not `:unanchored`, `:anchor_start` or `:anchor_both`
 *   @raise [NoMemoryError] if memory could not be allocated for the compiled pattern
 *
 * @overload initialize(anchor, options)
 *   Returns a new {RE2::Set} object with the specified options.
 *
 *   @param [Symbol] anchor one of `:unanchored`, `:anchor_start`, `:anchor_both`
 *   @param [Hash] options the options with which to compile the pattern
 *   @option options [Boolean] :utf8 (true) text and pattern are UTF-8; otherwise Latin-1
 *   @option options [Boolean] :posix_syntax (false) restrict regexps to POSIX egrep syntax
 *   @option options [Boolean] :longest_match (false) search for longest match, not first match
 *   @option options [Boolean] :log_errors (true) log syntax and execution errors to ERROR
 *   @option options [Integer] :max_mem approx. max memory footprint of RE2
 *   @option options [Boolean] :literal (false) interpret string as literal, not regexp
 *   @option options [Boolean] :never_nl (false) never match `\n`, even if it is in regexp
 *   @option options [Boolean] :case_sensitive (true) match is case-sensitive (regexp can override with `(?i)` unless in `posix_syntax` mode)
 *   @option options [Boolean] :perl_classes (false) allow Perl's `\d` `\s` `\w` `\D` `\S` `\W` when in `posix_syntax` mode
 *   @option options [Boolean] :word_boundary (false) allow `\b` `\B` (word boundary and not) when in `posix_syntax` mode
 *   @option options [Boolean] :one_line (false) `^` and `$` only match beginning and end of text when in `posix_syntax` mode
 *   @return [RE2::Set] a {RE2::Set} with the specified anchor and options
 *   @raise [ArgumentError] if `anchor` is not one of the accepted choices
 *   @raise [NoMemoryError] if memory could not be allocated for the compiled pattern
 */
static VALUE re2_set_initialize(int argc, VALUE *argv, VALUE self) {
  VALUE anchor, options;
  re2_set *s;

  rb_scan_args(argc, argv, "02", &anchor, &options);
  TypedData_Get_Struct(self, re2_set, &re2_set_data_type, s);

  RE2::Anchor re2_anchor = RE2::UNANCHORED;

  if (!NIL_P(anchor)) {
    Check_Type(anchor, T_SYMBOL);
    ID id_anchor_arg = SYM2ID(anchor);
    if (id_anchor_arg == id_unanchored) {
      re2_anchor = RE2::UNANCHORED;
    } else if (id_anchor_arg == id_anchor_start) {
      re2_anchor = RE2::ANCHOR_START;
    } else if (id_anchor_arg == id_anchor_both) {
      re2_anchor = RE2::ANCHOR_BOTH;
    } else {
      rb_raise(rb_eArgError, "anchor should be one of: :unanchored, :anchor_start, :anchor_both");
    }
  }

  RE2::Options re2_options;

  if (RTEST(options)) {
    parse_re2_options(&re2_options, options);
  }

  s->set = new(std::nothrow) RE2::Set(re2_options, re2_anchor);
  if (s->set == 0) {
    rb_raise(rb_eNoMemError, "not enough memory to allocate RE2::Set object");
  }

  return self;
}

/*
 * Adds a pattern to the set. Returns the index that will identify the pattern
 * in the output of {RE2::Set#match}. Cannot be called after {RE2::Set#compile}
 * has been called.
 *
 * @param [String] pattern the regex pattern
 * @return [Integer] the index of the pattern in the set
 * @raise [ArgumentError] if called after compile or the pattern is rejected
 * @example
 *   set = RE2::Set.new
 *   set.add("abc") #=> 0
 *   set.add("def") #=> 1
 */
static VALUE re2_set_add(VALUE self, VALUE pattern) {
  StringValue(pattern);

  re2_set *s;
  TypedData_Get_Struct(self, re2_set, &re2_set_data_type, s);

  /* To prevent the memory of the err string leaking when we call rb_raise,
   * take a copy of it and let it go out of scope.
   */
  char msg[100];
  int index;

  {
    std::string err;
    index = s->set->Add(
        re2::StringPiece(RSTRING_PTR(pattern), RSTRING_LEN(pattern)), &err);
    strlcpy(msg, err.c_str(), sizeof(msg));
  }

  if (index < 0) {
    rb_raise(rb_eArgError, "str rejected by RE2::Set->Add(): %s", msg);
  }

  return INT2FIX(index);
}

/*
 * Compiles a {RE2::Set} so it can be used to match against. Must be called
 * after {RE2::Set#add} and before {RE2::Set#match}.
 *
 * @return [Boolean] whether compilation was a success
 * @example
 *   set = RE2::Set.new
 *   set.add("abc")
 *   set.compile #=> true
 */
static VALUE re2_set_compile(VALUE self) {
  re2_set *s;
  TypedData_Get_Struct(self, re2_set, &re2_set_data_type, s);

  return BOOL2RUBY(s->set->Compile());
}

/*
 * Returns the size of the {RE2::Set}.
 *
 * @return [Integer] the number of patterns in the set
 * @example
 *   set = RE2::Set.new
 *   set.add("abc")
 *   set.size #=> 1
 */
static VALUE re2_set_size(VALUE self) {
#ifdef HAVE_SET_SIZE
  re2_set *s;
  TypedData_Get_Struct(self, re2_set, &re2_set_data_type, s);

  return INT2FIX(s->set->Size());
#else
  rb_raise(re2_eSetUnsupportedError, "current version of RE2::Set does not have Size method");
#endif
}

/*
 * Returns whether the underlying RE2 version outputs error information from
 * {https://github.com/google/re2/blob/bc0faab533e2b27b85b8ad312abf061e33ed6b5d/re2/set.h#L62-L65
 * `RE2::Set::Match`}. If not, {RE2::Set#match} will raise an error if attempting to set
 * its `:exception` option to `true`.
 *
 * @return [Boolean] whether the underlying RE2 outputs error information from {RE2::Set} matches
 */
static VALUE re2_set_match_raises_errors_p(VALUE) {
#ifdef HAVE_ERROR_INFO_ARGUMENT
  return Qtrue;
#else
  return Qfalse;
#endif
}

/*
 * Returns whether the underlying RE2 version has a Set::Size method.
 *
 * @return [Boolean] whether the underlying RE2 has a Set::Size method
 */
static VALUE re2_set_size_p(VALUE) {
#ifdef HAVE_SET_SIZE
  return Qtrue;
#else
  return Qfalse;
#endif
}

/*
 * Matches the given text against patterns in the set, returning an array of
 * integer indices of the matching patterns if matched or an empty array if
 * there are no matches.
 *
 * @return [Array<Integer>]
 *
 * @overload match(str)
 *   Returns an array of integer indices of patterns matching the given string
 *   (if any). Raises exceptions if there are any errors while matching.
 *
 *   @param [String] str the text to match against
 *   @return [Array<Integer>] the indices of matching regexps
 *   @raise [MatchError] if an error occurs while matching
 *   @raise [UnsupportedError] if the underlying version of RE2 does not output error information
 *   @example
 *     set = RE2::Set.new
 *     set.add("abc")
 *     set.add("def")
 *     set.compile
 *     set.match("abcdef") #=> [0, 1]
 *
 * @overload match(str, options)
 *   Returns an array of integer indices of patterns matching the given string
 *   (if any). Raises exceptions if there are any errors while matching and the
 *   `:exception` option is set to true.
 *
 *   @param [String] str the text to match against
 *   @param [Hash] options the options with which to match
 *   @option options [Boolean] :exception (true) whether to raise exceptions with RE2's error information (not supported on ABI version 0 of RE2)
 *   @return [Array<Integer>] the indices of matching regexps
 *   @raise [MatchError] if an error occurs while matching
 *   @raise [UnsupportedError] if the underlying version of RE2 does not output error information
 *   @example
 *     set = RE2::Set.new
 *     set.add("abc")
 *     set.add("def")
 *     set.compile
 *     set.match("abcdef", exception: true) #=> [0, 1]
 */
static VALUE re2_set_match(int argc, VALUE *argv, const VALUE self) {
  VALUE str, options;
  bool raise_exception = true;
  rb_scan_args(argc, argv, "11", &str, &options);

  StringValue(str);
  re2_set *s;
  TypedData_Get_Struct(self, re2_set, &re2_set_data_type, s);

  if (RTEST(options)) {
    Check_Type(options, T_HASH);

    VALUE exception_option = rb_hash_aref(options, ID2SYM(id_exception));
    if (!NIL_P(exception_option)) {
      raise_exception = RTEST(exception_option);
    }
  }

  std::vector<int> v;

  if (raise_exception) {
#ifdef HAVE_ERROR_INFO_ARGUMENT
    RE2::Set::ErrorInfo e;
    bool match_failed = !s->set->Match(
        re2::StringPiece(RSTRING_PTR(str), RSTRING_LEN(str)), &v, &e);
    VALUE result = rb_ary_new2(v.size());

    if (match_failed) {
      switch (e.kind) {
        case RE2::Set::kNoError:
          break;
        case RE2::Set::kNotCompiled:
          rb_raise(re2_eSetMatchError, "#match must not be called before #compile");
        case RE2::Set::kOutOfMemory:
          rb_raise(re2_eSetMatchError, "The DFA ran out of memory");
        case RE2::Set::kInconsistent:
          rb_raise(re2_eSetMatchError, "RE2::Prog internal error");
        default:  // Just in case a future version of libre2 adds new ErrorKinds
          rb_raise(re2_eSetMatchError, "Unknown RE2::Set::ErrorKind: %d", e.kind);
      }
    } else {
      for (std::vector<int>::size_type i = 0; i < v.size(); ++i) {
        rb_ary_push(result, INT2FIX(v[i]));
      }
    }

    return result;
#else
    rb_raise(re2_eSetUnsupportedError, "current version of RE2::Set::Match() does not output error information, :exception option can only be set to false");
#endif
  } else {
    bool matched = s->set->Match(
        re2::StringPiece(RSTRING_PTR(str), RSTRING_LEN(str)), &v);
    VALUE result = rb_ary_new2(v.size());

    if (matched) {
      for (std::vector<int>::size_type i = 0; i < v.size(); ++i) {
        rb_ary_push(result, INT2FIX(v[i]));
      }
    }

    return result;
  }
}

extern "C" void Init_re2(void) {
  re2_mRE2 = rb_define_module("RE2");
  re2_cRegexp = rb_define_class_under(re2_mRE2, "Regexp", rb_cObject);
  re2_eRegexpUnsupportedError = rb_define_class_under(re2_cRegexp,
      "UnsupportedError", rb_const_get(rb_cObject, rb_intern("StandardError")));
  re2_cMatchData = rb_define_class_under(re2_mRE2, "MatchData", rb_cObject);
  re2_cScanner = rb_define_class_under(re2_mRE2, "Scanner", rb_cObject);
  re2_cSet = rb_define_class_under(re2_mRE2, "Set", rb_cObject);
  re2_eSetMatchError = rb_define_class_under(re2_cSet, "MatchError",
      rb_const_get(rb_cObject, rb_intern("StandardError")));
  re2_eSetUnsupportedError = rb_define_class_under(re2_cSet, "UnsupportedError",
      rb_const_get(rb_cObject, rb_intern("StandardError")));

  rb_define_alloc_func(re2_cRegexp,
      reinterpret_cast<VALUE (*)(VALUE)>(re2_regexp_allocate));
  rb_define_alloc_func(re2_cMatchData,
      reinterpret_cast<VALUE (*)(VALUE)>(re2_matchdata_allocate));
  rb_define_alloc_func(re2_cScanner,
      reinterpret_cast<VALUE (*)(VALUE)>(re2_scanner_allocate));
  rb_define_alloc_func(re2_cSet,
      reinterpret_cast<VALUE (*)(VALUE)>(re2_set_allocate));

  rb_define_method(re2_cMatchData, "string",
      RUBY_METHOD_FUNC(re2_matchdata_string), 0);
  rb_define_method(re2_cMatchData, "regexp",
      RUBY_METHOD_FUNC(re2_matchdata_regexp), 0);
  rb_define_method(re2_cMatchData, "to_a",
      RUBY_METHOD_FUNC(re2_matchdata_to_a), 0);
  rb_define_method(re2_cMatchData, "size",
      RUBY_METHOD_FUNC(re2_matchdata_size), 0);
  rb_define_method(re2_cMatchData, "length",
      RUBY_METHOD_FUNC(re2_matchdata_size), 0);
  rb_define_method(re2_cMatchData, "begin",
      RUBY_METHOD_FUNC(re2_matchdata_begin), 1);
  rb_define_method(re2_cMatchData, "end",
      RUBY_METHOD_FUNC(re2_matchdata_end), 1);
  rb_define_method(re2_cMatchData, "[]", RUBY_METHOD_FUNC(re2_matchdata_aref),
      -1);
  rb_define_method(re2_cMatchData, "to_s",
        RUBY_METHOD_FUNC(re2_matchdata_to_s), 0);
  rb_define_method(re2_cMatchData, "inspect",
      RUBY_METHOD_FUNC(re2_matchdata_inspect), 0);
  rb_define_method(re2_cMatchData, "deconstruct",
      RUBY_METHOD_FUNC(re2_matchdata_deconstruct), 0);
  rb_define_method(re2_cMatchData, "deconstruct_keys",
      RUBY_METHOD_FUNC(re2_matchdata_deconstruct_keys), 1);

  rb_define_method(re2_cScanner, "string",
      RUBY_METHOD_FUNC(re2_scanner_string), 0);
  rb_define_method(re2_cScanner, "eof?",
      RUBY_METHOD_FUNC(re2_scanner_eof), 0);
  rb_define_method(re2_cScanner, "regexp",
      RUBY_METHOD_FUNC(re2_scanner_regexp), 0);
  rb_define_method(re2_cScanner, "scan",
      RUBY_METHOD_FUNC(re2_scanner_scan), 0);
  rb_define_method(re2_cScanner, "rewind",
      RUBY_METHOD_FUNC(re2_scanner_rewind), 0);

  rb_define_singleton_method(re2_cRegexp, "match_has_endpos_argument?",
      RUBY_METHOD_FUNC(re2_regexp_match_has_endpos_argument_p), 0);
  rb_define_method(re2_cRegexp, "initialize",
      RUBY_METHOD_FUNC(re2_regexp_initialize), -1);
  rb_define_method(re2_cRegexp, "ok?", RUBY_METHOD_FUNC(re2_regexp_ok), 0);
  rb_define_method(re2_cRegexp, "error", RUBY_METHOD_FUNC(re2_regexp_error),
      0);
  rb_define_method(re2_cRegexp, "error_arg",
      RUBY_METHOD_FUNC(re2_regexp_error_arg), 0);
  rb_define_method(re2_cRegexp, "program_size",
      RUBY_METHOD_FUNC(re2_regexp_program_size), 0);
  rb_define_method(re2_cRegexp, "options",
      RUBY_METHOD_FUNC(re2_regexp_options), 0);
  rb_define_method(re2_cRegexp, "number_of_capturing_groups",
      RUBY_METHOD_FUNC(re2_regexp_number_of_capturing_groups), 0);
  rb_define_method(re2_cRegexp, "named_capturing_groups",
      RUBY_METHOD_FUNC(re2_regexp_named_capturing_groups), 0);
  rb_define_method(re2_cRegexp, "match", RUBY_METHOD_FUNC(re2_regexp_match),
      -1);
  rb_define_method(re2_cRegexp, "match?", RUBY_METHOD_FUNC(re2_regexp_match_p),
      1);
  rb_define_method(re2_cRegexp, "partial_match?",
      RUBY_METHOD_FUNC(re2_regexp_match_p), 1);
  rb_define_method(re2_cRegexp, "=~", RUBY_METHOD_FUNC(re2_regexp_match_p), 1);
  rb_define_method(re2_cRegexp, "===", RUBY_METHOD_FUNC(re2_regexp_match_p), 1);
  rb_define_method(re2_cRegexp, "full_match?",
      RUBY_METHOD_FUNC(re2_regexp_full_match_p), 1);
  rb_define_method(re2_cRegexp, "scan",
      RUBY_METHOD_FUNC(re2_regexp_scan), 1);
  rb_define_method(re2_cRegexp, "to_s", RUBY_METHOD_FUNC(re2_regexp_to_s), 0);
  rb_define_method(re2_cRegexp, "to_str", RUBY_METHOD_FUNC(re2_regexp_to_s),
      0);
  rb_define_method(re2_cRegexp, "pattern", RUBY_METHOD_FUNC(re2_regexp_to_s),
      0);
  rb_define_method(re2_cRegexp, "source", RUBY_METHOD_FUNC(re2_regexp_to_s),
      0);
  rb_define_method(re2_cRegexp, "inspect",
      RUBY_METHOD_FUNC(re2_regexp_inspect), 0);
  rb_define_method(re2_cRegexp, "utf8?", RUBY_METHOD_FUNC(re2_regexp_utf8),
      0);
  rb_define_method(re2_cRegexp, "posix_syntax?",
      RUBY_METHOD_FUNC(re2_regexp_posix_syntax), 0);
  rb_define_method(re2_cRegexp, "longest_match?",
      RUBY_METHOD_FUNC(re2_regexp_longest_match), 0);
  rb_define_method(re2_cRegexp, "log_errors?",
      RUBY_METHOD_FUNC(re2_regexp_log_errors), 0);
  rb_define_method(re2_cRegexp, "max_mem",
      RUBY_METHOD_FUNC(re2_regexp_max_mem), 0);
  rb_define_method(re2_cRegexp, "literal?",
      RUBY_METHOD_FUNC(re2_regexp_literal), 0);
  rb_define_method(re2_cRegexp, "never_nl?",
      RUBY_METHOD_FUNC(re2_regexp_never_nl), 0);
  rb_define_method(re2_cRegexp, "case_sensitive?",
      RUBY_METHOD_FUNC(re2_regexp_case_sensitive), 0);
  rb_define_method(re2_cRegexp, "case_insensitive?",
      RUBY_METHOD_FUNC(re2_regexp_case_insensitive), 0);
  rb_define_method(re2_cRegexp, "casefold?",
      RUBY_METHOD_FUNC(re2_regexp_case_insensitive), 0);
  rb_define_method(re2_cRegexp, "perl_classes?",
      RUBY_METHOD_FUNC(re2_regexp_perl_classes), 0);
  rb_define_method(re2_cRegexp, "word_boundary?",
      RUBY_METHOD_FUNC(re2_regexp_word_boundary), 0);
  rb_define_method(re2_cRegexp, "one_line?",
      RUBY_METHOD_FUNC(re2_regexp_one_line), 0);

  rb_define_singleton_method(re2_cSet, "match_raises_errors?",
      RUBY_METHOD_FUNC(re2_set_match_raises_errors_p), 0);
  rb_define_singleton_method(re2_cSet, "size?",
      RUBY_METHOD_FUNC(re2_set_size_p), 0);
  rb_define_method(re2_cSet, "initialize",
      RUBY_METHOD_FUNC(re2_set_initialize), -1);
  rb_define_method(re2_cSet, "add", RUBY_METHOD_FUNC(re2_set_add), 1);
  rb_define_method(re2_cSet, "compile", RUBY_METHOD_FUNC(re2_set_compile), 0);
  rb_define_method(re2_cSet, "match", RUBY_METHOD_FUNC(re2_set_match), -1);
  rb_define_method(re2_cSet, "size", RUBY_METHOD_FUNC(re2_set_size), 0);
  rb_define_method(re2_cSet, "length", RUBY_METHOD_FUNC(re2_set_size), 0);

  rb_define_module_function(re2_mRE2, "Replace",
      RUBY_METHOD_FUNC(re2_Replace), 3);
  rb_define_module_function(re2_mRE2, "GlobalReplace",
      RUBY_METHOD_FUNC(re2_GlobalReplace), 3);
  rb_define_module_function(re2_mRE2, "QuoteMeta",
      RUBY_METHOD_FUNC(re2_QuoteMeta), 1);
  rb_define_singleton_method(re2_cRegexp, "escape",
      RUBY_METHOD_FUNC(re2_QuoteMeta), 1);
  rb_define_singleton_method(re2_cRegexp, "quote",
      RUBY_METHOD_FUNC(re2_QuoteMeta), 1);

  // (see RE2::Regexp#initialize)
  rb_define_singleton_method(re2_cRegexp, "compile",
      RUBY_METHOD_FUNC(rb_class_new_instance), -1);

  rb_define_module_function(rb_mKernel, "RE2", RUBY_METHOD_FUNC(re2_re2), -1);

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
  id_unanchored = rb_intern("unanchored");
  id_anchor = rb_intern("anchor");
  id_anchor_start = rb_intern("anchor_start");
  id_anchor_both = rb_intern("anchor_both");
  id_exception = rb_intern("exception");
  id_submatches = rb_intern("submatches");
  id_startpos = rb_intern("startpos");
  id_endpos = rb_intern("endpos");
}
