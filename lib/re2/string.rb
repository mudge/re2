# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2014, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require "re2"

module RE2
  module String

    # Replaces the first occurrence +pattern+ with +rewrite+ and returns a new
    # string.
    #
    # @param [String, RE2::Regexp] pattern a regexp matching text to be replaced
    # @param [String] rewrite the string to replace with
    # @example
    #   "hello there".re2_sub("hello", "howdy") #=> "howdy there"
    #   re2 = RE2.new("hel+o")
    #   "hello there".re2_sub(re2, "yo")        #=> "yo there"
    #   text = "Good morning"
    #   text.re2_sub("morn", "even")            #=> "Good evening"
    #   text                                    #=> "Good morning"
    def re2_sub(*args)
      RE2.Replace(self, *args)
    end

    # Replaces every occurrence of +pattern+ with +rewrite+ and return a new string.
    #
    # @param [String, RE2::Regexp] pattern a regexp matching text to be replaced
    # @param [String] rewrite the string to replace with
    # @example
    #   "hello there".re2_gsub("e", "i")   #=> "hillo thiri"
    #   re2 = RE2.new("oo?")
    #   "whoops-doops".re2_gsub(re2, "e")  #=> "wheps-deps"
    #   text = "Good morning"
    #   text.re2_gsub("o", "ee")           #=> "Geeeed meerning"
    #   text                               #=> "Good morning"
    def re2_gsub(*args)
      RE2.GlobalReplace(self, *args)
    end

    # Match the pattern and return either a boolean (if no submatches are required)
    # or a {RE2::MatchData} instance.
    #
    # @return [Boolean, RE2::MatchData]
    #
    # @overload match(pattern)
    #   Returns an {RE2::MatchData} containing the matching
    #   pattern and all subpatterns resulting from looking for
    #   +pattern+.
    #
    #   @param [String, RE2::Regexp] pattern the regular expression to match
    #   @return [RE2::MatchData] the matches
    #   @raise [NoMemoryError] if there was not enough memory to allocate the matches
    #   @example
    #     r = RE2::Regexp.new('w(o)(o)')
    #     "woo".re2_match(r)             #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
    #
    # @overload match(pattern, 0)
    #   Returns either true or false indicating whether a
    #   successful match was made.
    #
    #   @param [String, RE2::Regexp] pattern the regular expression to match
    #   @return [Boolean] whether the match was successful
    #   @raise [NoMemoryError] if there was not enough memory to allocate the matches
    #   @example
    #     r = RE2::Regexp.new('w(o)(o)')
    #     "woo".re2_match(0) #=> true
    #     "bob".re2_match(0) #=> false
    #
    # @overload match(pattern, number_of_matches)
    #   See +match(pattern)+ but with a specific number of
    #   matches returned (padded with nils if necessary).
    #
    #   @param [String, RE2::Regexp] pattern the regular expression to match
    #   @param [Fixnum] number_of_matches the number of matches to return
    #   @return [RE2::MatchData] the matches
    #   @raise [NoMemoryError] if there was not enough memory to allocate the matches
    #   @example
    #     r = RE2::Regexp.new('w(o)(o)')
    #     "woo".re2_match(r, 1) #=> #<RE2::MatchData "woo" 1:"o">
    #     "woo".re2_match(r, 3) #=> #<RE2::MatchData "woo" 1:"o" 2:"o" 3:nil>
    def re2_match(pattern, *args)
      RE2::Regexp.new(pattern).match(self, *args)
    end

    # Escapes all potentially meaningful regexp characters.
    # The returned string, used as a regular expression, will exactly match the
    # original string.
    #
    # @return [String] the escaped string
    # @example
    #   "1.5-2.0?".escape    #=> "1\.5\-2\.0\?"
    def re2_escape
      RE2.QuoteMeta(self)
    end

    alias_method :re2_quote, :re2_escape
  end
end
