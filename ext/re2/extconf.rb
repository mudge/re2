# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010, Paul Mucur (http://mucur.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'

incl, lib = dir_config("re2", "/usr/local/include", "/usr/local/lib")

$CFLAGS << " -Wall -Wextra -funroll-loops"

have_library("stdc++")
if have_library("re2")
  checking_for("RE2::Match() with endpos argument") do
    with_cflags("-x c++") do
      test_re2_match_signature = <<SRC
#include <re2/re2.h>

extern "C" int main() {
  RE2 pattern("test");
  re2::StringPiece *match;
  pattern.Match("test", 0, 0, RE2::UNANCHORED, match, 0);

  return 0;
}
SRC
      if try_compile(test_re2_match_signature)
        $defs.push("-DHAVE_ENDPOS_ARGUMENT")
      end
    end
  end

  create_makefile("re2")
else
  abort "You must have re2 installed and specified with --with-re2-dir, please see http://code.google.com/p/re2/wiki/Install"
end
