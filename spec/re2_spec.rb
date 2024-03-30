# frozen_string_literal: true

RSpec.describe RE2 do
  describe ".Replace" do
    it "only replaces the first occurrence of the pattern" do
      expect(RE2.Replace("woo", "o", "a")).to eq("wao")
    end

    it "supports inputs with null bytes" do
      expect(RE2.Replace("w\0oo", "o", "a")).to eq("w\0ao")
    end

    it "supports patterns with null bytes" do
      expect(RE2.Replace("w\0oo", "\0", "o")).to eq("wooo")
    end

    it "supports replacements with null bytes" do
      expect(RE2.Replace("woo", "o", "\0")).to eq("w\0o")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.Replace("woo", "o+", "e")).to eq("we")
    end

    it "supports flags in patterns" do
      expect(RE2.Replace("Good morning", "(?i)gOOD MORNING", "hi")).to eq("hi")
    end

    it "does not perform replacements in-place", :aggregate_failures do
      name = "Robert"
      replacement = RE2.Replace(name, "R", "Cr")

      expect(name).to eq("Robert")
      expect(replacement).to eq("Crobert")
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2}')

      expect(RE2.Replace("woo", re, "miaow")).to eq("miaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', case_sensitive: false)

      expect(RE2.Replace("Good morning", re, "hi")).to eq("hi")
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.Replace(StringLike.new("woo"), "oo", "ah")).to eq("wah")
    end

    it "supports passing something that can be coerced to a String as a pattern" do
      expect(RE2.Replace("woo", StringLike.new("oo"), "ah")).to eq("wah")
    end

    it "supports passing something that can be coerced to a String as a replacement" do
      expect(RE2.Replace("woo", "oo", StringLike.new("ah"))).to eq("wah")
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      original = "Foo".encode("ISO-8859-1")
      replacement = RE2.Replace(original, "oo", "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      original = "Foo"
      replacement = RE2.Replace(original, RE2("oo", utf8: false), "ah")

      expect(replacement.encoding).to eq(Encoding::ISO_8859_1)
    end

    it "returns UTF-8 strings when given a String pattern" do
      replacement = RE2.Replace("Foo", "oo".encode("ISO-8859-1"), "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.Replace(0, "oo", "ah") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a non-RE2::Regexp pattern that can't be converted to String" do
      expect { RE2.Replace("woo", 0, "ah") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a replacement that can't be converted to String" do
      expect { RE2.Replace("woo", "oo", 0) }.to raise_error(TypeError)
    end
  end

  describe ".GlobalReplace" do
    it "replaces every occurrence of a pattern" do
      expect(RE2.GlobalReplace("woo", "o", "a")).to eq("waa")
    end

    it "supports inputs with null bytes" do
      expect(RE2.GlobalReplace("w\0oo", "o", "a")).to eq("w\0aa")
    end

    it "supports patterns with null bytes" do
      expect(RE2.GlobalReplace("w\0\0oo", "\0", "a")).to eq("waaoo")
    end

    it "supports replacements with null bytes" do
      expect(RE2.GlobalReplace("woo", "o", "\0")).to eq("w\0\0")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.GlobalReplace("woohoo", "o+", "e")).to eq("wehe")
    end

    it "supports flags in patterns" do
      expect(RE2.GlobalReplace("Robert", "(?i)r", "w")).to eq("wobewt")
    end

    it "does not perform replacement in-place", :aggregate_failures do
      name = "Robert"
      replacement = RE2.GlobalReplace(name, "(?i)R", "w")

      expect(name).to eq("Robert")
      expect(replacement).to eq("wobewt")
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2,}')

      expect(RE2.GlobalReplace("woowooo", re, "miaow")).to eq("miaowmiaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', case_sensitive: false)

      expect(RE2.GlobalReplace("Good morning Good morning", re, "hi")).to eq("hi hi")
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.GlobalReplace(StringLike.new("woo"), "o", "a")).to eq("waa")
    end

    it "supports passing something that can be coerced to a String as a pattern" do
      expect(RE2.GlobalReplace("woo", StringLike.new("o"), "a")).to eq("waa")
    end

    it "supports passing something that can be coerced to a String as a replacement" do
      expect(RE2.GlobalReplace("woo", "o", StringLike.new("a"))).to eq("waa")
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      original = "Foo".encode("ISO-8859-1")
      replacement = RE2.GlobalReplace(original, "oo", "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      original = "Foo"
      replacement = RE2.GlobalReplace(original, RE2("oo", utf8: false), "ah")

      expect(replacement.encoding).to eq(Encoding::ISO_8859_1)
    end

    it "returns UTF-8 strings when given a String pattern" do
      replacement = RE2.GlobalReplace("Foo", "oo".encode("ISO-8859-1"), "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.GlobalReplace(0, "o", "a") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a non-RE2::Regexp pattern that can't be converted to String" do
      expect { RE2.GlobalReplace("woo", 0, "a") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a replacement that can't be converted to String" do
      expect { RE2.GlobalReplace("woo", "o", 0) }.to raise_error(TypeError)
    end
  end

  describe "#QuoteMeta" do
    it "escapes a string so it can be used as a regular expression" do
      expect(RE2.QuoteMeta("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.QuoteMeta(0) }.to raise_error(TypeError)
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.QuoteMeta(StringLike.new("1.5"))).to eq('1\.5')
    end

    it "supports strings containing null bytes" do
      expect(RE2.QuoteMeta("abc\0def")).to eq('abc\x00def')
    end
  end
end
