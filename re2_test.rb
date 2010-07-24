require File.join(File.dirname(__FILE__), "re2")
require "test/unit"

class RE2Test < Test::Unit::TestCase
  def test_interface
    assert_respond_to RE2, :FullMatch
    assert_respond_to RE2, :PartialMatch
    assert_respond_to RE2, :Replace
    assert_respond_to RE2, :GlobalReplace
  end

  def test_full_match
    assert RE2::FullMatch("woo", "woo")
    assert RE2::FullMatch("woo", "wo+")
    assert RE2::FullMatch("woo", "woo?")
    assert RE2::FullMatch("woo", "wo{2}")
    assert !RE2::FullMatch("woo", "wowzer")
  end

  def test_partial_match
    assert RE2::PartialMatch("woo", "oo")
    assert RE2::PartialMatch("woo", "oo?")
    assert RE2::PartialMatch("woo", "o{2}")
    assert !RE2::PartialMatch("woo", "ha")
  end

  def test_replace
    assert_equal "wao", RE2::Replace("woo", "o", "a")
    assert_equal "hoo", RE2::Replace("woo", "w", "h")
    assert_equal "we", RE2::Replace("woo", "o+", "e")

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
end
