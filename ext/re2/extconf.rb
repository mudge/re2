# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

require 'mkmf'
require_relative 'recipes'

module RE2
  class Extconf
    def configure
      configure_cross_compiler

      if config_system_libraries?
        build_with_system_libraries
      else
        build_with_vendored_libraries
      end

      build_extension

      create_makefile("re2")
    end

    def print_help
      print(<<~TEXT)
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
      TEXT
    end

    private

    def configure_cross_compiler
      RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"] if ENV["CC"]
      RbConfig::CONFIG["CXX"] = RbConfig::MAKEFILE_CONFIG["CXX"] = ENV["CXX"] if ENV["CXX"]
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

      unless have_library("re2")
        abort "You must have re2 installed and specified with --with-re2-dir, please see https://github.com/google/re2/wiki/Install"
      end
    end

    def build_with_vendored_libraries
      message "Building re2 using packaged libraries.\n"

      abseil_recipe, re2_recipe = load_recipes

      process_recipe(abseil_recipe) do |recipe|
        recipe.configure_options << '-DABSL_PROPAGATE_CXX_STD=ON'
        # Workaround for https://github.com/abseil/abseil-cpp/issues/1510
        recipe.configure_options << '-DCMAKE_CXX_FLAGS=-DABSL_FORCE_WAITER_MODE=4' if MiniPortile.windows?
      end

      process_recipe(re2_recipe) do |recipe|
        recipe.configure_options += [
          # Specify Abseil's path so RE2 will prefer that over any system Abseil
          "-DCMAKE_PREFIX_PATH=#{abseil_recipe.path}",
          '-DCMAKE_CXX_FLAGS=-DNDEBUG'
        ]
      end

      pc_file = File.join(re2_recipe.lib_path, 'pkgconfig', 're2.pc')
      pkg_config_paths = [
        File.join(abseil_recipe.lib_path, 'pkgconfig'),
        File.join(re2_recipe.lib_path, 'pkgconfig')
      ]

      static_pkg_config(pc_file, pkg_config_paths)
    end

    def build_extension
      # Enable optional warnings but disable deprecated register warning for Ruby 2.6 support
      $CFLAGS << " -Wall -Wextra -funroll-loops"
      $CXXFLAGS << " -Wall -Wextra -funroll-loops"
      $CPPFLAGS << " -Wno-register"

      # Pass -x c++ to force gcc to compile the test program
      # as C++ (as it will end in .c by default).
      compile_options = +"-x c++"

      have_library("stdc++")
      have_header("stdint.h")
      have_func("rb_gc_mark_movable") # introduced in Ruby 2.7

      minimal_program = <<~SRC
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
        test_re2_match_signature = <<~SRC
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
        test_re2_set_match_signature = <<~SRC
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

      checking_for("RE2::Set::Size()") do
        test_re2_set_size = <<~SRC
          #include <re2/re2.h>
          #include <re2/set.h>

          int main() {
            RE2::Set s(RE2::DefaultOptions, RE2::UNANCHORED);
            s.Size();

            return 0;
          }
        SRC

        if try_compile(test_re2_set_size, compile_options)
          $defs.push("-DHAVE_SET_SIZE")
        end
      end
    end

    def static_pkg_config(pc_file, pkg_config_paths)
      ENV["PKG_CONFIG_PATH"] = [*pkg_config_paths, ENV["PKG_CONFIG_PATH"]].compact.join(File::PATH_SEPARATOR)

      static_library_paths = minimal_pkg_config(pc_file, '--libs-only-L', '--static')
        .shellsplit
        .map { |flag| flag.delete_prefix('-L') }

      # Replace all -l flags that can be found in one of the static library
      # paths with the absolute path instead.
      minimal_pkg_config(pc_file, '--libs-only-l', '--static')
        .shellsplit
        .each do |flag|
          lib = "lib#{flag.delete_prefix('-l')}.#{$LIBEXT}"

          if (static_lib_path = static_library_paths.find { |path| File.exist?(File.join(path, lib)) })
            $libs << ' ' << File.join(static_lib_path, lib).shellescape
          else
            $libs << ' ' << flag.shellescape
          end
        end

      append_ldflags(minimal_pkg_config(pc_file, '--libs-only-other', '--static'))

      incflags = minimal_pkg_config(pc_file, '--cflags-only-I')
      $INCFLAGS = [incflags, $INCFLAGS].join(" ").strip

      cflags = minimal_pkg_config(pc_file, '--cflags-only-other')
      $CFLAGS = [$CFLAGS, cflags].join(" ").strip
      $CXXFLAGS = [$CXXFLAGS, cflags].join(" ").strip
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

        # Use a temporary base directory to reduce filename lengths since
        # Windows can hit a limit of 250 characters (CMAKE_OBJECT_PATH_MAX).
        Dir.mktmpdir { |dir| Dir.chdir(dir) { recipe.cook } }

        FileUtils.touch(checkpoint)
      end
    end

    # See MiniPortile2's minimal_pkg_config:
    # https://github.com/flavorjones/mini_portile/blob/52fb0bc41c89a10f1ac7b5abcf0157e059194374/lib/mini_portile2/mini_portile.rb#L760-L783
    # and Ruby's pkg_config:
    # https://github.com/ruby/ruby/blob/c505bb0ca0fd61c7ae931d26451f11122a2644e9/lib/mkmf.rb#L1916-L2004
    def minimal_pkg_config(pc_file, *options)
      if ($PKGCONFIG ||=
          (pkgconfig = MakeMakefile.with_config("pkg-config") {MakeMakefile.config_string("PKG_CONFIG") || "pkg-config"}) &&
          MakeMakefile.find_executable0(pkgconfig) && pkgconfig)
        pkgconfig = $PKGCONFIG
      else
        raise RuntimeError, "pkg-config is not found"
      end

      response = xpopen([pkgconfig, *options, pc_file], err: %i[child out], &:read)
      raise RuntimeError, response unless $?.success?

      response.strip
    end

    def config_system_libraries?
      enable_config("system-libraries", ENV.key?('RE2_USE_SYSTEM_LIBRARIES'))
    end

    def config_cross_build?
      enable_config("cross-build")
    end

    # We use 'host' to set compiler prefix for cross-compiling. Prefer host_alias over host. And
    # prefer i686 (what external dev tools use) to i386 (what ruby's configure.ac emits).
    def target_host
      host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
      host.gsub(/i386/, "i686")
    end

    def target_arch
      RbConfig::CONFIG['arch']
    end
  end
end

extconf = RE2::Extconf.new

if arg_config('--help')
  extconf.print_help
  exit!(true)
end

extconf.configure
