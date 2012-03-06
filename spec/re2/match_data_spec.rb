require "spec_helper"

describe RE2::MatchData do

  describe "#to_a" do
    it "is populated with the match and capturing groups" do
      a = RE2::Regexp.new('w(o)(o)').match('woo').to_a
      a.must_equal(["woo", "o", "o"])
    end

    it "populates optional capturing groups with nil if they are missing" do
      a = RE2::Regexp.new('(\d?)(a)(b)').match('ab').to_a
      a.must_equal(["ab", nil, "a", "b"])
    end
  end

  describe "#[]" do
    it "accesses capturing groups by numerical index" do
      md = RE2::Regexp.new('(\d)(\d{2})').match("123")
      md[1].must_equal("1")
      md[2].must_equal("23")
    end

    it "has the whole match as the 0th item" do
      md = RE2::Regexp.new('(\d)(\d{2})').match("123")
      md[0].must_equal("123")
    end

    it "supports access by numerical ranges" do
      md = RE2::Regexp.new('(\d+) (\d+) (\d+)').match("123 456 789")
      md[1..3].must_equal(["123", "456", "789"])
      md[1...3].must_equal(["123", "456"])
    end

    it "supports slicing" do
      md = RE2::Regexp.new('(\d+) (\d+) (\d+)').match("123 456 789")
      md[1, 3].must_equal(["123", "456", "789"])
      md[1, 2].must_equal(["123", "456"])
    end

    it "returns nil if attempting to access non-existent capturing groups by index" do
      md = RE2::Regexp.new('(\d+)').match('bob 123')
      md[2].must_be_nil
      md[3].must_be_nil
    end

    it "allows access by string names when there are named groups" do
      md = RE2::Regexp.new('(?P<numbers>\d+)').match('bob 123')
      md["numbers"].must_equal("123")
    end

    it "allows access by symbol names when there are named groups" do
      md = RE2::Regexp.new('(?P<numbers>\d+)').match('bob 123')
      md[:numbers].must_equal("123")
    end

    it "allows access by names and indices with mixed groups" do
      md = RE2::Regexp.new('(?P<name>\w+)(\s*)(?P<numbers>\d+)').match("bob 123")
      md["name"].must_equal("bob")
      md[:name].must_equal("bob")
      md[2].must_equal(" ")
      md["numbers"].must_equal("123")
      md[:numbers].must_equal("123")
    end

    it "returns nil if no such named group exists" do
      md = RE2::Regexp.new('(\d+)').match("bob 123")
      md["missing"].must_be_nil
      md[:missing].must_be_nil
    end
  end

  describe "#string" do
    it "returns the original string to match against" do
      re = RE2::Regexp.new('(\D+)').match("bob")
      re.string.must_equal("bob")
    end

    it "returns a copy, not the actual original" do
      string = "bob"
      re = RE2::Regexp.new('(\D+)').match(string)
      re.string.wont_be_same_as(string)
    end

    it "returns a frozen string" do
      re = RE2::Regexp.new('(\D+)').match("bob")
      re.string.must_be(:frozen?)
    end
  end

  describe "#size" do
    it "returns the number of capturing groups plus the matching string" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")
      md.size.must_equal(3)
    end
  end

  describe "#length" do
    it "returns the number of capturing groups plus the matching string" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")
      md.length.must_equal(3)
    end
  end

  describe "#regexp" do
    it "returns the original RE2::Regexp used" do
      re = RE2::Regexp.new('(\d+)')
      md = re.match("123")
      md.regexp.must_be_same_as(re)
    end
  end

  describe "#inspect" do
    it "returns a text representation of the object and indices" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")
      md.inspect.must_equal('#<RE2::MatchData "1234 56" 1:"1234" 2:"56">')
    end

    it "represents missing matches as nil" do
      md = RE2::Regexp.new('(\d+) (\d+)?').match("1234 ")
      md.inspect.must_equal('#<RE2::MatchData "1234 " 1:"1234" 2:nil>')
    end
  end

  describe "#to_s" do
    it "returns the matching part of the original string" do
      md = RE2::Regexp.new('(\d{2,5})').match("one two 23456")
      md.to_s.must_equal("23456")
    end
  end

  describe "#to_ary" do
    it "allows the object to be expanded with an asterisk" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")
      m1, m2, m3 = *md
      m1.must_equal("1234 56")
      m2.must_equal("1234")
      m3.must_equal("56")
    end
  end
end
