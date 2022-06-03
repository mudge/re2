RSpec.describe RE2::Set do

  # libre2, as of 2022-06-01, in set.cc, does print to stderr (fd 2) even when
  # :log_errors is false. So we need to temporarily redirect stderr while
  # running tests that might print to it.
  def silence_stderr(&blk)
    null_stream = StringIO.new
    original_stream = $stderr
    $stderr = null_stream

    blk.call
  ensure
    $stderr = original_stream
  end

  describe "#initialize" do
    it "returns an instance given no args" do
      set = RE2::Set.new
      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given only an anchor" do
      set = RE2::Set.new(:unanchored)
      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given an anchor and options" do
      set = RE2::Set.new(:unanchored, :case_sensitive => false)
      expect(set).to be_a(RE2::Set)
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Set.new(0) }.to raise_error(TypeError)
    end
  end

  describe "#add" do
    it "allows multiple patterns to be added", :aggregate_failures do
      set = RE2::Set.new
      expect(set.add("abc")).to eq(0)
      expect(set.add("def")).to eq(1)
      expect(set.add("ghi")).to eq(2)
    end

    it "rejects invalid patterns when added" do
      set = RE2::Set.new(:unanchored, :log_errors => false)
      expect { set.add("???") }.to raise_error(ArgumentError)
    end

    it "raises an error if called after #compile" do
      set = RE2::Set.new(:unanchored, :log_errors => false)
      set.add("abc")
      set.compile
      silence_stderr do
        expect { set.add("def") }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#compile" do
    it "compiles the set without error" do
      set = RE2::Set.new
      set.add("abc")
      set.add("def")
      set.add("ghi")
      expect { set.compile }.not_to raise_error
    end
  end

  describe "#match" do
    it "matches against multiple patterns" do
      set = RE2::Set.new
      set.add("abc")
      set.add("def")
      set.add("ghi")
      set.compile
      matches = set.match("abcdefghi")
      expect(matches).to eq([0, 1, 2])
    end

    it "raises an error if called before #compile" do
      set = RE2::Set.new(:unanchored, :log_errors => false)
      silence_stderr do
        expect { set.match("") }.to raise_error(RE2::Set::MatchError)
      end
    end
  end
end
