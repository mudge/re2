# frozen_string_literal: true

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
    it "returns the next array of matches", :aggregate_failures do
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

    it "supports scanning inputs with null bytes", :aggregate_failures do
      r = RE2::Regexp.new("(\\w\0\\w)")
      scanner = r.scan("a\0b c\0d e\0f")

      expect(scanner.scan).to eq(["a\0b"])
      expect(scanner.scan).to eq(["c\0d"])
      expect(scanner.scan).to eq(["e\0f"])
      expect(scanner.scan).to be_nil
    end

    it "returns UTF-8 matches if the pattern is UTF-8" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It")
      matches = scanner.scan

      expect(matches.first.encoding).to eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 matches if the pattern is not UTF-8" do
      r = RE2::Regexp.new('(\w+)', utf8: false)
      scanner = r.scan("It")
      matches = scanner.scan

      expect(matches.first.encoding).to eq(Encoding::ISO_8859_1)
    end

    it "returns multiple capturing groups at a time", :aggregate_failures do
      r = RE2::Regexp.new('(\w+) (\w+)')
      scanner = r.scan("It is a truth universally acknowledged")

      expect(scanner.scan).to eq(["It", "is"])
      expect(scanner.scan).to eq(["a", "truth"])
      expect(scanner.scan).to eq(["universally", "acknowledged"])
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

    it "returns nil if the regexp is invalid" do
      r = RE2::Regexp.new('???', log_errors: false)
      scanner = r.scan("Foo bar")

      expect(scanner.scan).to be_nil
    end

    it "returns an empty array if the input is empty", :aggregate_failures do
      r = RE2::Regexp.new("")
      scanner = r.scan("")

      expect(scanner.scan).to eq([])
      expect(scanner.scan).to be_nil
    end

    it "returns an array of nil with an empty input and capture", :aggregate_failures do
      r = RE2::Regexp.new("()")
      scanner = r.scan("")

      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to be_nil
    end

    it "returns an empty array for every match if the pattern is empty", :aggregate_failures do
      r = RE2::Regexp.new("")
      scanner = r.scan("Foo")

      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to eq([])
      expect(scanner.scan).to be_nil
    end

    it "returns an array of nil if the pattern is an empty capturing group", :aggregate_failures do
      r = RE2::Regexp.new("()")
      scanner = r.scan("Foo")

      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to be_nil
    end

    it "returns array of nils with multiple empty capturing groups", :aggregate_failures do
      r = RE2::Regexp.new("()()()")
      scanner = r.scan("Foo")

      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to eq([nil, nil, nil])
      expect(scanner.scan).to be_nil
    end

    it "supports empty groups with multibyte characters", :aggregate_failures do
      r = RE2::Regexp.new("()€")
      scanner = r.scan("€")

      expect(scanner.scan).to eq([nil])
      expect(scanner.scan).to be_nil
    end

    it "raises a Type Error if given input that can't be coerced to a String" do
      r = RE2::Regexp.new('(\w+)')

      expect { r.scan(0) }.to raise_error(TypeError)
    end

    it "accepts input that can be coerced to a String", :aggregate_failures do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan(StringLike.new("Hello world"))

      expect(scanner.scan).to eq(["Hello"])
      expect(scanner.scan).to eq(["world"])
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

      expect { |b| scanner.each(&b) }.to yield_successive_args(["1"], ["2"], ["3"])
    end

    it "returns an enumerator when not given a block" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")

      expect(scanner.each).to be_a(Enumerator)
    end
  end

  describe "#rewind" do
    it "resets any consumption", :aggregate_failures do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("There are 1 some 2 numbers 3")

      expect(scanner.to_enum.first).to eq(["1"])
      expect(scanner.to_enum.first).to eq(["2"])

      scanner.rewind

      expect(scanner.to_enum.first).to eq(["1"])
    end

    it "supports inputs with null bytes", :aggregate_failures do
      r = RE2::Regexp.new("(\\w\0\\w)")
      scanner = r.scan("a\0b c\0d")

      expect(scanner.to_enum.first).to eq(["a\0b"])
      expect(scanner.to_enum.first).to eq(["c\0d"])

      scanner.rewind

      expect(scanner.to_enum.first).to eq(["a\0b"])
    end

    it "resets the eof? check", :aggregate_failures do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1")
      scanner.scan

      expect(scanner).to be_eof

      scanner.rewind

      expect(scanner).not_to be_eof
    end
  end

  describe "#eof?" do
    it "returns false if the input has not been consumed" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1 2 3")

      expect(scanner).not_to be_eof
    end

    it "returns true if the input has been consumed" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("1")
      scanner.scan

      expect(scanner).to be_eof
    end

    it "returns false if no match is made" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("a")
      scanner.scan

      expect(scanner).not_to be_eof
    end

    it "returns false with an empty input that has not been scanned" do
      r = RE2::Regexp.new("")
      scanner = r.scan("")

      expect(scanner).not_to be_eof
    end

    it "returns false with an empty input that has not been matched" do
      r = RE2::Regexp.new('(\d)')
      scanner = r.scan("")
      scanner.scan

      expect(scanner).not_to be_eof
    end

    it "returns true with an empty input that has been matched" do
      r = RE2::Regexp.new("")
      scanner = r.scan("")
      scanner.scan

      expect(scanner).to be_eof
    end
  end
end
