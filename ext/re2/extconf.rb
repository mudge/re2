# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2012, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'

if ENV["CC"]
  RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"]
  RbConfig::CONFIG["CC"] = ENV["CC"]
end

if ENV["CXX"]
  RbConfig::MAKEFILE_CONFIG["CXX"] = ENV["CXX"]
  RbConfig::CONFIG["CXX"] = ENV["CXX"]
end

header_dirs = [
  "/usr/local/include",
  "/opt/homebrew/include",
  "/usr/include"
]

lib_dirs = [
  "/usr/local/lib",
  "/opt/homebrew/lib",
  "/usr/lib"
]

dir_config("re2", header_dirs, lib_dirs)

$CFLAGS << " -Wall -Wextra -funroll-loops"

# Pass -x c++ to force gcc to compile the test program
# as C++ (as it will end in .c by default).
compile_options = "-x c++"

have_library("stdc++")
have_header("stdint.h")
have_func("rb_str_sublen")

unless have_library("re2")
  abort "You must have re2 installed and specified with --with-re2-dir, please see https://github.com/google/re2/wiki/Install"
end

TRY_CXXFLAGS = %w[-std=c++20 -std=c++17 -std=c++11 -std=c++0x]

# Recent versions of re2 depend directly on abseil, which requires a
# compiler with C++14 support (see
# https://github.com/abseil/abseil-cpp/issues/1127 and
# https://github.com/abseil/abseil-cpp/issues/1431). However, the
# `std=c++14` flag doesn't appear to suffice; we need at least
# `std=c++17`.
checking_for("re2 requires a C++14 compiler") do
  success = false
  minimal_program = <<SRC
#include <re2/re2.h>
int main() { return 0; }
SRC

  if try_compile(minimal_program, compile_options)
    success = true
  else
    TRY_CXXFLAGS.each do |version_flag|
      if try_compile(minimal_program, compile_options + " #{version_flag}")
        compile_options << " #{version_flag}"
        $CPPFLAGS << " #{version_flag}"
        success = true
        break
      end
    end
  end

  abort "Cannot compile re2 with your compiler: recent versions require C++14 support." unless success
end

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

  if try_compile(test_re2_match_signature, compile_options)
    $defs.push("-DHAVE_ENDPOS_ARGUMENT")
  end
end

checking_for("RE2::Set::Match() with error information") do
  test_re2_set_match_signature = <<SRC
#include <vector>
#include <re2/re2.h>
#include <re2/set.h>

int main() {
  RE2::Set s(RE2::DefaultOptions, RE2::UNANCHORED);
  s.Add("foo", NULL);
  s.Compile();

  std::vector<int> v;
  RE2::Set::ErrorInfo ei;
  s.Match("foo", &v, &ei);

  return 0;
}
SRC

  if try_compile(test_re2_set_match_signature, compile_options)
    $defs.push("-DHAVE_ERROR_INFO_ARGUMENT")
  end
end

create_makefile("re2")
