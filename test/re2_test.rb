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
    assert_respond_to RE2, :FullMatch
    assert_respond_to RE2, :FullMatchN
    assert_respond_to RE2, :PartialMatch
    assert_respond_to RE2, :PartialMatchN
    assert_respond_to RE2, :Replace
    assert_respond_to RE2, :GlobalReplace
    assert_respond_to RE2, :QuoteMeta
    assert_respond_to RE2, :escape
    assert_respond_to RE2, :quote
    assert_respond_to RE2, :new
    assert_respond_to RE2, :compile

    r = RE2.new('woo')
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
    assert_kind_of RE2, r
    assert_respond_to r, :ok?
  end

  def test_re2_compile
    r = RE2.compile('w(o)(o)')
    assert_kind_of RE2, r
    assert_respond_to r, :ok?
  end

  def test_full_match
    assert RE2::FullMatch("woo", "woo")
    assert RE2::FullMatch("woo", "wo+")
    assert RE2::FullMatch("woo", "woo?")
    assert RE2::FullMatch("woo", "wo{2}")
    assert !RE2::FullMatch("woo", "wowzer")
  end

  def test_full_match_n
    assert_equal ["oo"], RE2::FullMatchN("woo", "w(oo)")
    assert_equal ["12"], RE2::FullMatchN("woo12w", 'woo(\d{2})w')
    assert_equal [nil, "1", "234"], RE2::FullMatchN("w1234", 'w(a?)(\d)(\d+)')
    assert_nil RE2::FullMatchN("bob", 'w(\d+)')
  end

  def test_full_match_n_with_compiled_pattern
    assert_equal ["oo"], RE2::FullMatchN("woo", RE2.new("w(oo)"))
    assert_equal ["12"], RE2::FullMatchN("woo12w", RE2.new('woo(\d{2})w'))
    assert_equal [nil, "1", "234"], RE2::FullMatchN("w1234", RE2.new('w(a?)(\d)(\d+)'))
    assert_nil RE2::FullMatchN("bob", RE2.new('w(\d+)'))
  end

  def test_partial_match
    assert RE2::PartialMatch("woo", "oo")
    assert RE2::PartialMatch("woo", "oo?")
    assert RE2::PartialMatch("woo", "o{2}")
    assert !RE2::PartialMatch("woo", "ha")
  end

  def test_partial_match_n
    assert_equal ["oo"], RE2::PartialMatchN("awooa", "w(oo)")
    assert_equal ["12"], RE2::PartialMatchN("awoo12wa", 'woo(\d{2})w')
    assert_equal [nil, "1", "234"], RE2::PartialMatchN("aw1234a", 'w(a?)(\d)(\d+)')
    assert_nil RE2::PartialMatchN("bob", 'w(\d+)')
  end

  def test_partial_match_n_with_compiled_pattern
    assert_equal ["oo"], RE2::PartialMatchN("awooa", RE2.new("w(oo)"))
    assert_equal ["12"], RE2::PartialMatchN("awoo12wa", RE2.new('woo(\d{2})w'))
    assert_equal [nil, "1", "234"], RE2::PartialMatchN("aw1234a", RE2.new('w(a?)(\d)(\d+)'))
    assert_nil RE2::PartialMatchN("bob", RE2.new('w(\d+)'))
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

  def test_compiling
    r = RE2.new("woo")
    assert r.ok?
    assert_equal "/woo/", r.inspect
    assert_equal "woo", r.to_s
  end

  def test_number_of_capturing_groups
    assert_equal 3, RE2.new('(a)(b)(c)').number_of_capturing_groups
    assert_equal 0, RE2.new('abc').number_of_capturing_groups
    assert_equal 2, RE2.new('a((b)c)').number_of_capturing_groups
  end

  def test_matching_all_subpatterns
    assert_equal ["woo", "o", "o"], RE2.new('w(o)(o)').match('woo')
    assert_equal ["ab", nil, "a", "b"], RE2.new('(\d?)(a)(b)').match('ab')
  end

  def test_matching_no_subpatterns
    assert RE2.new('woo').match('woo', 0)
    assert !RE2.new('bob').match('woo', 0)
    assert RE2.new('woo').match?('woo')
    assert !RE2.new('bob').match?('woo')
    assert RE2.new('woo') =~ 'woo'
    assert !(RE2.new('bob') =~ 'woo')
    assert !(RE2.new('woo') !~ 'woo')
    assert RE2.new('bob') !~ 'woo'
    assert RE2.new('woo') === 'woo'
    assert !(RE2.new('bob') === 'woo')
  end

  def test_matching_some_sub_patterns
    assert_equal ["woo", "o"], RE2.new('w(o)(o)').match('woo', 1)
    assert_equal ["woo", "o", "o"], RE2.new('w(o)(o)').match('woo', 2)
    assert_equal ["woo", "o", "o", nil], RE2.new('w(o)(o)').match('woo', 3)
  end

  def test_compiling_with_options
    r = RE2.new("woo", :case_sensitive => false)
    assert r.ok?
    assert RE2::FullMatch("woo", r)
    assert RE2::FullMatch("WOO", r)
    assert !r.options[:case_sensitive]
    assert r.case_insensitive?
    assert r.casefold?
    assert !r.case_sensitive?
    assert r.utf8?
    assert r.options[:utf8]
  end

  def test_full_match_with_re2
    r = RE2.new("woo")
    assert RE2::FullMatch("woo", r)
    assert !RE2::FullMatch("wowzer", r)
  end

  def test_partial_match_with_re2
    r = RE2.new("woo")
    assert RE2::PartialMatch("woo", r)
    assert !RE2::PartialMatch("wowzer", r)
  end

  def test_replace_with_re2
    r = RE2.new("wo{2}")
    assert_equal "miaow", RE2::Replace("woo", r, "miaow")
  end

  def test_global_replace_with_re2
    r = RE2.new("o")
    assert_equal "wii", RE2::GlobalReplace("woo", r, "i")
  end

  def test_quote_meta
    assert_equal "1\\.5\\-2\\.0\\?", RE2::QuoteMeta("1.5-2.0?")
    assert_equal "1\\.5\\-2\\.0\\?", RE2.escape("1.5-2.0?")
    assert_equal "1\\.5\\-2\\.0\\?", RE2.quote("1.5-2.0?")
  end

  def test_re2_error
    r = RE2.new("woo")
    assert_equal "", r.error
    assert_equal "", r.error_arg
  end

  def test_re2_error_with_error
    r = RE2.new("wo(o", :log_errors => false)
    assert !r.ok?
    assert_equal "missing ): wo(o", r.error
    assert_equal "wo(o", r.error_arg
  end
end
