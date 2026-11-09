# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt


module RE2
  class MatchData
    # Return whether this match has the same regular expression, text, and
    # submatch offsets as another {RE2::MatchData}, like Ruby's own
    # `MatchData#==`.
    #
    # @param [Object] other the object to compare against
    # @return [Boolean] whether the two matches are equal
    # @example
    #   re = RE2::Regexp.new('(\d+)')
    #   re.match("abc 123") == re.match("abc 123") #=> true
    #   re.match("abc 123") == re.match("123 abc") #=> false
    def ==(other)
      other.is_a?(RE2::MatchData) &&
        regexp == other.regexp &&
        string == other.string &&
        byteoffsets == other.byteoffsets
    end

    alias_method :eql?, :==

    # Return a hash based on the regular expression, text, and submatch offsets
    # so that equal {RE2::MatchData}s can be used as Hash keys.
    #
    # @return [Integer] the hash of the match
    def hash
      [regexp, string, byteoffsets].hash
    end

    protected

    def byteoffsets
      Array.new(size) { |i| byteoffset(i) }
    end
  end
end
