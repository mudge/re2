require "spec_helper"
require "re2/string"

class String
  include RE2::String
end

describe RE2::String do
  describe "#re2_sub!" do
    it "delegates to RE2.Replace to perform replacement" do
      "My name is Robert Paulson".re2_sub!('Robert', 'Crobert').must_equal("My name is Crobert Paulson")
    end

    it "doe perform an in-place replacement" do
      string = "My name is Robert Paulson"
      string.re2_sub!('Robert', 'Crobert').must_be_same_as(string)
    end
  end

  describe "#re2_gsub!" do
    it "delegates to RE2.GlobalReplace to perform replacement" do
      "My name is Robert Paulson".re2_gsub!('a', 'e').must_equal("My neme is Robert Peulson")
    end

    it "doe perform an in-place replacement" do
      string = "My name is Robert Paulson"
      string.re2_gsub!('a', 'e').must_be_same_as(string)
    end
  end

  describe "#re2_sub" do
    it "delegates to RE2.Replace to perform replacement" do
      "My name is Robert Paulson".re2_sub('Robert', 'Crobert').must_equal("My name is Crobert Paulson")
    end

    it "doesn't perform an in-place replacement" do
      string = "My name is Robert Paulson"
      string.re2_sub('Robert', 'Crobert').wont_be_same_as(string)
    end
  end

  describe "#re2_gsub" do
    it "delegates to RE2.GlobalReplace to perform replacement" do
      "My name is Robert Paulson".re2_gsub('a', 'e').must_equal("My neme is Robert Peulson")
    end

    it "doesn't perform an in-place replacement" do
      string = "My name is Robert Paulson"
      string.re2_gsub('a', 'e').wont_be_same_as(string)
    end
  end

  describe "#re2_match" do
    it "delegates to RE2::Regexp#match to perform matches" do
      md = "My name is Robert Paulson".re2_match('My name is (\S+) (\S+)')
      md.must_be_instance_of(RE2::MatchData)
      md[0].must_equal("My name is Robert Paulson")
      md[1].must_equal("Robert")
      md[2].must_equal("Paulson")
    end

    it "supports limiting the number of matches" do
      md = "My name is Robert Paulson".re2_match('My name is (\S+) (\S+)', 0)
      md.must_equal(true)
    end
  end

  describe "#re2_escape" do
    it "escapes the string for use in regular expressions" do
      "1.5-2.0?".re2_escape.must_equal('1\.5\-2\.0\?')
    end
  end

  describe "#re2_quote" do
    it "escapes the string for use in regular expressions" do
      "1.5-2.0?".re2_quote.must_equal('1\.5\-2\.0\?')
    end
  end
end
