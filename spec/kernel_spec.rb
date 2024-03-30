# frozen_string_literal: true

RSpec.describe Kernel do
  describe ".RE2" do
    it "returns an RE2::Regexp instance given a pattern" do
      expect(RE2('w(o)(o)')).to be_a(RE2::Regexp)
    end

    it "returns an RE2::Regexp instance given a pattern and options" do
      re = RE2('w(o)(o)', case_sensitive: false)

      expect(re).not_to be_case_sensitive
    end

    it "accepts patterns containing null bytes" do
      re = RE2("a\0b")

      expect(re.pattern).to eq("a\0b")
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2(nil) }.to raise_error(TypeError)
    end

    it "allows invalid patterns to be created" do
      re = RE2('???', log_errors: false)

      expect(re).to be_a(RE2::Regexp)
    end

    it "supports passing something that can be coerced to a String as input" do
      re = RE2(StringLike.new('w(o)(o)'))

      expect(re).to be_a(RE2::Regexp)
    end
  end
end
