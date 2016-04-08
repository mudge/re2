# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2012, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'

incl, lib = dir_config("re2", "/usr/local/include", "/usr/local/lib")

$CXXFLAGS << " -Wall -Wextra -funroll-loops -std=c++11"

have_library("stdc++")
have_header("stdint.h")
have_func("rb_str_sublen")

if have_library("re2")

  # Determine which version of re2 the user has installed.
  # Revision d9f8806c004d added an `endpos` argument to the
  # generic Match() function.
  #
  # To test for this, try to compile a simple program that uses
  # the newer form of Match() and set a flag if it is successful.
  checking_for("RE2::Match() with endpos argument") do
    test_re2_match_signature = <<SRC
#include <re2/re2.h>

int main() {
  RE2 pattern("test");
  re2::StringPiece *match;
  pattern.Match("test", 0, 0, RE2::UNANCHORED, match, 0);

  return 0;
}
SRC

    # Pass -x c++ to force gcc to compile the test program
    # as C++ (as it will end in .c by default).
    if try_compile(test_re2_match_signature, "-x c++ #{$CXXFLAGS}")
      $defs.push("-DHAVE_ENDPOS_ARGUMENT")
    end
  end

  create_makefile("re2")
else
  abort "You must have re2 installed and specified with --with-re2-dir, please see https://github.com/google/re2/wiki/Install"
end
