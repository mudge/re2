# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010, Paul Mucur (http://mucur.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'

abort "You must have re2 installed, please go to http://code.google.com/p/re2/wiki/Install" unless have_library("re2")
have_library("stdc++")
dir_config("re2")
create_makefile("re2")
