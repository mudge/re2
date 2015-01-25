require "spec_helper"

describe RE2 do
  describe "#Replace" do
    it "only replaces the first occurrence of the pattern" do
      RE2.Replace("woo", "o", "a").must_equal("wao")
    end

    it "performs replacement based on regular expressions" do
      RE2.Replace("woo", "o+", "e").must_equal("we")
    end

    it "supports flags in patterns" do
      RE2.Replace("Good morning", "(?i)gOOD MORNING", "hi").must_equal("hi")
    end

    it "does not perform replacements in-place" do
      name = "Robert"
      replacement = RE2.Replace(name, "R", "Cr")
      replacement.must_equal("Crobert")
      name.wont_be_same_as(replacement)
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2}')
      RE2.Replace("woo", re, "miaow").must_equal("miaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', :case_sensitive => false)
      RE2.Replace("Good morning", re, "hi").must_equal("hi")
    end

    if String.method_defined?(:encoding)
      it "preserves the original string's encoding" do
        original = "Foo"
        replacement = RE2.Replace(original, "oo", "ah")
        original.encoding.must_equal(replacement.encoding)
      end
    end
  end

  describe "#GlobalReplace" do
    it "replaces every occurrence of a pattern" do
      RE2.GlobalReplace("woo", "o", "a").must_equal("waa")
    end

    it "performs replacement based on regular expressions" do
      RE2.GlobalReplace("woohoo", "o+", "e").must_equal("wehe")
    end

    it "supports flags in patterns" do
      RE2.GlobalReplace("Robert", "(?i)r", "w").must_equal("wobewt")
    end

    it "does not perform replacement in-place" do
      name = "Robert"
      replacement = RE2.GlobalReplace(name, "(?i)R", "w")
      replacement.must_equal("wobewt")
      name.wont_be_same_as(replacement)
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2,}')
      RE2.GlobalReplace("woowooo", re, "miaow").must_equal("miaowmiaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', :case_sensitive => false)
      RE2.GlobalReplace("Good morning Good morning", re, "hi").must_equal("hi hi")
    end
  end

  describe "#QuoteMeta" do
    it "escapes a string so it can be used as a regular expression" do
      RE2.QuoteMeta("1.5-2.0?").must_equal('1\.5\-2\.0\?')
    end
  end
end
