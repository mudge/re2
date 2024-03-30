# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

begin
  ::RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "#{Regexp.last_match(1)}/re2.so"
rescue LoadError
  require 're2.so'
end

require "re2/regexp"
require "re2/scanner"
require "re2/version"
