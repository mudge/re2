require "spec_helper"

describe RE2::Consumer do
  describe "#regexp" do
    it "returns the original pattern for the consumer" do
      re = RE2::Regexp.new('(\w+)')
      consumer = re.consume("It is a truth")

      consumer.regexp.must_be_same_as(re)
    end
  end

  describe "#string" do
    it "returns the original text for the consumer" do
      re = RE2::Regexp.new('(\w+)')
      text = "It is a truth"
      consumer = re.consume(text)

      consumer.string.must_be_same_as(text)
    end
  end

  describe "#consume" do
    it "returns the next array of matches" do
      r = RE2::Regexp.new('(\w+)')
      consumer = r.consume("It is a truth universally acknowledged")
      consumer.consume.must_equal(["It"])
      consumer.consume.must_equal(["is"])
      consumer.consume.must_equal(["a"])
      consumer.consume.must_equal(["truth"])
      consumer.consume.must_equal(["universally"])
      consumer.consume.must_equal(["acknowledged"])
      consumer.consume.must_be_nil
    end

    it "returns an empty array if there are no capturing groups" do
      r = RE2::Regexp.new('\w+')
      consumer = r.consume("Foo bar")
      consumer.consume.must_equal([])
    end

    it "returns nil if there is no match" do
      r = RE2::Regexp.new('\d+')
      consumer = r.consume("Foo bar")
      consumer.consume.must_be_nil
    end
  end

  it "is enumerable" do
    r = RE2::Regexp.new('(\d)')
    consumer = r.consume("There are 1 some 2 numbers 3")
    consumer.must_be_kind_of(Enumerable)
  end

  describe "#each" do
    it "yields each match" do
      r = RE2::Regexp.new('(\d)')
      consumer = r.consume("There are 1 some 2 numbers 3")
      matches = []
      consumer.each do |match|
        matches << match
      end

      matches.must_equal([["1"], ["2"], ["3"]])
    end

    it "returns an enumerator when not given a block" do
      r = RE2::Regexp.new('(\d)')
      consumer = r.consume("There are 1 some 2 numbers 3")

      # Prior to Ruby 1.9, Enumerator was within Enumerable.
      if defined?(Enumerator)
        consumer.each.must_be_kind_of(Enumerator)
      elsif defined?(Enumerable::Enumerator)
        consumer.each.must_be_kind_of(Enumerable::Enumerator)
      end
    end
  end

  describe "#rewind" do
    it "resets any consumption" do
      r = RE2::Regexp.new('(\d)')
      consumer = r.consume("There are 1 some 2 numbers 3")
      consumer.to_enum.first.must_equal(["1"])
      consumer.to_enum.first.must_equal(["2"])
      consumer.rewind
      consumer.to_enum.first.must_equal(["1"])
    end
  end
end
