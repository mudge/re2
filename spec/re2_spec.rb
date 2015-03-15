RSpec.describe RE2 do
  describe "#Replace" do
    it "only replaces the first occurrence of the pattern" do
      expect(RE2.Replace("woo", "o", "a")).to eq("wao")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.Replace("woo", "o+", "e")).to eq("we")
    end

    it "supports flags in patterns" do
      expect(RE2.Replace("Good morning", "(?i)gOOD MORNING", "hi")).to eq("hi")
    end

    it "does not perform replacements in-place" do
      name = "Robert"
      replacement = RE2.Replace(name, "R", "Cr")
      expect(name).to_not equal(replacement)
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2}')
      expect(RE2.Replace("woo", re, "miaow")).to eq("miaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', :case_sensitive => false)
      expect(RE2.Replace("Good morning", re, "hi")).to eq("hi")
    end

    if String.method_defined?(:encoding)
      it "preserves the original string's encoding" do
        original = "Foo"
        replacement = RE2.Replace(original, "oo", "ah")
        expect(original.encoding).to eq(replacement.encoding)
      end
    end
  end

  describe "#GlobalReplace" do
    it "replaces every occurrence of a pattern" do
      expect(RE2.GlobalReplace("woo", "o", "a")).to eq("waa")
    end

    it "performs replacement based on regular expressions" do
      expect(RE2.GlobalReplace("woohoo", "o+", "e")).to eq("wehe")
    end

    it "supports flags in patterns" do
      expect(RE2.GlobalReplace("Robert", "(?i)r", "w")).to eq("wobewt")
    end

    it "does not perform replacement in-place" do
      name = "Robert"
      replacement = RE2.GlobalReplace(name, "(?i)R", "w")
      expect(name).to_not equal(replacement)
    end

    it "supports passing an RE2::Regexp as the pattern" do
      re = RE2::Regexp.new('wo{2,}')
      expect(RE2.GlobalReplace("woowooo", re, "miaow")).to eq("miaowmiaow")
    end

    it "respects any passed RE2::Regexp's flags" do
      re = RE2::Regexp.new('gOOD MORNING', :case_sensitive => false)
      expect(RE2.GlobalReplace("Good morning Good morning", re, "hi")).to eq("hi hi")
    end
  end

  describe "#QuoteMeta" do
    it "escapes a string so it can be used as a regular expression" do
      expect(RE2.QuoteMeta("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end
  end
end
