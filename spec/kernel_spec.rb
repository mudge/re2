require "spec_helper"

describe Kernel do
  describe "#RE2" do
    it "returns an RE2::Regexp instance given a pattern" do
      RE2('w(o)(o)').must_be_instance_of(RE2::Regexp)
    end

    it "returns an RE2::Regexp instance given a pattern and options" do
      re = RE2('w(o)(o)', :case_sensitive => false)
      re.must_be_instance_of(RE2::Regexp)
      re.wont_be(:case_sensitive?)
    end
  end
end
