# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2012, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'
require 'shellwords'

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

LIB_DIRS = [
  "/usr/local/lib",
  "/opt/homebrew/lib",
  "/usr/lib",
  "/usr/lib/x86_64-linux-gnu"
].select { |dir| Dir.exist?(dir) }

def libflag_to_filename(ldflag)
  case ldflag
  when /\A-l(.+)/
    "lib#{Regexp.last_match(1)}.#{$LIBEXT}"
  end
end

def resolve_static_library(arg)
  libs_path = pkg_config('re2', 'libs-only-L')

  re2_dirs =
    if libs_path.nil? || libs_path.empty?
      LIB_DIRS
    else
      # There should only be one path, but assume there can be multiple.
      libs_path.strip.split(' ').map { |lib| lib.gsub(/^-L/, '') }
    end

  filename = libflag_to_filename(arg)
  dir = re2_dirs.find { |path| File.exist?(File.join(path, filename)) }

  raise "Unable to find #{filename} in #{re2_dirs}" unless dir

  File.join(dir, filename)
end

dir_config("re2", header_dirs, LIB_DIRS)

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

# Recent versions of re2 now require a compiler with C++11 support
checking_for("re2 requires C++11 compiler") do
  minimal_program = <<SRC
#include <re2/re2.h>
int main() { return 0; }
SRC

  unless try_compile(minimal_program, compile_options)
    if try_compile(minimal_program, compile_options + " -std=c++11")
      compile_options << " -std=c++11"
      $CPPFLAGS << " -std=c++11"
    elsif try_compile(minimal_program, compile_options + " -std=c++0x")
      compile_options << " -std=c++0x"
      $CPPFLAGS << " -std=c++0x"
    else
      abort "Cannot compile re2 with your compiler: recent versions require C++11 support."
    end
  end
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

static_p = enable_config('static', false)
message "Static linking is #{static_p ? 'enabled' : 'disabled'}.\n"

if static_p
  append_cppflags('-fPIC')

  $libs = $libs.shellsplit.map do |arg|
    case arg
    when '-lre2'
      resolve_static_library(arg)
    else
      arg
    end
  end.shelljoin
end

create_makefile("re2")
