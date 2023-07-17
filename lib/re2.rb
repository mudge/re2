# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2014, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt
begin
  ::RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "#{Regexp.last_match(1)}/re2.so"
rescue LoadError
  require 're2.so'
end

require "re2/scanner"
require "re2/version"
