# frozen_string_literal: true

require 'objspace'

RSpec.describe RE2::MatchData do
  it "reports a larger consuming memory size when it has more matches" do
    matches1 = RE2::Regexp.new('w(o)').match('woo')
    matches2 = RE2::Regexp.new('w(o)(o)').match('woo')

    expect(ObjectSpace.memsize_of(matches1)).to be < ObjectSpace.memsize_of(matches2)
  end

  describe "#to_a" do
    it "is populated with the match and capturing groups" do
      a = RE2::Regexp.new('w(o)(o)').match('woo').to_a

      expect(a).to eq(["woo", "o", "o"])
    end

    it "populates optional capturing groups with nil if they are missing" do
      a = RE2::Regexp.new('(\d?)(a)(b)').match('ab').to_a

      expect(a).to eq(["ab", nil, "a", "b"])
    end

    it "returns UTF-8 strings if the pattern is UTF-8" do
      a = RE2::Regexp.new('w(o)(o)').match('woo').to_a

      expect(a.map(&:encoding)).to all eq(Encoding::UTF_8)
    end

    it "returns ISO-8859-1 strings if the pattern is not UTF-8" do
      a = RE2::Regexp.new('w(o)(o)', utf8: false).match('woo').to_a

      expect(a.map(&:encoding)).to all eq(Encoding::ISO_8859_1)
    end
  end

  describe "#[]" do
    it "accesses capturing groups by numerical index", :aggregate_failures do
      md = RE2::Regexp.new('(\d)(\d{2})').match("123")

      expect(md[1]).to eq("1")
      expect(md[2]).to eq("23")
    end

    it "returns a UTF-8 string by numerical index if the pattern is UTF-8" do
      md = RE2::Regexp.new('(\d)(\d{2})').match("123")

      expect(md[1].encoding).to eq(Encoding::UTF_8)
    end

    it "returns a ISO-8859-1 string by numerical index if the pattern is not UTF-8" do
      md = RE2::Regexp.new('(\d)(\d{2})', utf8: false).match("123")

      expect(md[1].encoding).to eq(Encoding::ISO_8859_1)
    end

    it "has the whole match as the 0th item" do
      md = RE2::Regexp.new('(\d)(\d{2})').match("123")

      expect(md[0]).to eq("123")
    end

    it "supports access by numerical ranges", :aggregate_failures do
      md = RE2::Regexp.new('(\d+) (\d+) (\d+)').match("123 456 789")

      expect(md[1..3]).to eq(["123", "456", "789"])
      expect(md[1...3]).to eq(["123", "456"])
    end

    it "supports slicing", :aggregate_failures do
      md = RE2::Regexp.new('(\d+) (\d+) (\d+)').match("123 456 789")

      expect(md[1, 3]).to eq(["123", "456", "789"])
      expect(md[1, 2]).to eq(["123", "456"])
    end

    it "returns nil if attempting to access non-existent capturing groups by index", :aggregate_failures do
      md = RE2::Regexp.new('(\d+)').match('bob 123')

      expect(md[2]).to be_nil
      expect(md[3]).to be_nil
    end

    it "allows access by string names when there are named groups" do
      md = RE2::Regexp.new('(?P<numbers>\d+)').match('bob 123')

      expect(md["numbers"]).to eq("123")
    end

    it "allows access by symbol names when there are named groups" do
      md = RE2::Regexp.new('(?P<numbers>\d+)').match('bob 123')

      expect(md[:numbers]).to eq("123")
    end

    it "allows access by names and indices with mixed groups", :aggregate_failures do
      md = RE2::Regexp.new('(?P<name>\w+)(\s*)(?P<numbers>\d+)').match("bob 123")

      expect(md["name"]).to eq("bob")
      expect(md[:name]).to eq("bob")
      expect(md[2]).to eq(" ")
      expect(md["numbers"]).to eq("123")
      expect(md[:numbers]).to eq("123")
    end

    it "returns nil if no such named group exists", :aggregate_failures do
      md = RE2::Regexp.new('(\d+)').match("bob 123")

      expect(md["missing"]).to be_nil
      expect(md[:missing]).to be_nil
    end

    it "raises an error if given an inappropriate index" do
      md = RE2::Regexp.new('(\d+)').match("bob 123")

      expect { md[nil] }.to raise_error(TypeError)
    end

    it "returns UTF-8 encoded strings by default", :aggregate_failures do
      md = RE2::Regexp.new('(?P<name>\S+)').match("bob")

      expect(md[0].encoding.name).to eq("UTF-8")
      expect(md["name"].encoding.name).to eq("UTF-8")
      expect(md[:name].encoding.name).to eq("UTF-8")
    end

    it "returns Latin 1 strings encoding when utf-8 is false", :aggregate_failures do
      md = RE2::Regexp.new('(?P<name>\S+)', utf8: false).match('bob')

      expect(md[0].encoding.name).to eq("ISO-8859-1")
      expect(md["name"].encoding.name).to eq("ISO-8859-1")
      expect(md[:name].encoding.name).to eq("ISO-8859-1")
    end
  end

  describe "#string" do
    it "returns the original string to match against" do
      re = RE2::Regexp.new('(\D+)').match("bob")

      expect(re.string).to eq("bob")
    end

    it "returns a copy, not the actual original" do
      string = +"bob"
      re = RE2::Regexp.new('(\D+)').match(string)

      expect(re.string).to_not equal(string)
    end

    it "returns a frozen string" do
      re = RE2::Regexp.new('(\D+)').match("bob")

      expect(re.string).to be_frozen
    end

    it "does not copy the string if it was already frozen" do
      string = "bob"
      re = RE2::Regexp.new('(\D+)').match(string)

      expect(re.string).to equal(string)
    end
  end

  describe "#size" do
    it "returns the number of capturing groups plus the matching string" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")

      expect(md.size).to eq(3)
    end
  end

  describe "#length" do
    it "returns the number of capturing groups plus the matching string" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")

      expect(md.length).to eq(3)
    end
  end

  describe "#regexp" do
    it "returns the original RE2::Regexp used" do
      re = RE2::Regexp.new('(\d+)')
      md = re.match("123")

      expect(md.regexp).to equal(re)
    end
  end

  describe "#inspect" do
    it "returns a text representation of the object and indices" do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")

      expect(md.inspect).to eq('#<RE2::MatchData "1234 56" 1:"1234" 2:"56">')
    end

    it "represents missing matches as nil" do
      md = RE2::Regexp.new('(\d+) (\d+)?').match("1234 ")

      expect(md.inspect).to eq('#<RE2::MatchData "1234 " 1:"1234" 2:nil>')
    end

    it "supports matches with null bytes" do
      md = RE2::Regexp.new("(\\w\0\\w) (\\w\0\\w)").match("a\0b c\0d")

      expect(md.inspect).to eq("#<RE2::MatchData \"a\0b c\0d\" 1:\"a\0b\" 2:\"c\0d\">")
    end
  end

  describe "#to_s" do
    it "returns the matching part of the original string" do
      md = RE2::Regexp.new('(\d{2,5})').match("one two 23456")

      expect(md.to_s).to eq("23456")
    end
  end

  describe "#to_ary" do
    it "allows the object to be expanded with an asterisk", :aggregate_failures do
      md = RE2::Regexp.new('(\d+) (\d+)').match("1234 56")
      m1, m2, m3 = *md

      expect(m1).to eq("1234 56")
      expect(m2).to eq("1234")
      expect(m3).to eq("56")
    end
  end

  describe "#begin" do
    it "returns the offset of the start of a match by index" do
      md = RE2::Regexp.new('(wo{2})').match('a woohoo')

      expect(md.string[md.begin(0)..-1]).to eq('woohoo')
    end

    it "returns the offset of the start of a match by string name" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[md.begin('foo')..-1]).to eq('foobar')
    end

    it "returns the offset of the start of a match by symbol name" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[md.begin(:foo)..-1]).to eq('foobar')
    end

    it "returns the offset of the start of a match by something that can be coerced to a String" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[md.begin(StringLike.new("foo"))..-1]).to eq('foobar')
    end

    it "returns the offset despite multibyte characters" do
      md = RE2::Regexp.new('(Ruby)').match('I ♥ Ruby')

      expect(md.string[md.begin(0)..-1]).to eq('Ruby')
    end

    it "returns nil for non-existent numerical matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.begin(10)).to be_nil
    end

    it "returns nil for negative numerical matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.begin(-4)).to be_nil
    end

    it "returns nil for non-existent named matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.begin('foo')).to be_nil
    end

    it "returns nil for non-existent symbol named matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.begin(:foo)).to be_nil
    end

    it "raises a type error if given an invalid name or number" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect { md.begin(nil) }.to raise_error(TypeError)
    end
  end

  describe "#end" do
    it "returns the offset of the character following the end of a match" do
      md = RE2::Regexp.new('(wo{2})').match('a woohoo')

      expect(md.string[0...md.end(0)]).to eq('a woo')
    end

    it "returns the offset of a match by string name" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[0...md.end('foo')]).to eq('a foo')
    end

    it "returns the offset of a match by symbol name" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[0...md.end(:foo)]).to eq('a foo')
    end

    it "returns the offset of a match by something that can be coerced to a String" do
      md = RE2::Regexp.new('(?P<foo>fo{2})').match('a foobar')

      expect(md.string[0...md.end(StringLike.new("foo"))]).to eq('a foo')
    end

    it "returns the offset despite multibyte characters" do
      md = RE2::Regexp.new('(Ruby)').match('I ♥ Ruby')

      expect(md.string[0...md.end(0)]).to eq('I ♥ Ruby')
    end

    it "returns nil for non-existent numerical matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.end(10)).to be_nil
    end

    it "returns nil for negative numerical matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.end(-4)).to be_nil
    end

    it "returns nil for non-existent named matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.end('foo')).to be_nil
    end

    it "returns nil for non-existent symbol named matches" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect(md.end(:foo)).to be_nil
    end

    it "raises a type error if given an invalid name or number" do
      md = RE2::Regexp.new('(\d)').match('123')

      expect { md.end(nil) }.to raise_error(TypeError)
    end
  end

  describe "#deconstruct" do
    it "returns all capturing groups" do
      md = RE2::Regexp.new('w(o)(o)').match('woo')

      expect(md.deconstruct).to eq(['o', 'o'])
    end

    it "includes optional capturing groups as nil" do
      md = RE2::Regexp.new('w(.)(.)(.)?').match('woo')

      expect(md.deconstruct).to eq(['o', 'o', nil])
    end
  end

  describe "#deconstruct_keys" do
    it "returns all named captures if given nil" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect(md.deconstruct_keys(nil)).to eq(numbers: '123', letters: 'abc')
    end

    it "returns only named captures if given names" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect(md.deconstruct_keys([:numbers])).to eq(numbers: '123')
    end

    it "returns named captures up until an invalid name is given" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect(md.deconstruct_keys([:numbers, :punctuation])).to eq(numbers: '123')
    end

    it "returns an empty hash if given more capture names than exist" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect(md.deconstruct_keys([:numbers, :letters, :punctuation])).to eq({})
    end

    it "returns an empty hash if there are no named capturing groups" do
      md = RE2::Regexp.new('(\d+) ([a-zA-Z]+)').match('123 abc')

      expect(md.deconstruct_keys(nil)).to eq({})
    end

    it "raises an error if given a non-array of keys" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect { md.deconstruct_keys(0) }.to raise_error(TypeError)
    end

    it "raises an error if given keys as non-symbols" do
      md = RE2::Regexp.new('(?P<numbers>\d+) (?P<letters>[a-zA-Z]+)').match('123 abc')

      expect { md.deconstruct_keys([0]) }.to raise_error(TypeError)
    end
  end
end
