# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010-2012, Paul Mucur (http://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'

PACKAGE_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

REQUIRED_MINI_PORTILE_VERSION = "~> 2.8.2" # keep this version in sync with the one in the gemspec

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

def find_compiler(compilers)
  compilers.find { |binary| find_executable(binary) }
end

# configure automatically searches for the right compiler based on the
# `--host` parameter.  However, we don't have that feature with
# cmake. Search for the right compiler for the target architecture using
# some basic heruistics.
# See https://github.com/flavorjones/mini_portile/issues/128.
def find_c_and_cxx_compilers(host)
  c_compiler = ENV["CC"]
  cxx_compiler = ENV["CXX"]

  if darwin?
    c_compiler ||= 'clang'
    cxx_compiler ||='clang++'
  else
    c_compiler ||= 'gcc'
    cxx_compiler ||= 'g++'
  end

  c_platform_compiler = "#{host}-#{c_compiler}"
  cxx_platform_compiler = "#{host}-#{cxx_compiler}"
  c_compiler = find_compiler([c_platform_compiler, c_compiler])
  cxx_compiler = find_compiler([cxx_platform_compiler, cxx_compiler])

  [c_compiler, cxx_compiler]
end

def cmake_system_name
  if darwin?
    'Darwin'
  elsif windows?
    'Windows'
  elsif freebsd?
    'FreeBSD'
  else
    'Linux'
  end
end

def cmake_compile_flags(host)
  c_compiler, cxx_compiler = find_c_and_cxx_compilers(host)

  # needed to ensure cross-compilation with CMake targets the right CPU and compilers
  [
    "-DCMAKE_SYSTEM_PROCESSOR=#{RbConfig::CONFIG['target_cpu']}",
    "-DCMAKE_SYSTEM_NAME=#{cmake_system_name}",
    "-DCMAKE_C_COMPILER=#{c_compiler}",
    "-DCMAKE_CXX_COMPILER=#{cxx_compiler}"
  ]
end

# By default, mini_portile2 might add an unnecessary option:
# https://github.com/flavorjones/mini_portile/blob/5084a2aeab12076f534cf0cabc81a4d5f84b5c25/lib/mini_portile2/mini_portile_cmake.rb#L17
# See https://github.com/flavorjones/mini_portile/issues/127.
def delete_cmake_generator_option!(options)
  indices = []

  options.each_with_index do |element, index|
    if element == '-G' && index + 1 < options.length
      indices << index
      indices << index + 1
    end
  end

  indices.reverse_each { |index| options.delete_at(index) }
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

def build_extension
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

def process_recipe(name, version)
  require "rubygems"
  gem("mini_portile2", REQUIRED_MINI_PORTILE_VERSION) # gemspec is not respected at install time
  require "mini_portile2"
  message("Using mini_portile version #{MiniPortile::VERSION}\n")

  MiniPortileCMake.new(name, version).tap do |recipe|
    recipe.host = target_host
    recipe.target = File.join(PACKAGE_ROOT_DIR, "ports")

    recipe.configure_options += [
      # abseil needs a C++14 compiler
      '-DCMAKE_CXX_STANDARD=17',
      # needed for building the C extension shared library with -fPIC
      '-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
      # ensures pkg-config and installed libraries will be in lib, not lib64
      '-DCMAKE_INSTALL_LIBDIR=lib'
    ]
    recipe.configure_options += cmake_compile_flags(recipe.host)
    delete_cmake_generator_option!(recipe.configure_options)

    yield recipe

    checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"

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

      recipe.cook

      FileUtils.touch(checkpoint)
    end

    recipe.activate
  end
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

def build_with_vendored_libraries
  message "Building re2 using packaged libraries.\n"

  require 'yaml'
  dependencies = YAML.load_file(File.join(PACKAGE_ROOT_DIR, 'dependencies.yml'))

  abseil_recipe = process_recipe('abseil', dependencies['abseil']['version']) do |recipe|
    recipe.files = [{
      url: "https://github.com/abseil/abseil-cpp/archive/refs/tags/#{recipe.version}.tar.gz",
      sha256: dependencies['abseil']['sha256']
    }]
    recipe.configure_options += ['-DABSL_PROPAGATE_CXX_STD=ON']
  end

  re2_recipe = process_recipe('libre2', dependencies['libre2']['version']) do |recipe|
    recipe.files = [{
      url: "https://github.com/google/re2/releases/download/#{recipe.version}/re2-#{recipe.version}.tar.gz",
      sha256: dependencies['libre2']['sha256']
    }]
    recipe.configure_options += ["-DCMAKE_PREFIX_PATH=#{abseil_recipe.path}", '-DCMAKE_CXX_FLAGS=-DNDEBUG']
  end

  dir_config("re2", File.join(re2_recipe.path, 'include'), File.join(re2_recipe.path, 'lib'))
  dir_config("abseil", File.join(abseil_recipe.path, 'include'), File.join(abseil_recipe.path, 'lib'))

  pkg_config_paths = [
    "#{abseil_recipe.path}/lib/pkgconfig",
    "#{re2_recipe.path}/lib/pkgconfig"
  ].join(':')

  pkg_config_paths = "#{ENV['PKG_CONFIG_PATH']}:#{pkg_config_paths}" if ENV['PKG_CONFIG_PATH']

  ENV['PKG_CONFIG_PATH'] = pkg_config_paths
  pc_file = File.join(re2_recipe.path, 'lib', 'pkgconfig', 're2.pc')

  raise 'Please install the `pkg-config` utility!' unless find_executable('pkg-config')

  # See https://bugs.ruby-lang.org/issues/18490, broken in Ruby 3.1 but fixed in Ruby 3.2.
  flags = xpopen(['pkg-config', '--libs', '--static', pc_file], err: %i[child out], &:read)
  flags.split.each { |flag| append_ldflags(flag) } if $?.success?

  build_extension
end

if config_system_libraries?
  build_with_system_libraries
else
  build_with_vendored_libraries
end

create_makefile("re2")
