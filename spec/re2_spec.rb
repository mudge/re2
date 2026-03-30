# frozen_string_literal: true

RSpec.describe RE2 do
  describe ".replace" do
    it "only replaces the first occurrence of the pattern" do
      expect(RE2.replace("woo", "o", "a")).to eq("wao")
    end

    it "supports inputs with null bytes" do
      expect(RE2.replace("w\0oo", "o", "a")).to eq("w\0ao")
    end

    it "supports patterns with null bytes" do
      expect(RE2.replace("w\0oo", "\0", "o")).to eq("wooo")
    end

    it "supports replacements with null bytes" do
      expect(RE2.replace("woo", "o", "\0")).to eq("w\0o")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.replace("woo", "o+", "e")).to eq("we")
    end

    it "supports flags in patterns" do
      expect(RE2.replace("Good morning", "(?i)gOOD MORNING", "hi")).to eq("hi")
    end

    it "does not perform replacements in-place", :aggregate_failures do
      name = "Robert"
      replacement = RE2.replace(name, "R", "Cr")

      expect(name).to eq("Robert")
      expect(replacement).to eq("Crobert")
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2}')

      expect(RE2.replace("woo", re, "miaow")).to eq("miaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', case_sensitive: false)

      expect(RE2.replace("Good morning", re, "hi")).to eq("hi")
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.replace(StringLike.new("woo"), "oo", "ah")).to eq("wah")
    end

    it "supports passing something that can be coerced to a String as a pattern" do
      expect(RE2.replace("woo", StringLike.new("oo"), "ah")).to eq("wah")
    end

    it "supports passing something that can be coerced to a String as a replacement" do
      expect(RE2.replace("woo", "oo", StringLike.new("ah"))).to eq("wah")
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      original = "Foo".encode("ISO-8859-1")
      replacement = RE2.replace(original, "oo", "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      original = "Foo"
      replacement = RE2.replace(original, RE2("oo", utf8: false), "ah")

      expect(replacement.encoding).to eq(Encoding::ISO_8859_1)
    end

    it "returns UTF-8 strings when given a String pattern" do
      replacement = RE2.replace("Foo", "oo".encode("ISO-8859-1"), "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.replace(0, "oo", "ah") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a non-RE2::Regexp pattern that can't be converted to String" do
      expect { RE2.replace("woo", 0, "ah") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a replacement that can't be converted to String" do
      expect { RE2.replace("woo", "oo", 0) }.to raise_error(TypeError)
    end
  end

  describe ".Replace" do
    it "is an alias for .replace" do
      expect(RE2.Replace("woo", "o", "a")).to eq("wao")
    end
  end

  describe ".global_replace" do
    it "replaces every occurrence of a pattern" do
      expect(RE2.global_replace("woo", "o", "a")).to eq("waa")
    end

    it "supports inputs with null bytes" do
      expect(RE2.global_replace("w\0oo", "o", "a")).to eq("w\0aa")
    end

    it "supports patterns with null bytes" do
      expect(RE2.global_replace("w\0\0oo", "\0", "a")).to eq("waaoo")
    end

    it "supports replacements with null bytes" do
      expect(RE2.global_replace("woo", "o", "\0")).to eq("w\0\0")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.global_replace("woohoo", "o+", "e")).to eq("wehe")
    end

    it "supports flags in patterns" do
      expect(RE2.global_replace("Robert", "(?i)r", "w")).to eq("wobewt")
    end

    it "does not perform replacement in-place", :aggregate_failures do
      name = "Robert"
      replacement = RE2.global_replace(name, "(?i)R", "w")

      expect(name).to eq("Robert")
      expect(replacement).to eq("wobewt")
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2,}')

      expect(RE2.global_replace("woowooo", re, "miaow")).to eq("miaowmiaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', case_sensitive: false)

      expect(RE2.global_replace("Good morning Good morning", re, "hi")).to eq("hi hi")
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.global_replace(StringLike.new("woo"), "o", "a")).to eq("waa")
    end

    it "supports passing something that can be coerced to a String as a pattern" do
      expect(RE2.global_replace("woo", StringLike.new("o"), "a")).to eq("waa")
    end

    it "supports passing something that can be coerced to a String as a replacement" do
      expect(RE2.global_replace("woo", "o", StringLike.new("a"))).to eq("waa")
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      original = "Foo".encode("ISO-8859-1")
      replacement = RE2.global_replace(original, "oo", "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      original = "Foo"
      replacement = RE2.global_replace(original, RE2("oo", utf8: false), "ah")

      expect(replacement.encoding).to eq(Encoding::ISO_8859_1)
    end

    it "returns UTF-8 strings when given a String pattern" do
      replacement = RE2.global_replace("Foo", "oo".encode("ISO-8859-1"), "ah")

      expect(replacement.encoding).to eq(Encoding::UTF_8)
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.global_replace(0, "o", "a") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a non-RE2::Regexp pattern that can't be converted to String" do
      expect { RE2.global_replace("woo", 0, "a") }.to raise_error(TypeError)
    end

    it "raises a Type Error for a replacement that can't be converted to String" do
      expect { RE2.global_replace("woo", "o", 0) }.to raise_error(TypeError)
    end
  end

  describe ".GlobalReplace" do
    it "is an alias for .global_replace" do
      expect(RE2.GlobalReplace("woo", "o", "a")).to eq("waa")
    end
  end

  describe ".extract" do
    it "extracts a rewrite of the first match" do
      expect(RE2.extract("alice@example.com", '(\w+)@(\w+)', '\2-\1')).to eq("example-alice")
    end

    it "returns nil if there is no match" do
      expect(RE2.extract("no match", '(\d+)', '\1')).to be_nil
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('(\w+)@(\w+)')

      expect(RE2.extract("alice@example.com", re, '\2-\1')).to eq("example-alice")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('(hello)', case_sensitive: false)

      expect(RE2.extract("Hello", re, '\1')).to eq("Hello")
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      re = RE2::Regexp.new('(foo)')
      result = RE2.extract("foo", re, '\1')

      expect(result.encoding.name).to eq("UTF-8")
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      re = RE2::Regexp.new('(foo)', utf8: false)
      result = RE2.extract("foo", re, '\1')

      expect(result.encoding.name).to eq("ISO-8859-1")
    end

    it "returns UTF-8 strings when given a String pattern" do
      result = RE2.extract("foo", '(foo)', '\1')

      expect(result.encoding.name).to eq("UTF-8")
    end

    it "supports inputs with null bytes" do
      expect(RE2.extract("ab\0cd", '(a.*d)', '\1')).to eq("ab\0cd")
    end

    it "supports patterns with null bytes" do
      expect(RE2.extract("ab\0cd", "(b\0c)", '\1')).to eq("b\0c")
    end

    it "supports rewrites with null bytes" do
      expect(RE2.extract("abcd", '(bc)', "x\0\\1")).to eq("x\0bc")
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.extract(StringLike.new("bob123"), '(\d+)', '\1')).to eq("123")
    end

    it "supports passing something that can be coerced to a String as a pattern" do
      expect(RE2.extract("bob123", StringLike.new('(\d+)'), '\1')).to eq("123")
    end

    it "supports passing something that can be coerced to a String as a rewrite" do
      expect(RE2.extract("bob123", '(\d+)', StringLike.new('\1'))).to eq("123")
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.extract(0, '(\d+)', '\1') }.to raise_error(TypeError)
    end

    it "raises a Type Error for a non-RE2::Regexp pattern that can't be converted to String" do
      expect { RE2.extract("woo", 0, '\1') }.to raise_error(TypeError)
    end

    it "raises a Type Error for a rewrite that can't be converted to String" do
      expect { RE2.extract("woo", '(\w+)', 0) }.to raise_error(TypeError)
    end
  end

  describe "#escape" do
    it "escapes a string so it can be used as a regular expression" do
      expect(RE2.escape("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end

    it "raises a Type Error for input that can't be converted to String" do
      expect { RE2.escape(0) }.to raise_error(TypeError)
    end

    it "supports passing something that can be coerced to a String as input" do
      expect(RE2.escape(StringLike.new("1.5"))).to eq('1\.5')
    end

    it "supports strings containing null bytes" do
      expect(RE2.escape("abc\0def")).to eq('abc\x00def')
    end
  end

  describe ".quote" do
    it "is an alias for .escape" do
      expect(RE2.quote("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end
  end

  describe ".QuoteMeta" do
    it "is an alias for .escape" do
      expect(RE2.QuoteMeta("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end
  end
end
