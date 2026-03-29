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
    # Returns an array of the match values at the given indices or names.
    #
    # @param [Array<Integer, String, Symbol>] indexes the indices or names of
    #   the matches to fetch
    # @return [Array<String, nil>] the values at the given indices or names
    # @example
    #   m = RE2::Regexp.new('(?P<a>\d+) (?P<b>\d+)').match("123 456")
    #   m.values_at(1, 2)   #=> ["123", "456"]
    #   m.values_at(:a, :b) #=> ["123", "456"]
    #   m.values_at(1, :b)  #=> ["123", "456"]
    def values_at(*indexes)
      indexes.map { |i| self[i] }
    end
  end
end
