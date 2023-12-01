# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'
require_relative 'recipes'

RE2_HELP_MESSAGE = <<~HELP
  USAGE: ruby #{$0} [options]

    Flags that are always valid:

      --enable-system-libraries
          Use system libraries instead of building and using the packaged libraries.

      --disable-system-libraries
          Use the packaged libraries, and ignore the system libraries. This is the default.


    Flags only used when using system libraries:

      Related to re2 library:

        --with-re2-dir=DIRECTORY
            Look for re2 headers and library in DIRECTORY.


    Flags only used when building and using the packaged libraries:

      --enable-cross-build
          Enable cross-build mode. (You probably do not want to set this manually.)


    Environment variables used:

      CC
          Use this path to invoke the compiler instead of `RbConfig::CONFIG['CC']`

      CPPFLAGS
          If this string is accepted by the C preprocessor, add it to the flags passed to the C preprocessor

      CFLAGS
          If this string is accepted by the compiler, add it to the flags passed to the compiler

      LDFLAGS
          If this string is accepted by the linker, add it to the flags passed to the linker

      LIBS
          Add this string to the flags passed to the linker
HELP

#
#  utility functions
#
def config_system_libraries?
  enable_config("system-libraries", ENV.key?('RE2_USE_SYSTEM_LIBRARIES'))
end

def config_cross_build?
  enable_config("cross-build")
end

def concat_flags(*args)
  args.compact.join(" ")
end

def do_help
  print(RE2_HELP_MESSAGE)
  exit!(0)
end

def darwin?
  RbConfig::CONFIG["target_os"].include?("darwin")
end

def windows?
  RbConfig::CONFIG["target_os"].match?(/mingw|mswin/)
end

def freebsd?
  RbConfig::CONFIG["target_os"].include?("freebsd")
end

def target_host
  # We use 'host' to set compiler prefix for cross-compiling. Prefer host_alias over host. And
  # prefer i686 (what external dev tools use) to i386 (what ruby's configure.ac emits).
  host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
  host.gsub(/i386/, "i686")
end

def target_arch
  RbConfig::CONFIG['arch']
end

def with_temp_dir
  Dir.mktmpdir do |temp_dir|
    Dir.chdir(temp_dir) do
      yield
    end
  end
end

#
#  main
#
do_help if arg_config('--help')

if ENV["CC"]
  RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"]
  RbConfig::CONFIG["CC"] = ENV["CC"]
end

if ENV["CXX"]
  RbConfig::MAKEFILE_CONFIG["CXX"] = ENV["CXX"]
  RbConfig::CONFIG["CXX"] = ENV["CXX"]
end

def build_extension(static_p = false)
  # Enable optional warnings but disable deprecated register warning for Ruby 2.6 support
  $CFLAGS << " -Wall -Wextra -funroll-loops"
  $CPPFLAGS << " -Wno-register"

  # Pass -x c++ to force gcc to compile the test program
  # as C++ (as it will end in .c by default).
  compile_options = "-x c++"

  have_library("stdc++")
  have_header("stdint.h")
  have_func("rb_gc_mark_movable") # introduced in Ruby 2.7

  if !static_p and !have_library("re2")
    abort "You must have re2 installed and specified with --with-re2-dir, please see https://github.com/google/re2/wiki/Install"
  end

  minimal_program = <<SRC
#include <re2/re2.h>
int main() { return 0; }
SRC

  re2_requires_version_flag = checking_for("re2 that requires explicit C++ version flag") do
    !try_compile(minimal_program, compile_options)
  end

  if re2_requires_version_flag
    # Recent versions of re2 depend directly on abseil, which requires a
    # compiler with C++14 support (see
    # https://github.com/abseil/abseil-cpp/issues/1127 and
    # https://github.com/abseil/abseil-cpp/issues/1431). However, the
    # `std=c++14` flag doesn't appear to suffice; we need at least
    # `std=c++17`.
    abort "Cannot compile re2 with your compiler: recent versions require C++14 support." unless %w[c++20 c++17 c++11 c++0x].any? do |std|
      checking_for("re2 that compiles with #{std} standard") do
        if try_compile(minimal_program, compile_options + " -std=#{std}")
          compile_options << " -std=#{std}"
          $CPPFLAGS << " -std=#{std}"

          true
        end
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
end

def process_recipe(recipe)
  cross_build_p = config_cross_build?
  message "Cross build is #{cross_build_p ? "enabled" : "disabled"}.\n"

  recipe.host = target_host
  # Ensure x64-mingw-ucrt and x64-mingw32 use different library paths since the host
  # is the same (x86_64-w64-mingw32).
  recipe.target = File.join(recipe.target, target_arch) if cross_build_p

  yield recipe

  checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"
  name = recipe.name
  version = recipe.version

  if File.exist?(checkpoint)
    message("Building re2 with a packaged version of #{name}-#{version}.\n")
  else
    message(<<~EOM)
        ---------- IMPORTANT NOTICE ----------
        Building re2 with a packaged version of #{name}-#{version}.
        Configuration options: #{recipe.configure_options.shelljoin}
      EOM

    unless recipe.patch_files.empty?
      message("The following patches are being applied:\n")

      recipe.patch_files.each do |patch|
        message("  - %s\n" % File.basename(patch))
      end
    end

    # Use a temporary base directory to reduce filename lengths since
    # Windows can hit a limit of 250 characters (CMAKE_OBJECT_PATH_MAX).
    with_temp_dir { recipe.cook }

    FileUtils.touch(checkpoint)
  end

  recipe.activate
end

def build_with_system_libraries
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

  build_extension
end

def libflag_to_filename(ldflag)
  case ldflag
  when /\A-l(.+)/
    "lib#{Regexp.last_match(1)}.#{$LIBEXT}"
  end
end

# This method does a number of things to ensure the final shared library
# is compiled statically with the vendored libraries:
#
# 1. For -L<path> flags, ensure that any `ports` paths are prioritized just
#    in case there are installed libraries that might take precedence.
# 2. For -l<lib> flags, convert the library to the static library with a
#    full path and substitute the absolute static library.  For example,
#    -lre2 maps to /path/to/ports/<arch>/libre2/<version>/lib/libre2.a.
#
# This is needed because when building the extension, Ruby appears to
# insert `-L#{RbConfig::CONFIG['exec_prefix']}/lib` first. If libre2 is
# in installed in that location then the extension will link against the
# system library instead of the vendored library.
def add_flag(arg, lib_paths)
  case arg
  when /\A-L(.+)\z/
    # Prioritize ports' directories
    lib_dir = Regexp.last_match(1)
    $LIBPATH =
      if lib_dir.start_with?(PACKAGE_ROOT_DIR + "/")
        [lib_dir] | $LIBPATH
      else
        $LIBPATH | [lib_dir]
      end
  when /\A-l./
    filename = libflag_to_filename(arg)

    added = false
    lib_paths.each do |path|
      static_lib = File.join(path, filename)

      next unless File.exist?(static_lib)

      $LDFLAGS << " " << static_lib
      added = true
      break
    end

    append_ldflags(arg.shellescape) unless added
  else
    append_ldflags(arg.shellescape)
  end
end

def add_static_ldflags(flags, lib_paths)
  flags.strip.shellsplit.each { |flag| add_flag(flag, lib_paths) }
end

def build_with_vendored_libraries
  message "Building re2 using packaged libraries.\n"

  abseil_recipe, re2_recipe = load_recipes

  process_recipe(abseil_recipe) do |recipe|
    recipe.configure_options += ['-DABSL_PROPAGATE_CXX_STD=ON', '-DCMAKE_CXX_VISIBILITY_PRESET=hidden']
    # Workaround for https://github.com/abseil/abseil-cpp/issues/1510
    recipe.configure_options += ['-DCMAKE_CXX_FLAGS=-DABSL_FORCE_WAITER_MODE=4'] if windows?
  end

  process_recipe(re2_recipe) do |recipe|
    recipe.configure_options += ["-DCMAKE_PREFIX_PATH=#{abseil_recipe.path}", '-DCMAKE_CXX_FLAGS=-DNDEBUG',
                                 '-DCMAKE_CXX_VISIBILITY_PRESET=hidden']
  end

  dir_config("re2", File.join(re2_recipe.path, 'include'), File.join(re2_recipe.path, 'lib'))
  dir_config("abseil", File.join(abseil_recipe.path, 'include'), File.join(abseil_recipe.path, 'lib'))

  pkg_config_paths = [
    "#{abseil_recipe.path}/lib/pkgconfig",
    "#{re2_recipe.path}/lib/pkgconfig"
  ].join(File::PATH_SEPARATOR)

  pkg_config_paths = "#{ENV['PKG_CONFIG_PATH']}#{File::PATH_SEPARATOR}#{pkg_config_paths}" if ENV['PKG_CONFIG_PATH']

  ENV['PKG_CONFIG_PATH'] = pkg_config_paths
  pc_file = File.join(re2_recipe.path, 'lib', 'pkgconfig', 're2.pc')

  raise 'Please install the `pkg-config` utility!' unless find_executable('pkg-config')

  # See https://bugs.ruby-lang.org/issues/18490, broken in Ruby 3.1 but fixed in Ruby 3.2.
  flags = xpopen(['pkg-config', '--libs', '--static', pc_file], err: %i[child out], &:read)

  raise 'Unable to run pkg-config --libs --static' unless $?.success?

  lib_paths = [File.join(abseil_recipe.path, 'lib'), File.join(re2_recipe.path, 'lib')]
  add_static_ldflags(flags, lib_paths)
  build_extension(true)
end

if config_system_libraries?
  build_with_system_libraries
else
  build_with_vendored_libraries
end

create_makefile("re2")
