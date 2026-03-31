# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require "re2"

module RE2
  # @deprecated Use methods on {RE2} and {RE2::Regexp} instead.
  module String
    # @deprecated Use {RE2.replace} instead.
    def re2_sub(*args)
      RE2.replace(self, *args)
    end

    # @deprecated Use {RE2.global_replace} instead.
    def re2_gsub(*args)
      RE2.global_replace(self, *args)
    end

    # @deprecated Use {RE2::Regexp#match} instead.
    def re2_match(pattern, *args)
      RE2::Regexp.new(pattern).match(self, *args)
    end

    # @deprecated Use {RE2.escape} instead.
    def re2_escape
      RE2.escape(self)
    end

    alias_method :re2_quote, :re2_escape
  end
end
