require "spec_helper"

describe RE2::Scanner do
  describe "#regexp" do
    it "returns the original pattern for the scanner" do
      re = RE2::Regexp.new('(\w+)')
      scanner = re.scan("It is a truth")

      scanner.regexp.must_be_same_as(re)
    end
  end

  describe "#string" do
    it "returns the original text for the scanner" do
      re = RE2::Regexp.new('(\w+)')
      text = "It is a truth"
      scanner = re.scan(text)

      scanner.string.must_be_same_as(text)
    end
  end

  describe "#scan" do
    it "returns the next array of matches" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It is a truth universally acknowledged")
      scanner.scan.must_equal(["It"])
      scanner.scan.must_equal(["is"])
      scanner.scan.must_equal(["a"])
      scanner.scan.must_equal(["truth"])
      scanner.scan.must_equal(["universally"])
      scanner.scan.must_equal(["acknowledged"])
      scanner.scan.must_be_nil
    end

    it "returns an empty array if there are no capturing groups" do
      r = RE2::Regexp.new('\w+')
      scanner = r.scan("Foo bar")
      scanner.scan.must_equal([])
    end

    it "returns nil if there is no match" do
      r = RE2::Regexp.new('\d+')
      scanner = r.scan("Foo bar")
      scanner.scan.must_be_nil
    end
  end

  it "is enumerable" do
    r = RE2::Regexp.new('(\d)')
    scanner = r.scan("There are 1 some 2 numbers 3")
    scanner.must_be_kind_of(Enumerable)
  end

  describe "#each" do
    it "yields each match" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")
      matches = []
      scanner.each do |match|
        matches << match
      end

      matches.must_equal([["1"], ["2"], ["3"]])
    end

    it "returns an enumerator when not given a block" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")

      # Prior to Ruby 1.9, Enumerator was within Enumerable.
      if defined?(Enumerator)
        scanner.each.must_be_kind_of(Enumerator)
      elsif defined?(Enumerable::Enumerator)
        scanner.each.must_be_kind_of(Enumerable::Enumerator)
      end
    end
  end

  describe "#rewind" do
    it "resets any consumption" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")
      scanner.to_enum.first.must_equal(["1"])
      scanner.to_enum.first.must_equal(["2"])
      scanner.rewind
      scanner.to_enum.first.must_equal(["1"])
    end
  end
end
