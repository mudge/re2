# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt


module RE2
  class Scanner
    include Enumerable

    def each
      if block_given?
        while matches = scan
          yield matches
        end
      else
        to_enum(:each)
      end
    end
  end
end
