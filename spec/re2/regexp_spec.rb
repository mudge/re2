# frozen_string_literal: true

RSpec.describe RE2::Regexp do
  describe "#initialize" do
    it "returns an instance given only a pattern" do
      re = RE2::Regexp.new('woo')

      expect(re).to be_a(RE2::Regexp)
    end

    it "returns an instance given a pattern and options" do
      re = RE2::Regexp.new('woo', case_sensitive: false)

      expect(re).to be_a(RE2::Regexp)
    end

    it "accepts patterns containing null bytes" do
      re = RE2::Regexp.new("a\0b")

      expect(re.pattern).to eq("a\0b")
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Regexp.new(nil) }.to raise_error(TypeError)
    end

    it "allows invalid patterns to be created" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re).to be_a(RE2::Regexp)
    end

    it "supports passing something that can be coerced to a String as input" do
      re = RE2::Regexp.new(StringLike.new('w(o)(o)'))

      expect(re).to be_a(RE2::Regexp)
    end
  end

  describe ".compile" do
    it "returns an instance given only a pattern" do
      re = RE2::Regexp.compile('woo')

      expect(re).to be_a(RE2::Regexp)
    end

    it "returns an instance given a pattern and options" do
      re = RE2::Regexp.compile('woo', case_sensitive: false)
      expect(re).to be_a(RE2::Regexp)
    end

    it "accepts patterns containing null bytes" do
      re = RE2::Regexp.compile("a\0b")

      expect(re.pattern).to eq("a\0b")
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Regexp.compile(nil) }.to raise_error(TypeError)
    end

    it "allows invalid patterns to be created" do
      re = RE2::Regexp.compile('???', log_errors: false)

      expect(re).to be_a(RE2::Regexp)
    end

    it "supports passing something that can be coerced to a String as input" do
      re = RE2::Regexp.compile(StringLike.new('w(o)(o)'))

      expect(re).to be_a(RE2::Regexp)
    end
  end

  describe "#options" do
    it "returns a hash of options" do
      options = RE2::Regexp.new('woo').options
      expect(options).to be_a(Hash)
    end

    it "is populated with default options when nothing has been set" do
      expect(RE2::Regexp.new('woo').options).to include(
        utf8: true,
        posix_syntax: false,
        longest_match: false,
        log_errors: true,
        literal: false,
        never_nl: false,
        case_sensitive: true,
        perl_classes: false,
        word_boundary: false,
        one_line: false
      )
    end

    it "is populated with overridden options when specified" do
      options = RE2::Regexp.new('woo', case_sensitive: false).options

      expect(options).to include(case_sensitive: false)
    end
  end

  describe "#error" do
    it "returns nil if there is no error" do
      error = RE2::Regexp.new('woo').error

      expect(error).to be_nil
    end

    # Use log_errors: false to suppress RE2's logging to STDERR.
    it "contains the error string if there is an error" do
      error = RE2::Regexp.new('wo(o', log_errors: false).error

      expect(error).to eq("missing ): wo(o")
    end
  end

  describe "#error_arg" do
    it "returns nil if there is no error" do
      error_arg = RE2::Regexp.new('woo').error_arg

      expect(error_arg).to be_nil
    end

    it "returns the offending portion of the pattern if there is an error" do
      error_arg = RE2::Regexp.new('wo(o', log_errors: false).error_arg

      expect(error_arg).to eq("wo(o")
    end
  end

  describe "#program_size" do
    it "returns a numeric value" do
      program_size = RE2::Regexp.new('w(o)(o)').program_size

      expect(program_size).to be_an(Integer)
    end

    it "returns -1 for an invalid pattern" do
      program_size = RE2::Regexp.new('???', log_errors: false).program_size

      expect(program_size).to eq(-1)
    end
  end

  describe "#to_str" do
    it "returns the original pattern" do
      string = RE2::Regexp.new('w(o)(o)').to_str

      expect(string).to eq("w(o)(o)")
    end

    it "returns the pattern even if invalid" do
      string = RE2::Regexp.new('???', log_errors: false).to_str

      expect(string).to eq("???")
    end
  end

  describe "#pattern" do
    it "returns the original pattern" do
      pattern = RE2::Regexp.new('w(o)(o)').pattern

      expect(pattern).to eq("w(o)(o)")
    end

    it "returns the pattern even if invalid" do
      pattern = RE2::Regexp.new('???', log_errors: false).pattern

      expect(pattern).to eq("???")
    end
  end

  describe "#inspect" do
    it "shows the class name and original pattern" do
      string = RE2::Regexp.new('w(o)(o)').inspect

      expect(string).to eq("#<RE2::Regexp /w(o)(o)/>")
    end

    it "respects the pattern's original encoding" do
      string = RE2::Regexp.new('w(o)(o)', utf8: false).inspect

      expect(string.encoding).to eq(Encoding::ISO_8859_1)
    end
  end

  describe "#utf8?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_utf8
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', utf8: false)

      expect(re).to_not be_utf8
    end
  end

  describe "#posix_syntax?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_posix_syntax
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', posix_syntax: true)

      expect(re).to be_posix_syntax
    end
  end

  describe "#literal?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_literal
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', literal: true)

      expect(re).to be_literal
    end
  end

  describe "#never_nl?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_never_nl
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', never_nl: true)

      expect(re).to be_never_nl
    end
  end

  describe "#case_sensitive?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_case_sensitive
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', case_sensitive: false)
      expect(re).to_not be_case_sensitive
    end
  end

  describe "#case_insensitive?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_case_insensitive
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', case_sensitive: false)

      expect(re).to be_case_insensitive
    end
  end

  describe "#casefold?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to_not be_casefold
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', case_sensitive: false)

      expect(re).to be_casefold
    end
  end

  describe "#longest_match?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_casefold
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', longest_match: true)

      expect(re).to be_longest_match
    end
  end

  describe "#log_errors?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_log_errors
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', log_errors: false)

      expect(re).to_not be_log_errors
    end
  end

  describe "#perl_classes?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_perl_classes
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', perl_classes: true)

      expect(re).to be_perl_classes
    end
  end

  describe "#word_boundary?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_word_boundary
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', word_boundary: true)

      expect(re).to be_word_boundary
    end
  end

  describe "#one_line?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_one_line
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', one_line: true)

      expect(re).to be_one_line
    end
  end

  describe "#max_mem" do
    it "returns the default max memory" do
      expect(RE2::Regexp.new('woo').max_mem).to eq(8388608)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', max_mem: 1024)

      expect(re.max_mem).to eq(1024)
    end
  end

  describe "#match" do
    it "returns match data given only text if the pattern has capturing groups" do
      re = RE2::Regexp.new('My name is (\w+) (\w+)')

      expect(re.match("My name is Alice Bloggs")).to be_a(RE2::MatchData)
    end

    it "returns only true or false given only text if the pattern has no capturing groups" do
      re = RE2::Regexp.new('My name is \w+ \w+')

      expect(re.match("My name is Alice Bloggs")).to eq(true)
    end

    it "supports matching against text containing null bytes" do
      re = RE2::Regexp.new("a\0b")

      expect(re.match("a\0b")).to eq(true)
    end

    it "returns nil if the text does not match the pattern" do
      re = RE2::Regexp.new('My name is (\w+) (\w+)')

      expect(re.match("My age is 99")).to be_nil
    end

    it "accepts text that can be coerced to a string" do
      re = RE2::Regexp.new('My name is (\w+) (\w+)')

      expect(re.match(StringLike.new("My name is Alice Bloggs"))).to be_a(RE2::MatchData)
    end

    it "raises an exception when given text that cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\w+) (\w+)')

      expect { re.match(nil) }.to raise_error(TypeError)
    end

    it "returns nil with an invalid pattern" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re.match("My name is Alice Bloggs")).to be_nil
    end

    it "returns nil with an invalid pattern and options" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re.match('foo bar', startpos: 1)).to be_nil
    end

    it "accepts an offset at which to start matching", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+)')
      md = re.match("one two three", startpos: 4)

      expect(md[1]).to eq("two")
      expect(md[2]).to eq("three")
    end

    it "returns nil if using a starting offset past the end of the text" do
      skip "Underlying RE2::Match does not have endpos argument" unless RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)', log_errors: false)

      expect(re.match("one two three", startpos: 20, endpos: 21)).to be_nil
    end

    it "raises an exception when given a negative starting offset" do
      re = RE2::Regexp.new('(\w+) (\w+)')

      expect { re.match("one two three", startpos: -1) }.to raise_error(ArgumentError, "startpos should be >= 0")
    end

    it "raises an exception when given a starting offset past the default ending offset" do
      re = RE2::Regexp.new('(\w+) (\w+)')

      expect { re.match("one two three", startpos: 30) }.to raise_error(ArgumentError, "startpos should be <= endpos")
    end

    it "accepts an offset at which to end matching", :aggregate_failures do
      skip "Underlying RE2::Match does not have endpos argument" unless RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)')
      md = re.match("one two three", endpos: 6)

      expect(md[1]).to eq("one")
      expect(md[2]).to eq("tw")
    end

    it "returns nil if using a ending offset at the start of the text" do
      skip "Underlying RE2::Match does not have endpos argument" unless RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)')

      expect(re.match("one two three", endpos: 0)).to be_nil
    end

    it "raises an exception when given a negative ending offset" do
      skip "Underlying RE2::Match does not have endpos argument" unless RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)')

      expect { re.match("one two three", endpos: -1) }.to raise_error(ArgumentError, "endpos should be >= 0")
    end

    it "raises an exception when given an ending offset before the starting offset" do
      skip "Underlying RE2::Match does not have endpos argument" unless RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)')

      expect { re.match("one two three", startpos: 3, endpos: 0) }.to raise_error(ArgumentError, "startpos should be <= endpos")
    end

    it "raises an error if given an ending offset and RE2 does not support it" do
      skip "Underlying RE2::Match has endpos argument" if RE2::Regexp.match_has_endpos_argument?

      re = RE2::Regexp.new('(\w+) (\w+)')

      expect { re.match("one two three", endpos: 3) }.to raise_error(RE2::Regexp::UnsupportedError)
    end

    it "does not anchor matches by default when extracting submatches" do
      re = RE2::Regexp.new('(two)')

      expect(re.match("one two three")).to be_a(RE2::MatchData)
    end

    it "does not anchor matches by default without extracting submatches" do
      re = RE2::Regexp.new('(two)')

      expect(re.match("one two three", submatches: 0)).to eq(true)
    end

    it "can explicitly match without anchoring when extracting submatches" do
      re = RE2::Regexp.new('(two)')

      expect(re.match("one two three", anchor: :unanchored)).to be_a(RE2::MatchData)
    end

    it "can explicitly match with neither anchoring nor extracting submatches" do
      re = RE2::Regexp.new('(two)')

      expect(re.match("one two three", anchor: :unanchored, submatches: 0)).to eq(true)
    end

    it "can anchor matches at the start when extracting submatches", :aggregate_failures do
      re = RE2::Regexp.new('(two)')

      expect(re.match("two three", anchor: :anchor_start)).to be_a(RE2::MatchData)
      expect(re.match("one two three", anchor: :anchor_start)).to be_nil
    end

    it "can anchor matches at the start without extracting submatches", :aggregate_failures do
      re = RE2::Regexp.new('(two)')

      expect(re.match("two three", anchor: :anchor_start, submatches: 0)).to eq(true)
      expect(re.match("one two three", anchor: :anchor_start, submatches: 0)).to eq(false)
    end

    it "can anchor matches at both ends when extracting submatches", :aggregate_failures do
      re = RE2::Regexp.new('(two)')

      expect(re.match("two three", anchor: :anchor_both)).to be_nil
      expect(re.match("two", anchor: :anchor_both)).to be_a(RE2::MatchData)
    end

    it "does not anchor matches when given a nil anchor" do
      re = RE2::Regexp.new('(two)')

      expect(re.match("one two three", anchor: nil)).to be_a(RE2::MatchData)
    end

    it "raises an exception when given an invalid anchor" do
      re = RE2::Regexp.new('(two)')

      expect { re.match("one two three", anchor: :invalid) }.to raise_error(ArgumentError, "anchor should be one of: :unanchored, :anchor_start, :anchor_both")
    end

    it "raises an exception when given a non-symbol anchor" do
      re = RE2::Regexp.new('(two)')

      expect { re.match("one two three", anchor: 0) }.to raise_error(TypeError)
    end

    it "extracts all submatches by default", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')
      md = re.match("one two three")

      expect(md[1]).to eq("one")
      expect(md[2]).to eq("two")
      expect(md[3]).to eq("three")
    end

    it "supports extracting submatches containing null bytes" do
      re = RE2::Regexp.new("(a\0b)")
      md = re.match("a\0bc")

      expect(md[1]).to eq("a\0b")
    end

    it "extracts a specific number of submatches", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')
      md = re.match("one two three", submatches: 2)

      expect(md[1]).to eq("one")
      expect(md[2]).to eq("two")
      expect(md[3]).to be_nil
    end

    it "pads submatches with nil when requesting more than the number of capturing groups" do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')
      md = re.match("one two three", submatches: 5)

      expect(md.to_a).to eq(["one two three", "one", "two", "three", nil, nil])
    end

    it "raises an exception when given a negative number of submatches" do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')

      expect { re.match("one two three", submatches: -1) }.to raise_error(ArgumentError, "number of matches should be >= 0")
    end

    it "raises an exception when given a non-numeric number of submatches" do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')

      expect { re.match("one two three", submatches: :invalid) }.to raise_error(TypeError)
    end

    it "defaults to extracting all submatches when given nil", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')
      md = re.match("one two three", submatches: nil)

      expect(md[1]).to eq("one")
      expect(md[2]).to eq("two")
      expect(md[3]).to eq("three")
    end

    it "accepts passing the number of submatches instead of options for backward compatibility", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')
      md = re.match("one two three", 2)

      expect(md[1]).to eq("one")
      expect(md[2]).to eq("two")
      expect(md[3]).to be_nil
    end

    it "raises an exception when given invalid options" do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')

      expect { re.match("one two three", :invalid) }.to raise_error(TypeError)
    end

    it "accepts anything that can be coerced to a hash as options", :aggregate_failures do
      re = RE2::Regexp.new('(\w+) (\w+) (\w+)')

      expect(re.match("one two three", nil)).to be_a(RE2::MatchData)
    end
  end

  describe "#match?" do
    it "returns only true or false even if there are capturing groups", :aggregate_failures do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect(re.match?("My name is Alice Bloggs")).to eq(true)
      expect(re.match?("My age is 99")).to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re.match?("My name is Alice Bloggs")).to eq(false)
    end

    it "raises an exception if text cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect { re.match?(0) }.to raise_error(TypeError)
    end
  end

  describe "#partial_match?" do
    it "returns only true or false even if there are capturing groups", :aggregate_failures do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect(re.partial_match?("My name is Alice Bloggs")).to eq(true)
      expect(re.partial_match?("My age is 99")).to eq(false)
    end

    it "supports matching against text containing null bytes", :aggregate_failures do
      re = RE2::Regexp.new("a\0b")

      expect(re.partial_match?("a\0b")).to eq(true)
      expect(re.partial_match?("ab")).to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re.partial_match?("My name is Alice Bloggs")).to eq(false)
    end

    it "raises an exception if text cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect { re.partial_match?(0) }.to raise_error(TypeError)
    end
  end

  describe "#=~" do
    it "returns only true or false even if there are capturing groups", :aggregate_failures do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect(re =~ "My name is Alice Bloggs").to eq(true)
      expect(re =~ "My age is 99").to eq(false)
    end

    it "supports matching against text containing null bytes", :aggregate_failures do
      re = RE2::Regexp.new("a\0b")

      expect(re =~ "a\0b").to eq(true)
      expect(re =~ "ab").to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re =~ "My name is Alice Bloggs").to eq(false)
    end

    it "raises an exception if text cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect { re =~ 0 }.to raise_error(TypeError)
    end
  end

  describe "#===" do
    it "returns only true or false even if there are capturing groups", :aggregate_failures do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect(re === "My name is Alice Bloggs").to eq(true)
      expect(re === "My age is 99").to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re === "My name is Alice Bloggs").to eq(false)
    end

    it "raises an exception if text cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect { re === 0 }.to raise_error(TypeError)
    end
  end

  describe "#full_match?" do
    it "returns only true or false even if there are capturing groups", :aggregate_failures do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect(re.full_match?("My name is Alice Bloggs")).to eq(true)
      expect(re.full_match?("My name is Alice Bloggs and I am 99")).to eq(false)
    end

    it "supports matching against text containing null bytes", :aggregate_failures do
      re = RE2::Regexp.new("a\0b")

      expect(re.full_match?("a\0b")).to eq(true)
      expect(re.full_match?("a\0bc")).to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', log_errors: false)

      expect(re.full_match?("My name is Alice Bloggs")).to eq(false)
    end

    it "raises an exception if text cannot be coerced to a string" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')

      expect { re.full_match?(0) }.to raise_error(TypeError)
    end
  end

  describe "#ok?" do
    it "returns true for valid patterns", :aggregate_failures do
      expect(RE2::Regexp.new('woo')).to be_ok
      expect(RE2::Regexp.new('wo(o)')).to be_ok
      expect(RE2::Regexp.new('((\d)\w+){3,}')).to be_ok
    end

    it "returns false for invalid patterns", :aggregate_failures do
      expect(RE2::Regexp.new('wo(o', log_errors: false)).to_not be_ok
      expect(RE2::Regexp.new('wo[o', log_errors: false)).to_not be_ok
      expect(RE2::Regexp.new('*', log_errors: false)).to_not be_ok
    end
  end

  describe ".escape" do
    it "transforms a string into a regexp" do
      expect(RE2::Regexp.escape("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end
  end

  describe ".quote" do
    it "transforms a string into a regexp" do
      expect(RE2::Regexp.quote("1.5-2.0?")).to eq('1\.5\-2\.0\?')
    end
  end

  describe "#number_of_capturing_groups" do
    it "returns the number of groups in a pattern", :aggregate_failures do
      expect(RE2::Regexp.new('(a)(b)(c)').number_of_capturing_groups).to eq(3)
      expect(RE2::Regexp.new('abc').number_of_capturing_groups).to eq(0)
      expect(RE2::Regexp.new('a((b)c)').number_of_capturing_groups).to eq(2)
    end

    it "returns -1 for an invalid pattern" do
      expect(RE2::Regexp.new('???', log_errors: false).number_of_capturing_groups).to eq(-1)
    end
  end

  describe "#named_capturing_groups" do
    it "returns a hash of names to indices" do
      expect(RE2::Regexp.new('(?P<bob>a)').named_capturing_groups).to be_a(Hash)
    end

    it "maps names to indices with only one group" do
      groups = RE2::Regexp.new('(?P<bob>a)').named_capturing_groups

      expect(groups).to eq("bob" => 1)
    end

    it "maps names to indices with several groups" do
      groups = RE2::Regexp.new('(?P<bob>a)(o)(?P<rob>e)').named_capturing_groups

      expect(groups).to eq("bob" => 1, "rob" => 3)
    end

    it "returns an empty hash for an invalid regexp" do
      expect(RE2::Regexp.new('???', log_errors: false).named_capturing_groups).to be_empty
    end
  end

  describe "#scan" do
    it "returns a scanner" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It is a truth universally acknowledged")

      expect(scanner).to be_a(RE2::Scanner)
    end

    it "raises a type error if given invalid input" do
      r = RE2::Regexp.new('(\w+)')

      expect { r.scan(nil) }.to raise_error(TypeError)
    end
  end

  describe "#partial_match" do
    it "matches the pattern anywhere within the given text" do
      r = RE2::Regexp.new('f(o+)')

      expect(r.partial_match("foo bar")).to be_a(RE2::MatchData)
    end

    it "returns true or false if there are no capturing groups" do
      r = RE2::Regexp.new('fo+')

      expect(r.partial_match("foo bar")).to eq(true)
    end

    it "can set the number of submatches to extract", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')
      m = r.partial_match("fooaa bar", submatches: 1)

      expect(m[1]).to eq("oo")
      expect(m[2]).to be_nil

      m = r.partial_match("fooaa bar", submatches: 2)

      expect(m[1]).to eq("oo")
      expect(m[2]).to eq("aa")
    end

    it "raises an error if given non-hash options" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect { r.partial_match("fooaa bar", "not a hash") }.to raise_error(TypeError)
    end

    it "accepts options that can be coerced to a hash", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')

      m = r.partial_match("fooaa bar", nil)
      expect(m[1]).to eq('oo')

      m = r.partial_match("fooaa bar", [])
      expect(m[1]).to eq('oo')
    end

    it "accepts anything that can be coerced to a string" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect(r.partial_match(StringLike.new("fooaa bar"))).to be_a(RE2::MatchData)
    end

    it "does not allow the anchor to be overridden" do
      r = RE2::Regexp.new('(\d+)')

      expect(r.partial_match('ruby:1234', anchor: :anchor_both)).to be_a(RE2::MatchData)
    end
  end

  describe "#full_match" do
    it "only matches the pattern if all of the given text matches", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)')

      expect(r.full_match("foo")).to be_a(RE2::MatchData)
      expect(r.full_match("foo bar")).to be_nil
    end

    it "returns true or false if there are no capturing groups" do
      r = RE2::Regexp.new('fo+')

      expect(r.full_match("foo")).to eq(true)
    end

    it "can set the number of submatches to extract", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')
      m = r.full_match("fooaa", submatches: 1)

      expect(m[1]).to eq("oo")
      expect(m[2]).to be_nil

      m = r.full_match("fooaa", submatches: 2)

      expect(m[1]).to eq("oo")
      expect(m[2]).to eq("aa")
    end

    it "raises an error if given non-hash options" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect { r.full_match("fooaa", "not a hash") }.to raise_error(TypeError)
    end

    it "accepts options that can be coerced to a hash", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')

      m = r.full_match("fooaa", nil)
      expect(m[1]).to eq("oo")

      m = r.full_match("fooaa", [])
      expect(m[1]).to eq("oo")
    end

    it "accepts anything that can be coerced to a string" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect(r.full_match(StringLike.new("fooaa"), submatches: 0)).to eq(true)
    end

    it "does not allow the anchor to be overridden" do
      r = RE2::Regexp.new('(\d+)')

      expect(r.full_match('ruby:1234', anchor: :unanchored)).to be_nil
    end
  end
end
