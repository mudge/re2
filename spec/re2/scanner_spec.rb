# encoding: utf-8

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

    it "returns an empty array if the input is empty" do
      r = RE2::Regexp.new("")
      scanner = r.scan("")
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to be_nil
    end

    it "returns an array of nil with an empty input and capture" do
      r = RE2::Regexp.new("()")
      scanner = r.scan("")
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to be_nil
    end

    it "returns an empty array for every match if the pattern is empty" do
      r = RE2::Regexp.new("")
      scanner = r.scan("Foo")
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to be_nil
    end

    it "returns an array of nil if the pattern is an empty capturing group" do
      r = RE2::Regexp.new("()")
      scanner = r.scan("Foo")
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to be_nil
    end

    it "returns array of nils with multiple empty capturing groups" do
      r = RE2::Regexp.new("()()()")
      scanner = r.scan("Foo")
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to be_nil
    end

    it "supports empty groups with multibyte characters" do
      r = RE2::Regexp.new("()€")
      scanner = r.scan("€")
      expect(scanner.scan).to eq([nil])
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

    it "resets the eof? check" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1")
      scanner.scan
      expect(scanner.eof?).to be_truthy
      scanner.rewind
      expect(scanner.eof?).to be_falsey
    end
  end

  describe "#eof?" do
    it "returns false if the input has not been consumed" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1 2 3")

      expect(scanner.eof?).to be_falsey
    end

    it "returns true if the input has been consumed" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1")
      scanner.scan

      expect(scanner.eof?).to be_truthy
    end

    it "returns false if no match is made" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("a")
      scanner.scan

      expect(scanner.eof?).to be_falsey
    end

    it "returns false with an empty input that has not been scanned" do
      r = RE2::Regexp.new("")
      scanner = r.scan("")

      expect(scanner.eof?).to be_falsey
    end

    it "returns false with an empty input that has not been matched" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("")
      scanner.scan

      expect(scanner.eof?).to be_falsey
    end

    it "returns true with an empty input that has been matched" do
      r = RE2::Regexp.new("")
      scanner = r.scan("")
      scanner.scan

      expect(scanner.eof?).to be_truthy
    end
  end
end
