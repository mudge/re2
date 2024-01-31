# Change Log
All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

Older versions are detailed as [GitHub
releases](https://github.com/mudge/re2/releases) for this project.

## [2.8.0] - 2024-01-31
### Changed
- Upgrade the bundled version of RE2 to 2024-02-01.
- Upgrade the bundled version of Abseil to 20240116.0.

## [2.7.0] - 2024-01-20
### Added
- Support strings with null bytes as patterns and input throughout the library.
  Note this means strings with null bytes will no longer be truncated at the
  first null byte. Thanks to @manueljacob for reporting this bug.

## [2.6.0] - 2023-12-27
### Added
- Add precompiled native gem for Ruby 3.3.0.

## [2.6.0.rc1] - 2023-12-13
### Added
- Add precompiled native gem for Ruby 3.3.0-rc1.

## [2.5.0] - 2023-12-05
### Added
- Add a new matching interface that more closely resembles the underlying RE2
  library's: `RE2::Regexp#full_match?`, `RE2::Regexp#partial_match?` for
  matching without extracting submatches and `RE2::Regexp#full_match` and
  `RE2::Regexp#partial_match` for extracting submatches. The latter two are
  built on the existing `RE2::Regexp#match` method which now exposes more of
  RE2's general matching interface by accepting new `anchor`, `startpos` and
  `endpos` (where supported) arguments.

### Changed
- Overhaul much of the documentation to better explain the library and more
  closely match the underlying RE2 library's interface, primarily promoting
  the new full and partial matching APIs.
- Remove workarounds for building Abseil on Windows now that pkgconf 2.1.0 has
  been released.

## [2.4.3] - 2023-11-22
### Fixed
- Restore support for compiling the gem with gcc 7.3 (as used on Amazon Linux
  2), fixing the "non-trivial designated initializers not supported" error
  introduced in version 2.4.0. Thanks to @stanhu for reporting this bug.

## [2.4.2] - 2023-11-17
### Changed
- Improve the reported consuming memory size of RE2::Regexp, RE2::Set and
  RE2::Scanner objects.

## [2.4.1] - 2023-11-12
### Changed
- Improve the reported consuming memory size of RE2::MatchData objects. Thanks
  to @byroot again for suggesting a better way to calculate this.

## [2.4.0] - 2023-11-11
### Added
- Improve garbage collection and support compaction in newer versions of Ruby.
  Thanks to @byroot for contributing this by switching to Ruby's TypedData API.

### Changed
- No longer needlessly return copies of frozen strings passed to
  `RE2::Regexp#match` and return the original instead.

## [2.3.0] - 2023-10-31
### Changed
- Upgrade the bundled version of RE2 to 2023-11-01.

## [2.2.0] - 2023-10-23
### Changed
- Upgrade the bundled version of Abseil to 20230802.1.
- Upgrade MiniPortile to 2.8.5 which significantly reduces the size of the
  precompiled native gems due to its switch to build Abseil in Release mode.

## [2.1.3] - 2023-09-23
### Fixed
- Fixed memory leaks reported by
  [ruby_memcheck](https://github.com/Shopify/ruby_memcheck) when rewinding an
  `RE2::Scanner` and when passing invalid input to `RE2::Regexp#scan`,
  `RE2::Regexp#initialize`, `RE2.Replace`, `RE2.GlobalReplace` and
  `RE2::Set#add`. Thanks to @peterzhu2118 for maintaining ruby_memcheck and
  their assistance in finding the source of these leaks.

## [2.1.2] - 2023-09-20
### Fixed
- Removed use of a C++17 extension from the gem to restore support for users
  compiling against system libraries with older C compilers.

## [2.1.1] - 2023-09-18
### Fixed
- Worked around a deprecation warning re the use of ANYARGS when compiling
  against recent Ruby versions.

### Changed
- Various internal C++ style improvements to reduce unnecessary memory usage
  when accessing named capturing groups.

## [2.1.0] - 2023-09-16
### Fixed
- As RE2 only supports UTF-8 and ISO-8859-1 encodings, fix an inconsistency
  when using string patterns with `RE2.Replace` and `RE2.GlobalReplace` where
  the result would match the encoding of the pattern rather than UTF-8 which is
  what RE2 will use. This behaviour and limitation is now documented on all
  APIs that produce string results.

### Added
- The `RE2::Set` API now accepts anything that can be coerced to a string where
  previously only strings were permitted, e.g. `RE2::Set#add`,
  `RE2::Set#match`.
- Added the licences of all vendored dependencies: RE2 and Abseil.
- Document the behaviour of `RE2::Regexp#match` when given a pattern with no
  capturing groups: it will return true or false whether there was a match or
  not rather than a `RE2::MatchData` instance.

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

[2.8.0]: https://github.com/mudge/re2/releases/tag/v2.8.0
[2.7.0]: https://github.com/mudge/re2/releases/tag/v2.7.0
[2.6.0]: https://github.com/mudge/re2/releases/tag/v2.6.0
[2.6.0.rc1]: https://github.com/mudge/re2/releases/tag/v2.6.0.rc1
[2.5.0]: https://github.com/mudge/re2/releases/tag/v2.5.0
[2.4.3]: https://github.com/mudge/re2/releases/tag/v2.4.3
[2.4.2]: https://github.com/mudge/re2/releases/tag/v2.4.2
[2.4.1]: https://github.com/mudge/re2/releases/tag/v2.4.1
[2.4.0]: https://github.com/mudge/re2/releases/tag/v2.4.0
[2.3.0]: https://github.com/mudge/re2/releases/tag/v2.3.0
[2.2.0]: https://github.com/mudge/re2/releases/tag/v2.2.0
[2.1.3]: https://github.com/mudge/re2/releases/tag/v2.1.3
[2.1.2]: https://github.com/mudge/re2/releases/tag/v2.1.2
[2.1.1]: https://github.com/mudge/re2/releases/tag/v2.1.1
[2.1.0]: https://github.com/mudge/re2/releases/tag/v2.1.0
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
