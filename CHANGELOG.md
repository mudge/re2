# Change Log
All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

Older versions are detailed as [GitHub
releases](https://github.com/mudge/re2/releases) for this project.

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

[1.1.0]: https://github.com/mudge/re2/releases/tag/v1.1.0
[1.0.0]: https://github.com/mudge/re2/releases/tag/v1.0.0
[0.7.0]: https://github.com/mudge/re2/releases/tag/v0.7.0
[0.6.0]: https://github.com/mudge/re2/releases/tag/v0.6.0
