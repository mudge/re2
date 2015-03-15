RSpec.describe RE2::Scanner do
  describe "#regexp" do
    it "returns the original pattern for the scanner" do
      re = RE2::Regexp.new('(\w+)')
      scanner = re.scan("It is a truth")

      expect(scanner.regexp).to equal(re)
    end
  end

  describe "#string" do
    it "returns the original text for the scanner" do
      re = RE2::Regexp.new('(\w+)')
      text = "It is a truth"
      scanner = re.scan(text)

      expect(scanner.string).to equal(text)
    end
  end

  describe "#scan" do
    it "returns the next array of matches" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It is a truth universally acknowledged")
      expect(scanner.scan).to eq(["It"])
      expect(scanner.scan).to eq(["is"])
      expect(scanner.scan).to eq(["a"])
      expect(scanner.scan).to eq(["truth"])
      expect(scanner.scan).to eq(["universally"])
      expect(scanner.scan).to eq(["acknowledged"])
      expect(scanner.scan).to be_nil
    end

    it "returns an empty array if there are no capturing groups" do
      r = RE2::Regexp.new('\w+')
      scanner = r.scan("Foo bar")
      expect(scanner.scan).to eq([])
    end

    it "returns nil if there is no match" do
      r = RE2::Regexp.new('\d+')
      scanner = r.scan("Foo bar")
      expect(scanner.scan).to be_nil
    end
  end

  it "is enumerable" do
    r = RE2::Regexp.new('(\d)')
    scanner = r.scan("There are 1 some 2 numbers 3")
    expect(scanner).to be_a(Enumerable)
  end

  describe "#each" do
    it "yields each match" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")
      matches = []
      scanner.each do |match|
        matches << match
      end

      expect(matches).to eq([["1"], ["2"], ["3"]])
    end

    it "returns an enumerator when not given a block" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")

      # Prior to Ruby 1.9, Enumerator was within Enumerable.
      if defined?(Enumerator)
        expect(scanner.each).to be_a(Enumerator)
      elsif defined?(Enumerable::Enumerator)
        expect(scanner.each).to be_a(Enumerable::Enumerator)
      end
    end
  end

  describe "#rewind" do
    it "resets any consumption" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")
      expect(scanner.to_enum.first).to eq(["1"])
      expect(scanner.to_enum.first).to eq(["2"])
      scanner.rewind
      expect(scanner.to_enum.first).to eq(["1"])
    end
  end
end
