require "spec_helper"

describe RE2::Regexp do
  describe "#initialize" do
    it "returns an instance given only a pattern" do
      re = RE2::Regexp.new('woo')
      re.must_be_instance_of(RE2::Regexp)
    end

    it "returns an instance given a pattern and options" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      re.must_be_instance_of(RE2::Regexp)
    end
  end

  describe "#compile" do
    it "returns an instance given only a pattern" do
      re = RE2::Regexp.compile('woo')
      re.must_be_instance_of(RE2::Regexp)
    end

    it "returns an instance given a pattern and options" do
      re = RE2::Regexp.compile('woo', :case_sensitive => false)
      re.must_be_instance_of(RE2::Regexp)
    end
  end

  describe "#options" do
    it "returns a hash of options" do
      options = RE2::Regexp.new('woo').options
      options.must_be_instance_of(Hash)
    end

    it "is populated with default options when nothing has been set" do
      options = RE2::Regexp.new('woo').options
      assert options[:utf8]
      refute options[:posix_syntax]
      refute options[:longest_match]
      assert [:log_errors]
      refute options[:literal]
      refute options[:never_nl]
      assert options[:case_sensitive]
      refute options[:perl_classes]
      refute options[:word_boundary]
      refute options[:one_line]
    end

    it "is populated with overridden options when specified" do
      options = RE2::Regexp.new('woo', :case_sensitive => false).options
      refute options[:case_sensitive]
    end
  end

  describe "#error" do
    it "returns nil if there is no error" do
      error = RE2::Regexp.new('woo').error
      error.must_be_nil
    end

    # Use log_errors => false to suppress RE2's logging to STDERR.
    it "contains the error string if there is an error" do
      error = RE2::Regexp.new('wo(o', :log_errors => false).error
      error.must_equal("missing ): wo(o")
    end
  end

  describe "#error_arg" do
    it "returns nil if there is no error" do
      error_arg = RE2::Regexp.new('woo').error_arg
      error_arg.must_be_nil
    end

    it "returns the offending portin of the regexp if there is an error" do
      error_arg = RE2::Regexp.new('wo(o', :log_errors => false).error_arg
      error_arg.must_equal("wo(o")
    end
  end

  describe "#program_size" do
    it "returns a numeric value" do
      program_size = RE2::Regexp.new('w(o)(o)').program_size
      program_size.must_be_instance_of(Fixnum)
    end
  end

  describe "#to_str" do
    it "returns the original pattern" do
      string = RE2::Regexp.new('w(o)(o)').to_str
      string.must_equal("w(o)(o)")
    end
  end

  describe "#pattern" do
    it "returns the original pattern" do
      pattern = RE2::Regexp.new('w(o)(o)').pattern
      pattern.must_equal("w(o)(o)")
    end
  end

  describe "#inspect" do
    it "shows the class name and original pattern" do
      string = RE2::Regexp.new('w(o)(o)').inspect
      string.must_equal("#<RE2::Regexp /w(o)(o)/>")
    end
  end

  describe "#utf8?" do
    it "returns true by default" do
      RE2::Regexp.new('woo').must_be(:utf8?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :utf8 => false)
      re.wont_be(:utf8?)
    end
  end

  describe "#posix_syntax?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:posix_syntax?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :posix_syntax => true)
      re.must_be(:posix_syntax?)
    end
  end

  describe "#literal?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:literal?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :literal => true)
      re.must_be(:literal?)
    end
  end

  describe "#never_nl?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:never_nl?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :never_nl => true)
      re.must_be(:never_nl?)
    end
  end

  describe "#case_sensitive?" do
    it "returns true by default" do
      RE2::Regexp.new('woo').must_be(:case_sensitive?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      re.wont_be(:case_sensitive?)
    end
  end

  describe "#case_insensitive?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:case_insensitive?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      re.must_be(:case_insensitive?)
    end
  end

  describe "#casefold?" do
    it "returns true by default" do
      RE2::Regexp.new('woo').wont_be(:casefold?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :case_sensitive => false)
      re.must_be(:casefold?)
    end
  end

  describe "#longest_match?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:casefold?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :longest_match => true)
      re.must_be(:longest_match?)
    end
  end

  describe "#log_errors?" do
    it "returns true by default" do
      RE2::Regexp.new('woo').must_be(:log_errors?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :log_errors => false)
      re.wont_be(:log_errors?)
    end
  end

  describe "#perl_classes?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:perl_classes?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :perl_classes => true)
      re.must_be(:perl_classes?)
    end
  end

  describe "#word_boundary?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:word_boundary?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :word_boundary => true)
      re.must_be(:word_boundary?)
    end
  end

  describe "#one_line?" do
    it "returns false by default" do
      RE2::Regexp.new('woo').wont_be(:one_line?)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :one_line => true)
      re.must_be(:one_line?)
    end
  end

  describe "#max_mem" do
    it "returns the default max memory" do
      RE2::Regexp.new('woo').max_mem.must_equal(8388608)
    end

    it "can be overridden on initialization" do
      re = RE2::Regexp.new('woo', :max_mem => 1024)
      re.max_mem.must_equal(1024)
    end
  end

  describe "#match" do
    let(:re) { RE2::Regexp.new('My name is (\S+) (\S+)') }

    it "returns match data given only text" do
      md = re.match("My name is Robert Paulson")
      md.must_be_instance_of(RE2::MatchData)
    end

    it "returns nil if there is no match for the given text" do
      re.match("My age is 99").must_be_nil
    end

    it "returns only true or false if no matches are requested" do
      re.match("My name is Robert Paulson", 0).must_equal(true)
      re.match("My age is 99", 0).must_equal(false)
    end

    describe "with a specific number of matches under the total in the pattern" do
      subject { re.match("My name is Robert Paulson", 1) }

      it "returns a match data object" do
        subject.must_be_instance_of(RE2::MatchData)
      end

      it "has the whole match and only the specified number of matches" do
        subject.size.must_equal(2)
      end

      it "populates any specified matches" do
        subject[1].must_equal("Robert")
      end

      it "does not populate any matches that weren't included" do
        subject[2].must_be_nil
      end
    end

    describe "with a number of matches over the total in the pattern" do
      subject { re.match("My name is Robert Paulson", 5) }

      it "returns a match data object" do
        subject.must_be_instance_of(RE2::MatchData)
      end

      it "has the whole match the specified number of matches" do
        subject.size.must_equal(6)
      end

      it "populates any specified matches" do
        subject[1].must_equal("Robert")
        subject[2].must_equal("Paulson")
      end

      it "pads the remaining matches with nil" do
        subject[3].must_be_nil
        subject[4].must_be_nil
        subject[5].must_be_nil
        subject[6].must_be_nil
      end
    end
  end

  describe "#match?" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      re.match?("My name is Robert Paulson").must_equal(true)
      re.match?("My age is 99").must_equal(false)
    end
  end

  describe "#=~" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      (re =~ "My name is Robert Paulson").must_equal(true)
      (re =~ "My age is 99").must_equal(false)
    end
  end

  describe "#!~" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      (re !~ "My name is Robert Paulson").must_equal(false)
      (re !~ "My age is 99").must_equal(true)
    end
  end

  describe "#===" do
    it "returns only true or false if no matches are requested" do
      re = RE2::Regexp.new('My name is (\S+) (\S+)')
      (re === "My name is Robert Paulson").must_equal(true)
      (re === "My age is 99").must_equal(false)
    end
  end

  describe "#ok?" do
    it "returns true for valid regexps" do
      RE2::Regexp.new('woo').must_be(:ok?)
      RE2::Regexp.new('wo(o)').must_be(:ok?)
      RE2::Regexp.new('((\d)\w+){3,}').must_be(:ok?)
    end

    it "returns false for invalid regexps" do
      RE2::Regexp.new('wo(o', :log_errors => false).wont_be(:ok?)
      RE2::Regexp.new('wo[o', :log_errors => false).wont_be(:ok?)
      RE2::Regexp.new('*', :log_errors => false).wont_be(:ok?)
    end
  end

  describe "#escape" do
    it "transforms a string into a regexp" do
      RE2::Regexp.escape("1.5-2.0?").must_equal('1\.5\-2\.0\?')
    end
  end

  describe "#quote" do
    it "transforms a string into a regexp" do
      RE2::Regexp.quote("1.5-2.0?").must_equal('1\.5\-2\.0\?')
    end
  end

  describe "#number_of_capturing_groups" do
    it "returns the number of groups in a regexp" do
      RE2::Regexp.new('(a)(b)(c)').number_of_capturing_groups.must_equal(3)
      RE2::Regexp.new('abc').number_of_capturing_groups.must_equal(0)
      RE2::Regexp.new('a((b)c)').number_of_capturing_groups.must_equal(2)
    end
  end

  describe "#named_capturing_groups" do
    it "returns a hash of names to indices" do
      RE2::Regexp.new('(?P<bob>a)').named_capturing_groups.must_be_instance_of(Hash)
    end

    it "maps names to indices with only one group" do
      groups = RE2::Regexp.new('(?P<bob>a)').named_capturing_groups
      groups["bob"].must_equal(1)
    end

    it "maps names to indices with several groups" do
      groups = RE2::Regexp.new('(?P<bob>a)(o)(?P<rob>e)').named_capturing_groups
      groups["bob"].must_equal(1)
      groups["rob"].must_equal(3)
    end
  end

  describe "#scan" do
    it "returns a scanner" do
      r = RE2::Regexp.new('(\w+)')
      scanner = r.scan("It is a truth universally acknowledged")

      scanner.must_be_instance_of(RE2::Scanner)
    end
  end
end
