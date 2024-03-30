# frozen_string_literal: true

require "re2/string"

class String
  include RE2::String
end

RSpec.describe RE2::String do
  describe "#re2_sub" do
    it "delegates to RE2.Replace to perform replacement" do
      expect("My name is Robert Paulson".re2_sub('Robert', 'Crobert')).to eq("My name is Crobert Paulson")
    end

    it "doesn't perform an in-place replacement" do
      string = "My name is Robert Paulson"

      expect(string.re2_sub('Robert', 'Crobert')).not_to equal(string)
    end
  end

  describe "#re2_gsub" do
    it "delegates to RE2.GlobalReplace to perform replacement" do
      expect("My name is Robert Paulson".re2_gsub('a', 'e')).to eq("My neme is Robert Peulson")
    end

    it "doesn't perform an in-place replacement" do
      string = "My name is Robert Paulson"

      expect(string.re2_gsub('a', 'e')).not_to equal(string)
    end
  end

  describe "#re2_match" do
    it "delegates to RE2::Regexp#match to perform matches", :aggregate_failures do
      md = "My name is Robert Paulson".re2_match('My name is (\S+) (\S+)')

      expect(md).to be_a(RE2::MatchData)
      expect(md[0]).to eq("My name is Robert Paulson")
      expect(md[1]).to eq("Robert")
      expect(md[2]).to eq("Paulson")
    end

    it "supports limiting the number of matches" do
      md = "My name is Robert Paulson".re2_match('My name is (\S+) (\S+)', 0)

      expect(md).to eq(true)
    end
  end

  describe "#re2_escape" do
    it "escapes the string for use in regular expressions" do
      expect("1.5-2.0?".re2_escape).to eq('1\.5\-2\.0\?')
    end
  end

  describe "#re2_quote" do
    it "escapes the string for use in regular expressions" do
      expect("1.5-2.0?".re2_quote).to eq('1\.5\-2\.0\?')
    end
  end
end
