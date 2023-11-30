RSpec.describe RE2::Regexp do
  describe "#initialize" do
    it "returns an instance given only a pattern" do
      re = RE2::Regexp.new('woo')
      expect(re).to be_a(RE2::Regexp)
    end

    it "returns an instance given a pattern and options" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      expect(re).to be_a(RE2::Regexp)
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Regexp.new(nil) }.to raise_error(TypeError)
    end

    it "allows invalid patterns to be created" do
      re = RE2::Regexp.new('???', :log_errors => false)
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
      re = RE2::Regexp.compile('woo', :case_sensitive => false)
      expect(re).to be_a(RE2::Regexp)
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Regexp.compile(nil) }.to raise_error(TypeError)
    end

    it "allows invalid patterns to be created" do
      re = RE2::Regexp.compile('???', :log_errors => false)
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
      options = RE2::Regexp.new('woo').options
      expect(options).to include(:utf8 => true,
                                 :posix_syntax => false,
                                 :longest_match => false,
                                 :log_errors => true,
                                 :literal => false,
                                 :never_nl => false,
                                 :case_sensitive => true,
                                 :perl_classes => false,
                                 :word_boundary => false,
                                 :one_line => false)
    end

    it "is populated with overridden options when specified" do
      options = RE2::Regexp.new('woo', :case_sensitive => false).options
      expect(options).to include(:case_sensitive => false)
    end
  end

  describe "#error" do
    it "returns nil if there is no error" do
      error = RE2::Regexp.new('woo').error
      expect(error).to be_nil
    end

    # Use log_errors => false to suppress RE2's logging to STDERR.
    it "contains the error string if there is an error" do
      error = RE2::Regexp.new('wo(o', :log_errors => false).error
      expect(error).to eq("missing ): wo(o")
    end
  end

  describe "#error_arg" do
    it "returns nil if there is no error" do
      error_arg = RE2::Regexp.new('woo').error_arg
      expect(error_arg).to be_nil
    end

    it "returns the offending portion of the regexp if there is an error" do
      error_arg = RE2::Regexp.new('wo(o', :log_errors => false).error_arg
      expect(error_arg).to eq("wo(o")
    end
  end

  describe "#program_size" do
    it "returns a numeric value" do
      program_size = RE2::Regexp.new('w(o)(o)').program_size

      expect(program_size).to be_an(Integer)
    end

    it "returns -1 for an invalid pattern" do
      program_size = RE2::Regexp.new('???', :log_errors => false).program_size
      expect(program_size).to eq(-1)
    end
  end

  describe "#to_str" do
    it "returns the original pattern" do
      string = RE2::Regexp.new('w(o)(o)').to_str
      expect(string).to eq("w(o)(o)")
    end
  end

  describe "#pattern" do
    it "returns the original pattern" do
      pattern = RE2::Regexp.new('w(o)(o)').pattern
      expect(pattern).to eq("w(o)(o)")
    end

    it "returns the pattern even if invalid" do
      pattern = RE2::Regexp.new('???', :log_errors => false).pattern
      expect(pattern).to eq("???")
    end
  end

  describe "#inspect" do
    it "shows the class name and original pattern" do
      string = RE2::Regexp.new('w(o)(o)').inspect
      expect(string).to eq("#<RE2::Regexp /w(o)(o)/>")
    end
  end

  describe "#utf8?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_utf8
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :utf8 => false)
      expect(re).to_not be_utf8
    end
  end

  describe "#posix_syntax?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_posix_syntax
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :posix_syntax => true)
      expect(re).to be_posix_syntax
    end
  end

  describe "#literal?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_literal
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :literal => true)
      expect(re).to be_literal
    end
  end

  describe "#never_nl?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_never_nl
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :never_nl => true)
      expect(re).to be_never_nl
    end
  end

  describe "#case_sensitive?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_case_sensitive
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      expect(re).to_not be_case_sensitive
    end
  end

  describe "#case_insensitive?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_case_insensitive
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      expect(re).to be_case_insensitive
    end
  end

  describe "#casefold?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to_not be_casefold
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      expect(re).to be_casefold
    end
  end

  describe "#longest_match?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_casefold
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :longest_match => true)
      expect(re).to be_longest_match
    end
  end

  describe "#log_errors?" do
    it "returns true by default" do
      expect(RE2::Regexp.new('woo')).to be_log_errors
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :log_errors => false)
      expect(re).to_not be_log_errors
    end
  end

  describe "#perl_classes?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_perl_classes
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :perl_classes => true)
      expect(re).to be_perl_classes
    end
  end

  describe "#word_boundary?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_word_boundary
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :word_boundary => true)
      expect(re).to be_word_boundary
    end
  end

  describe "#one_line?" do
    it "returns false by default" do
      expect(RE2::Regexp.new('woo')).to_not be_one_line
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :one_line => true)
      expect(re).to be_one_line
    end
  end

  describe "#max_mem" do
    it "returns the default max memory" do
      expect(RE2::Regexp.new('woo').max_mem).to eq(8388608)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :max_mem => 1024)
      expect(re.max_mem).to eq(1024)
    end
  end

  describe "#match" do
    let(:re) { RE2::Regexp.new('My name is (\S+) (\S+)') }

    it "returns match data given only text" do
      md = re.match("My name is Robert Paulson")
      expect(md).to be_a(RE2::MatchData)
    end

    it "returns nil if there is no match for the given text" do
      expect(re.match("My age is 99")).to be_nil
    end

    it "returns only true or false if no matches are requested" do
      expect(re.match("My name is Robert Paulson", 0)).to eq(true)
      expect(re.match("My age is 99", 0)).to eq(false)
    end

    it "returns only true or false if the pattern has no capturing groups" do
      re = RE2::Regexp.new('My name is')

      expect(re.match('My name is Robert Paulson')).to eq(true)
    end

    it "raises an exception when given nil" do
      expect { re.match(nil) }.to raise_error(TypeError)
    end

    it "raises an exception when given invalid options" do
      expect { re.match("My name is Robert Paulson", "foo") }.to raise_error(TypeError)
    end

    it "accepts anything that can be coerced to a hash as options", :aggregate_failures do
      m = re.match("My name is Robert Paulson", nil)
      expect(m[1]).to eq("Robert")

      m = re.match("My name is Robert Paulson", [])
      expect(m[1]).to eq("Robert")
    end

    it "returns nil with an invalid pattern" do
      re = RE2::Regexp.new('???', :log_errors => false)

      expect(re.match('My name is Robert Paulson')).to be_nil
    end

    it "returns nil with an invalid pattern and options" do
      re = RE2::Regexp.new('???', :log_errors => false)

      expect(re.match('My name is Robert Paulson', submatches: 1)).to be_nil
    end

    it "is unanchored by default", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", submatches: 0)).to eq(true)
      expect(re.match("My name is Robert Paulson, he said", submatches: 0)).to eq(true)
      expect(re.match("He said, My name is Robert Paulson", submatches: 0)).to eq(true)
    end

    it "is unanchored if given a nil anchor", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", anchor: nil, submatches: 0)).to eq(true)
      expect(re.match("My name is Robert Paulson, he said", anchor: nil, submatches: 0)).to eq(true)
      expect(re.match("He said, My name is Robert Paulson", anchor: nil, submatches: 0)).to eq(true)
    end

    it "can be explicitly unanchored", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", anchor: :unanchored, submatches: 0)).to eq(true)
      expect(re.match("My name is Robert Paulson, he said", anchor: :unanchored, submatches: 0)).to eq(true)
      expect(re.match("He said, My name is Robert Paulson", anchor: :unanchored, submatches: 0)).to eq(true)
    end

    it "can anchor the match at both ends", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", anchor: :anchor_both, submatches: 0)).to eq(true)
      expect(re.match("My name is Robert Paulson, he said", anchor: :anchor_both, submatches: 0)).to eq(false)
      expect(re.match("He said, My name is Robert Paulson", anchor: :anchor_both, submatches: 0)).to eq(false)
    end

    it "can anchor the match at the start", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", anchor: :anchor_start, submatches: 0)).to eq(true)
      expect(re.match("My name is Robert Paulson, he said", anchor: :anchor_start, submatches: 0)).to eq(true)
      expect(re.match("He said, My name is Robert Paulson", anchor: :anchor_start, submatches: 0)).to eq(false)
    end

    it "raises an exception when given an invalid anchor" do
      expect { re.match("My name is Robert Paulson", anchor: :invalid) }.to raise_error(ArgumentError, "anchor should be one of: :unanchored, :anchor_start, :anchor_both")
    end

    it "raises an exception when given a non-symbol anchor" do
      expect { re.match("My name is Robert Paulson", anchor: 0) }.to raise_error(TypeError)
    end

    it "can be given an offset at which to start matching", :aggregate_failures do
      m = re.match("My name is Alice Bloggs My name is Robert Paulson", startpos: 24)

      expect(m[1]).to eq("Robert")
      expect(m[2]).to eq("Paulson")
    end

    it "does not match if given an offset past the end of the text", :aggregate_failures do
      expect(re.match("My name is Alice Bloggs", startpos: 99)).to be_nil
    end

    it "raises an exception when given a negative start position" do
      expect { re.match("My name is Robert Paulson", startpos: -1) }.to raise_error(ArgumentError, "startpos should be >= 0")
    end

    it "raises an exception when given a negative number of matches" do
      expect { re.match("My name is Robert Paulson", submatches: -1) }.to raise_error(ArgumentError, "number of matches should be >= 0")
    end

    it "raises an exception when given a non-numeric number of matches" do
      expect { re.match("My name is Robert Paulson", submatches: "foo") }.to raise_error(TypeError)
    end

    it "defaults to extracting all submatches when given nil", :aggregate_failures do
      m = re.match("My name is Robert Paulson", submatches: nil)

      expect(m[1]).to eq("Robert")
      expect(m[2]).to eq("Paulson")
    end

    describe "with a specific number of matches under the total in the pattern" do
      subject { re.match("My name is Robert Paulson", submatches: 1) }

      it "returns a match data object" do
        expect(subject).to be_a(RE2::MatchData)
      end

      it "has the whole match and only the specified number of matches" do
        expect(subject.size).to eq(2)
      end

      it "populates any specified matches" do
        expect(subject[1]).to eq("Robert")
      end

      it "does not populate any matches that weren't included" do
        expect(subject[2]).to be_nil
      end
    end

    describe "with a number of matches over the total in the pattern" do
      subject { re.match("My name is Robert Paulson", submatches: 5) }

      it "returns a match data object" do
        expect(subject).to be_a(RE2::MatchData)
      end

      it "has the whole match the specified number of matches" do
        expect(subject.size).to eq(6)
      end

      it "populates any specified matches" do
        expect(subject[1]).to eq("Robert")
        expect(subject[2]).to eq("Paulson")
      end

      it "pads the remaining matches with nil" do
        expect(subject[3]).to be_nil
        expect(subject[4]).to be_nil
        expect(subject[5]).to be_nil
        expect(subject[6]).to be_nil
      end
    end

    it "accepts the number of submatches as a second argument for compatibility", :aggregate_failures do
      expect(re.match("My name is Robert Paulson", 0)).to eq(true)

      m = re.match("My name is Robert Paulson", 1)
      expect(m[1]).to eq("Robert")
      expect(m[2]).to be_nil

      m = re.match("My name is Robert Paulson", 2)
      expect(m[1]).to eq("Robert")
      expect(m[2]).to eq("Paulson")

      expect { re.match("My name is Robert Paulson", -1) }.to raise_error(ArgumentError, "number of matches should be >= 0")
    end
  end

  describe "#match?" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      expect(re.match?("My name is Robert Paulson")).to eq(true)
      expect(re.match?("My age is 99")).to eq(false)
    end

    it "returns false if the pattern is invalid" do
      re = RE2::Regexp.new('???', :log_errors => false)
      expect(re.match?("My name is Robert Paulson")).to eq(false)
    end
  end

  describe "#=~" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      expect(re =~ "My name is Robert Paulson").to eq(true)
      expect(re =~ "My age is 99").to eq(false)
    end
  end

  describe "#!~" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      expect(re !~ "My name is Robert Paulson").to eq(false)
      expect(re !~ "My age is 99").to eq(true)
    end
  end

  describe "#===" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      expect(re === "My name is Robert Paulson").to eq(true)
      expect(re === "My age is 99").to eq(false)
    end
  end

  describe "#ok?" do
    it "returns true for valid regexps" do
      expect(RE2::Regexp.new('woo')).to be_ok
      expect(RE2::Regexp.new('wo(o)')).to be_ok
      expect(RE2::Regexp.new('((\d)\w+){3,}')).to be_ok
    end

    it "returns false for invalid regexps" do
      expect(RE2::Regexp.new('wo(o', :log_errors => false)).to_not be_ok
      expect(RE2::Regexp.new('wo[o', :log_errors => false)).to_not be_ok
      expect(RE2::Regexp.new('*', :log_errors => false)).to_not be_ok
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
    it "returns the number of groups in a regexp" do
      expect(RE2::Regexp.new('(a)(b)(c)').number_of_capturing_groups).to eq(3)
      expect(RE2::Regexp.new('abc').number_of_capturing_groups).to eq(0)
      expect(RE2::Regexp.new('a((b)c)').number_of_capturing_groups).to eq(2)
    end

    it "returns -1 for an invalid regexp" do
      expect(RE2::Regexp.new('???', :log_errors => false).number_of_capturing_groups).to eq(-1)
    end
  end

  describe "#named_capturing_groups" do
    it "returns a hash of names to indices" do
      expect(RE2::Regexp.new('(?P<bob>a)').named_capturing_groups).to be_a(Hash)
    end

    it "maps names to indices with only one group" do
      groups = RE2::Regexp.new('(?P<bob>a)').named_capturing_groups
      expect(groups["bob"]).to eq(1)
    end

    it "maps names to indices with several groups" do
      groups = RE2::Regexp.new('(?P<bob>a)(o)(?P<rob>e)').named_capturing_groups
      expect(groups["bob"]).to eq(1)
      expect(groups["rob"]).to eq(3)
    end

    it "returns an empty hash for an invalid regexp" do
      expect(RE2::Regexp.new('???', :log_errors => false).named_capturing_groups).to be_empty
    end
  end

  describe "#scan" do
    it "returns a scanner" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It is a truth universally acknowledged")

      expect(scanner).to be_a(RE2::Scanner)
    end
  end

  describe "#partial_match" do
    it "matches the pattern anywhere within the given text" do
      r = RE2::Regexp.new('f(o+)')

      expect(r.partial_match('foo bar', submatches: 0)).to eq(true)
    end

    it "can set the number of submatches to extract", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')
      m = r.partial_match('fooaa bar', submatches: 1)

      expect(m[1]).to eq('oo')
      expect(m[2]).to be_nil

      m = r.partial_match('fooaa bar', submatches: 2)

      expect(m[1]).to eq('oo')
      expect(m[2]).to eq('aa')
    end

    it "raises an error if given non-hash options" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect { r.partial_match('fooaa bar', 'not a hash') }.to raise_error(TypeError)
    end

    it "accepts options that can be coerced to a hash", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')

      m = r.partial_match('fooaa bar', nil)
      expect(m[1]).to eq('oo')

      m = r.partial_match('fooaa bar', [])
      expect(m[1]).to eq('oo')
    end

    it "accepts anything that can be coerced to a string" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect(r.partial_match(StringLike.new('fooaa bar'), submatches: 0)).to eq(true)
    end
  end

  describe "#full_match" do
    it "only matches the pattern if all of the given text matches", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)')

      expect(r.full_match('foo', submatches: 0)).to eq(true)
      expect(r.full_match('foo bar', submatches: 0)).to eq(false)
    end

    it "can set the number of submatches to extract", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')
      m = r.full_match('fooaa', submatches: 1)

      expect(m[1]).to eq('oo')
      expect(m[2]).to be_nil

      m = r.full_match('fooaa', submatches: 2)

      expect(m[1]).to eq('oo')
      expect(m[2]).to eq('aa')
    end

    it "raises an error if given non-hash options" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect { r.full_match('fooaa', 'not a hash') }.to raise_error(TypeError)
    end

    it "accepts options that can be coerced to a hash", :aggregate_failures do
      r = RE2::Regexp.new('f(o+)(a+)')

      m = r.full_match('fooaa', nil)
      expect(m[1]).to eq('oo')

      m = r.full_match('fooaa', [])
      expect(m[1]).to eq('oo')
    end

    it "accepts anything that can be coerced to a string" do
      r = RE2::Regexp.new('f(o+)(a+)')

      expect(r.full_match(StringLike.new('fooaa'), submatches: 0)).to eq(true)
    end
  end
end
