require 'mkmf'

have_library("re2")
have_library("stdc++")
dir_config("re2")
create_makefile("re2")
