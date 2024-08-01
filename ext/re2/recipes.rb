# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt

PACKAGE_ROOT_DIR = File.expand_path('../..', __dir__)
REQUIRED_MINI_PORTILE_VERSION = '~> 2.8.7' # keep this version in sync with the one in the gemspec

def load_recipes
  require 'yaml'
  dependencies = YAML.load_file(File.join(PACKAGE_ROOT_DIR, 'dependencies.yml'))

  abseil_recipe = build_recipe('abseil', dependencies['abseil']['version']) do |recipe|
    recipe.files = [{
      url: "https://github.com/abseil/abseil-cpp/archive/refs/tags/#{recipe.version}.tar.gz",
      sha256: dependencies['abseil']['sha256']
    }]
  end

  re2_recipe = build_recipe('libre2', dependencies['libre2']['version']) do |recipe|
    recipe.files = [{
      url: "https://github.com/google/re2/releases/download/#{recipe.version}/re2-#{recipe.version}.tar.gz",
      sha256: dependencies['libre2']['sha256']
    }]
  end

  [abseil_recipe, re2_recipe]
end

def build_recipe(name, version)
  require 'rubygems'
  gem('mini_portile2', REQUIRED_MINI_PORTILE_VERSION) # gemspec is not respected at install time
  require 'mini_portile2'

  MiniPortileCMake.new(name, version).tap do |recipe|
    recipe.target = File.join(PACKAGE_ROOT_DIR, 'ports')
    recipe.configure_options += [
      # abseil needs a C++14 compiler
      '-DCMAKE_CXX_STANDARD=14',
      # needed for building the C extension shared library with -fPIC
      '-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
      # ensures pkg-config and installed libraries will be in lib, not lib64
      '-DCMAKE_INSTALL_LIBDIR=lib',
      '-DCMAKE_CXX_VISIBILITY_PRESET=hidden'
    ]

    yield recipe
  end
end
