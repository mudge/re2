# Change Log
All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

Older versions are detailed as [GitHub
releases](https://github.com/mudge/re2/releases) for this project.

## [2.0.0] - 2023-09-13
### Added
- The gem now comes bundled with the underlying RE2 library and its dependency,
  Abseil. Installing the gem will compile those dependencies automatically. As
  this can take a while, precompiled native gems are available for Linux,
  Windows and macOS. (Thanks to Stan Hu for contributing this.)

### Changed
- By default, the gem will use its own bundled version of RE2 rather than
  looking for the library on the system. To opt back into that behaviour, pass
  `--enable-system-libraries` when installing. (Thanks to Stan Hu for
  contributing this.)

### Removed
- Due to the new dependency on MiniPortile2, the gem no longer supports Ruby
  versions older than 2.6.

## [2.0.0.beta2] - 2023-09-10
### Added
- Restored support for Ruby 2.6.

### Changed
- Upgraded the vendored version of RE2 to 2023-09-01.

### Fixed
- When using the Ruby platform gem (skipping the precompiled, native gems) and
  opting out of the vendored dependencies in favour of a system install of
  RE2 with `--enable-system-libraries`, the gem will now compile correctly
  against the library if it is installed in Ruby's `exec_prefix` directory.
  (Thanks to Stan Hu.)

## [2.0.0.beta1] - 2023-09-08
### Added
- The gem now comes bundled with the underlying RE2 library and its dependency,
  Abseil. Installing the gem will compile those dependencies automatically. As
  this can take a while, precompiled native gems are available for Linux,
  Windows and macOS. (Thanks to Stan Hu for contributing this.)

### Changed
- By default, the gem will use its own bundled version of RE2 rather than
  looking for the library on the system. To opt back into that behaviour, pass
  `--enable-system-libraries` when installing. (Thanks to Stan Hu for
  contributing this.)

### Removed
- Due to the new dependency on MiniPortile2, the gem no longer supports Ruby
  versions older than 2.7.

## [1.7.0] - 2023-07-04
### Added
- Added support for libre2.11 (thanks to Stan Hu for contributing this)

## [1.6.0] - 2022-10-22
### Added
- Added RE2::MatchData#deconstruct and RE2::MatchData#deconstruct_keys so they
  can be used with Ruby pattern matching

## [1.5.0] - 2022-10-16
### Added
- Added RE2::Set for simultaneously searching a collection of patterns

## [1.4.0] - 2021-03-29
### Fixed
- Fixed a crash when using RE2::Scanner#scan with an invalid regular expression
  (thanks to Sergio Medina for reporting this)
- Fixed RE2::Regexp#match raising a NoMemoryError instead of an ArgumentError
  when given a negative number of matches

## [1.3.0] - 2021-03-12
### Added
- Add Homebrew's prefix on Apple Silicon and /usr as fallback locations
  searched when looking for the underlying re2 library if not found in
  /usr/local

## [1.2.0] - 2020-04-18
### Changed
- Stop using the now-deprecated utf8 API and re-implement it in terms of the
  encoding API in order to support both existing and upcoming releases of re2

## [1.1.1] - 2017-07-24
### Fixed
- Ensure that any compilers passed via the CC and CXX environment variables are
  used throughout the compilation process including both the final Makefile and
  any preceding checks

## [1.1.0] - 2017-07-23
### Fixed
- Fixed RE2::Scanner not advancing when calling scan with an empty pattern or
  pattern with empty capturing groups (thanks to Stan Hu for reporting this)

### Added
- Added eof? to RE2::Scanner to detect when the input has been fully consumed by
  matches (used internally by the fixed scan)
- Added support for specifying the C and C++ compiler using the standard CC and
  CXX environment variables when installing the gem

## [1.0.0] - 2016-11-14
### Added
- Added support for versions of the underlying re2 library that require C++11
  compiler support

## [0.7.0] - 2015-01-25
### Added
- Added RE2::MatchData#begin and RE2::MatchData#end for finding the offset of
  matches in your searches

## [0.6.1] - 2014-10-25
### Fixed
- Fix crash when non-strings are passed to match

## [0.6.0] - 2014-02-01
### Added
- Added RE2::Regexp#scan which returns a new RE2::Scanner instance for
  incrementally scanning a string for matches

### Removed
- Methods that altered strings in place are gone: re2_sub! and re2_gsub!

### Changed
- RE2.Replace and RE2.GlobalReplace now return new strings rather than modifying
  their input

### Fixed
- In Ruby 1.9.2 and later, re2 will now set the correct encoding for strings

[2.0.0]: https://github.com/mudge/re2/releases/tag/v2.0.0
[2.0.0.beta2]: https://github.com/mudge/re2/releases/tag/v2.0.0.beta2
[2.0.0.beta1]: https://github.com/mudge/re2/releases/tag/v2.0.0.beta1
[1.7.0]: https://github.com/mudge/re2/releases/tag/v1.7.0
[1.6.0]: https://github.com/mudge/re2/releases/tag/v1.6.0
[1.5.0]: https://github.com/mudge/re2/releases/tag/v1.5.0
[1.4.0]: https://github.com/mudge/re2/releases/tag/v1.4.0
[1.3.0]: https://github.com/mudge/re2/releases/tag/v1.3.0
[1.2.0]: https://github.com/mudge/re2/releases/tag/v1.2.0
[1.1.1]: https://github.com/mudge/re2/releases/tag/v1.1.1
[1.1.0]: https://github.com/mudge/re2/releases/tag/v1.1.0
[1.0.0]: https://github.com/mudge/re2/releases/tag/v1.0.0
[0.7.0]: https://github.com/mudge/re2/releases/tag/v0.7.0
[0.6.0]: https://github.com/mudge/re2/releases/tag/v0.6.0
