# frozen_string_literal: true

RSpec.describe RE2::Set do
  describe "#initialize" do
    it "returns an instance given no args" do
      set = RE2::Set.new

      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given only an anchor of :unanchored" do
      set = RE2::Set.new(:unanchored)

      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given only an anchor of :anchor_start" do
      set = RE2::Set.new(:anchor_start)

      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given only an anchor of :anchor_both" do
      set = RE2::Set.new(:anchor_both)

      expect(set).to be_a(RE2::Set)
    end

    it "returns an instance given an anchor and options" do
      set = RE2::Set.new(:unanchored, case_sensitive: false)

      expect(set).to be_a(RE2::Set)
    end

    it "raises an error if given an inappropriate type" do
      expect { RE2::Set.new(0) }.to raise_error(TypeError)
    end

    it "raises an error if given an invalid anchor" do
      expect { RE2::Set.new(:not_a_valid_anchor) }.to raise_error(
        ArgumentError,
        "anchor should be one of: :unanchored, :anchor_start, :anchor_both"
      )
    end

    it "raises an error if given an invalid anchor and options" do
      expect { RE2::Set.new(:not_a_valid_anchor, case_sensitive: false) }.to raise_error(
        ArgumentError,
        "anchor should be one of: :unanchored, :anchor_start, :anchor_both"
      )
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
      set = RE2::Set.new(:unanchored, log_errors: false)

      expect { set.add("???") }.to raise_error(ArgumentError, /str rejected by RE2::Set->Add\(\)/)
    end

    it "truncates error messages to 100 characters" do
      set = RE2::Set.new(:unanchored, log_errors: false)

      expect { set.add("(?P<#{'o' * 200}") }.to raise_error(ArgumentError, "str rejected by RE2::Set->Add(): invalid named capture group: (?P<oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
    end

    it "raises an error if called after #compile" do
      set = RE2::Set.new(:unanchored, log_errors: false)
      set.add("abc")
      set.compile

      silence_stderr do
        expect { set.add("def") }.to raise_error(ArgumentError)
      end
    end

    it "raises an error if given a pattern that can't be coerced to a String" do
      set = RE2::Set.new(:unanchored, log_errors: false)

      expect { set.add(0) }.to raise_error(TypeError)
    end

    it "accepts a pattern that can be coerced to a String" do
      set = RE2::Set.new

      expect(set.add(StringLike.new("abc"))).to eq(0)
    end
  end

  describe "#compile" do
    it "compiles the set without error" do
      set = RE2::Set.new
      set.add("abc")
      set.add("def")
      set.add("ghi")

      expect(set.compile).to be_truthy
    end
  end

  describe "#match" do
    it "matches against multiple patterns" do
      set = RE2::Set.new
      set.add("abc")
      set.add("def")
      set.add("ghi")
      set.compile

      expect(set.match("abcdefghi", exception: false)).to eq([0, 1, 2])
    end

    it "returns an empty array if there is no match" do
      set = RE2::Set.new
      set.add("abc")
      set.compile

      expect(set.match("def", exception: false)).to be_empty
    end

    it "supports matching null bytes", :aggregate_failures do
      set = RE2::Set.new
      set.add("a\0b")
      set.compile

      expect(set.match("a\0b", exception: false)).to eq([0])
    end

    it "returns an empty array if there is no match when :exception is true" do
      skip "Underlying RE2::Set::Match does not output error information" unless RE2::Set.match_raises_errors?

      set = RE2::Set.new
      set.add("abc")
      set.compile

      expect(set.match("def")).to be_empty
    end

    it "raises an error if called before #compile by default" do
      skip "Underlying RE2::Set::Match does not output error information" unless RE2::Set.match_raises_errors?

      set = RE2::Set.new(:unanchored, log_errors: false)

      silence_stderr do
        expect { set.match("") }.to raise_error(RE2::Set::MatchError)
      end
    end

    it "raises an error if called before #compile when :exception is true" do
      skip "Underlying RE2::Set::Match does not output error information" unless RE2::Set.match_raises_errors?

      set = RE2::Set.new(:unanchored, log_errors: false)

      silence_stderr do
        expect { set.match("", exception: true) }.to raise_error(RE2::Set::MatchError)
      end
    end

    it "returns an empty array if called before #compile when :exception is false" do
      set = RE2::Set.new(:unanchored, log_errors: false)

      silence_stderr do
        expect(set.match("", exception: false)).to be_empty
      end
    end

    it "raises an error if :exception is true and RE2 does not support it" do
      skip "Underlying RE2::Set::Match outputs error information" if RE2::Set.match_raises_errors?

      set = RE2::Set.new(:unanchored, log_errors: false)

      silence_stderr do
        expect { set.match("", exception: true) }.to raise_error(RE2::Set::UnsupportedError)
      end
    end

    it "raises an error if given non-hash options" do
      set = RE2::Set.new

      expect { set.match("", 0) }.to raise_error(TypeError)
    end

    it "raises a Type Error if given input that can't be coerced to a String" do
      set = RE2::Set.new
      set.add("abc")
      set.compile

      expect { set.match(0, exception: false) }.to raise_error(TypeError)
    end

    it "accepts input if it can be coerced to a String" do
      set = RE2::Set.new
      set.add("abc")
      set.compile

      expect(set.match(StringLike.new("abcdef"), exception: false)).to contain_exactly(0)
    end
  end

  describe "#size" do
    it "returns the number of patterns added to the set", :aggregate_failures do
      skip "Underlying RE2::Set has no Size method" unless RE2::Set.size?

      set = RE2::Set.new

      expect(set.size).to eq(0)

      set.add("abc")

      expect(set.size).to eq(1)

      set.add("def")

      expect(set.size).to eq(2)
    end

    it "raises an error if RE2 does not support Set::Size" do
      skip "Underlying RE2::Set has a Size method" if RE2::Set.size?

      set = RE2::Set.new

      expect { set.size }.to raise_error(RE2::Set::UnsupportedError)
    end
  end

  describe "#length" do
    it "is an alias for size" do
      skip "Underlying RE2::Set has no Size method" unless RE2::Set.size?

      set = RE2::Set.new

      expect(set.length).to eq(0)

      set.add("abc")

      expect(set.length).to eq(1)

      set.add("def")

      expect(set.length).to eq(2)
    end
  end

  def silence_stderr
    original_stream = STDERR

    if File.const_defined?(:NULL)
      STDERR.reopen(File::NULL)
    else
      platform = RUBY_PLATFORM == 'java' ? RbConfig::CONFIG['host_os'] : RUBY_PLATFORM

      case platform
      when /mswin|mingw/i
        STDERR.reopen('NUL')
      when /amiga/i
        STDERR.reopen('NIL')
      when /openvms/i
        STDERR.reopen('NL:')
      else
        STDERR.reopen('/dev/null')
      end
    end

    yield
  ensure
    STDERR.reopen(original_stream)
  end
end
