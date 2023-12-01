# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2014, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require "re2"

module RE2
  module String
    # @deprecated Replaces the first occurrence +pattern+ with +rewrite+ and
    # returns a new string.
    #
    # @see RE2.Replace
    def re2_sub(*args)
      RE2.Replace(self, *args)
    end

    # @deprecated Replaces every occurrence of +pattern+ with +rewrite+ and
    # return a new string.
    #
    # @see RE2.GlobalReplace
    def re2_gsub(*args)
      RE2.GlobalReplace(self, *args)
    end

    # @deprecated Match the pattern and return either a boolean (if no
    # submatches are required) or a {RE2::MatchData} instance.
    #
    # @see RE2::Regexp#match
    def re2_match(pattern, *args)
      RE2::Regexp.new(pattern).match(self, *args)
    end

    # @deprecated Escapes all potentially meaningful regexp characters. The
    # returned string, used as a regular expression, will exactly match the
    # original string.
    #
    # @see RE2.quote
    def re2_escape
      RE2.QuoteMeta(self)
    end

    alias_method :re2_quote, :re2_escape
  end
end
