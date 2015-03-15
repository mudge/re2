RSpec.describe Kernel do
  describe "#RE2" do
    it "returns an RE2::Regexp instance given a pattern" do
      expect(RE2('w(o)(o)')).to be_a(RE2::Regexp)
    end

    it "returns an RE2::Regexp instance given a pattern and options" do
      re = RE2('w(o)(o)', :case_sensitive => false)
      expect(re).to be_a(RE2::Regexp)
      expect(re).to_not be_case_sensitive
    end
  end
end
