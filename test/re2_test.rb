# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010, Paul Mucur (http://mucur.name)
# Released under the BSD Licence, please see LICENSE.txt

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "re2"
require "test/unit"

class RE2Test < Test::Unit::TestCase
  def test_interface
    assert_respond_to RE2, :Replace
    assert_respond_to RE2, :GlobalReplace
    assert_respond_to RE2, :QuoteMeta
    assert_respond_to RE2::Regexp, :escape
    assert_respond_to RE2::Regexp, :quote
    assert_respond_to RE2::Regexp, :new
    assert_respond_to RE2::Regexp, :compile

    r = RE2::Regexp.new('woo')
    assert_respond_to r, :ok?
    assert_respond_to r, :options
    assert_respond_to r, :error
    assert_respond_to r, :error_arg
    assert_respond_to r, :program_size
    assert_respond_to r, :to_s
    assert_respond_to r, :to_str
    assert_respond_to r, :pattern
    assert_respond_to r, :inspect
    assert_respond_to r, :match
    assert_respond_to r, :match?
    assert_respond_to r, :=~
    assert_respond_to r, :===
    assert_respond_to r, :number_of_capturing_groups
    assert_respond_to r, :utf8?
    assert_respond_to r, :posix_syntax?
    assert_respond_to r, :longest_match?
    assert_respond_to r, :log_errors?
    assert_respond_to r, :max_mem
    assert_respond_to r, :literal?
    assert_respond_to r, :never_nl?
    assert_respond_to r, :case_sensitive?
    assert_respond_to r, :case_insensitive?
    assert_respond_to r, :casefold?
    assert_respond_to r, :perl_classes?
    assert_respond_to r, :word_boundary?
    assert_respond_to r, :one_line?

    assert_respond_to Kernel, :RE2
  end

  def test_global_re2
    r = RE2('w(o)(o)')
    assert_kind_of RE2::Regexp, r
    assert_respond_to r, :ok?
  end

  def test_re2_compile
    r = RE2::Regexp.compile('w(o)(o)')
    assert_kind_of RE2::Regexp, r
    assert_respond_to r, :ok?
  end

  def test_replace
    assert_equal "wao", RE2::Replace("woo", "o", "a")
    assert_equal "hoo", RE2::Replace("woo", "w", "h")
    assert_equal "we", RE2::Replace("woo", "o+", "e")
    assert_equal "Good morning", RE2::Replace("hi", "hih?", "Good morning")
    assert_equal "hi", RE2::Replace("Good morning", "(?i)gOOD MORNING", "hi")

    name = "Robert"
    name_id = name.object_id
    assert_equal "Crobert", RE2::Replace(name, "R", "Cr")
    assert_equal "Crobert", name
    assert_equal name_id, name.object_id
  end

  def test_replace_with_a_frozen_string
    frozen_name = "Arnold".freeze
    assert frozen_name.frozen?

    # Ruby 1.9 raises a RuntimeError instead of a TypeError.
    assert_raise TypeError, RuntimeError do
      RE2::Replace(frozen_name, "o", "a")
    end
  end

  def test_global_replace
    assert_equal "waa", RE2::GlobalReplace("woo", "o", "a")
    assert_equal "hoo", RE2::GlobalReplace("woo", "w", "h")
    assert_equal "we", RE2::GlobalReplace("woo", "o+", "e")

    name = "Robert"
    name_id = name.object_id
    assert_equal "wobewt", RE2::GlobalReplace(name, "(?i)R", "w")
    assert_equal "wobewt", name
    assert_equal name_id, name.object_id
  end

  def test_global_replace_with_a_frozen_string
    frozen_name = "Arnold".freeze
    assert frozen_name.frozen?

    # Ruby 1.9 raises a RuntimeError instead of a TypeError.
    assert_raise TypeError, RuntimeError do
      RE2::GlobalReplace(frozen_name, "o", "a")
    end
  end

  def test_compiling
    r = RE2::Regexp.new("woo")
    assert r.ok?
    assert_equal "#<RE2::Regexp /woo/>", r.inspect
    assert_equal "woo", r.to_s
  end

  def test_number_of_capturing_groups
    assert_equal 3, RE2('(a)(b)(c)').number_of_capturing_groups
    assert_equal 0, RE2('abc').number_of_capturing_groups
    assert_equal 2, RE2('a((b)c)').number_of_capturing_groups
  end

  def test_matching_all_subpatterns
    assert_equal ["woo", "o", "o"], RE2('w(o)(o)').match('woo').to_a
    assert_equal ["ab", nil, "a", "b"], RE2('(\d?)(a)(b)').match('ab').to_a
  end

  def test_matchdata
    r = RE2('(\d+)')
    text = "bob 123"
    m = r.match(text)
    assert_kind_of RE2::MatchData, m
    assert_respond_to m, :string
    assert_respond_to m, :size
    assert_respond_to m, :length
    assert_respond_to m, :regexp
    assert_respond_to m, :to_a
    assert_respond_to m, :[]
    assert_equal r, m.regexp
    assert_equal text, m.string
    assert !text.frozen?
    assert m.string.frozen?
    assert_not_equal m.string.object_id, text.object_id
    assert_equal '#<RE2::MatchData "123" 1:"123">', m.inspect
    assert_equal "123", m.to_s
    assert_equal "123", m[0]
    assert_equal "123", m[1]
    assert_equal ["123"], m[0, 1]
    assert_equal ["123", "123"], m[0, 2]
    assert_equal ["123"], m[0...1]
    assert_equal ["123", "123"], m[0..1]
    m1, m2 = *r.match(text)
    assert_equal "123", m1
    assert_equal "123", m2
  end

  def test_matching_no_subpatterns
    assert RE2('woo').match('woo', 0)
    assert !RE2('bob').match('woo', 0)
    assert RE2('woo').match?('woo')
    assert !RE2('bob').match?('woo')
    assert RE2('woo') =~ 'woo'
    assert !(RE2('bob') =~ 'woo')
    assert !(RE2('woo') !~ 'woo')
    assert RE2('bob') !~ 'woo'
    assert RE2('woo') === 'woo'
    assert !(RE2('bob') === 'woo')
  end

  def test_matching_some_sub_patterns
    assert_equal ["woo", "o"], RE2('w(o)(o)').match('woo', 1).to_a
    assert_equal ["woo", "o", "o"], RE2('w(o)(o)').match('woo', 2).to_a
    assert_equal ["woo", "o", "o", nil], RE2('w(o)(o)').match('woo', 3).to_a
    assert_equal ["w", nil], RE2('w(o)?(o)?').match('w', 1).to_a
    assert_equal ["w", nil, nil], RE2('w(o)?(o)?').match('w', 2).to_a
    assert_equal ["w", nil, nil, nil], RE2('w(o)?(o)?').match('w', 3).to_a
  end

  def test_compiling_with_options
    r = RE2("woo", :case_sensitive => false)
    assert r.ok?
    assert r =~ "woo"
    assert r =~ "WOO"
    assert !r.options[:case_sensitive]
    assert r.case_insensitive?
    assert r.casefold?
    assert !r.case_sensitive?
    assert r.utf8?
    assert r.options[:utf8]
  end

  def test_replace_with_re2
    r = RE2("wo{2}")
    assert_equal "miaow", RE2::Replace("woo", r, "miaow")

    assert_equal "wao", RE2::Replace("woo", RE2("o"), "a")
    assert_equal "hoo", RE2::Replace("woo", RE2("w"), "h")
    assert_equal "we", RE2::Replace("woo", RE2("o+"), "e")
    assert_equal "Good morning", RE2::Replace("hi", RE2("hih?"), "Good morning")
    assert_equal "hi", RE2::Replace("Good morning", RE2("gOOD MORNING", :case_sensitive => false), "hi")
  end

  def test_global_replace_with_re2
    r = RE2("o")
    assert_equal "wii", RE2::GlobalReplace("woo", r, "i")

    assert_equal "waa", RE2::GlobalReplace("woo", RE2("o"), "a")
    assert_equal "hoo", RE2::GlobalReplace("woo", RE2("w"), "h")
    assert_equal "we", RE2::GlobalReplace("woo", RE2("o+"), "e")
  end

  def test_quote_meta
    assert_equal "1\\.5\\-2\\.0\\?", RE2::QuoteMeta("1.5-2.0?")
    assert_equal "1\\.5\\-2\\.0\\?", RE2::Regexp.escape("1.5-2.0?")
    assert_equal "1\\.5\\-2\\.0\\?", RE2::Regexp.quote("1.5-2.0?")
  end

  def test_re2_error
    r = RE2("woo")
    assert_equal "", r.error
    assert_equal "", r.error_arg
  end

  def test_re2_error_with_error
    r = RE2("wo(o", :log_errors => false)
    assert !r.ok?
    assert_equal "missing ): wo(o", r.error
    assert_equal "wo(o", r.error_arg
  end
end
