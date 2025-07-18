# re2 - safer regular expressions in Ruby

Ruby bindings to [RE2][], a "fast, safe, thread-friendly alternative to
backtracking regular expression engines like those used in PCRE, Perl, and
Python".

[![Build Status](https://github.com/mudge/re2/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/mudge/re2/actions)

**Current version:** 2.17.0  
**Bundled RE2 version:** libre2.11 (2025-07-17)  

```ruby
RE2('h.*o').full_match?("hello")    #=> true
RE2('e').full_match?("hello")       #=> false
RE2('h.*o').partial_match?("hello") #=> true
RE2('e').partial_match?("hello")    #=> true
RE2('(\w+):(\d+)').full_match("ruby:1234")
#=> #<RE2::MatchData "ruby:1234" 1:"ruby" 2:"1234">
```

## Table of Contents

* [Why RE2?](#why-re2)
* [Usage](#usage)
    * [Compiling regular expressions](#compiling-regular-expressions)
    * [Matching interface](#matching-interface)
    * [Submatch extraction](#submatch-extraction)
    * [Scanning text incrementally](#scanning-text-incrementally)
    * [Searching simultaneously](#searching-simultaneously)
    * [Encoding](#encoding)
* [Requirements](#requirements)
    * [Native gems](#native-gems)
    * [Verifying the gems](#verifying-the-gems)
    * [Installing the `ruby` platform gem](#installing-the-ruby-platform-gem)
    * [Using system libraries](#using-system-libraries)
* [Thanks](#thanks)
* [Contact](#contact)
* [License](#license)
    * [Dependencies](#dependencies)

## Why RE2?

While [recent
versions](https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/) of
Ruby have improved defences against [regular expression denial of service
(ReDoS) attacks](https://en.wikipedia.org/wiki/ReDoS), it is still possible for
users to craft malicious patterns that take a long time to process by using
syntactic features such as [back-references, lookaheads and possessive
quantifiers](https://bugs.ruby-lang.org/issues/19104#note-3). RE2 aims to
eliminate ReDoS by design:

> **_Safety is RE2's raison d'être._**
>
> RE2 was designed and implemented with an explicit goal of being able to
> handle regular expressions from untrusted users without risk. One of its
> primary guarantees is that the match time is linear in the length of the
> input string. It was also written with production concerns in mind: the
> parser, the compiler and the execution engines limit their memory usage by
> working within a configurable budget – failing gracefully when exhausted –
> and they avoid stack overflow by eschewing recursion.

— [Why RE2?](https://github.com/google/re2/wiki/WhyRE2)

## Usage

Install re2 as a dependency:

```ruby
# In your Gemfile
gem "re2"

# Or without Bundler
gem install re2
```

Include in your code:

```ruby
require "re2"
```

Full API documentation automatically generated from the latest version is
available at https://mudge.name/re2/.

While re2 uses the same naming scheme as Ruby's built-in regular expression
library (with [`Regexp`](https://mudge.name/re2/RE2/Regexp.html) and
[`MatchData`](https://mudge.name/re2/RE2/MatchData.html)), its API is slightly
different:

### Compiling regular expressions

> [!WARNING]
> RE2's regular expression syntax differs from PCRE and Ruby's built-in
> [`Regexp`](https://docs.ruby-lang.org/en/3.2/Regexp.html) library, see the
> [official syntax page](https://github.com/google/re2/wiki/Syntax) for more
> details.

The core class is [`RE2::Regexp`](https://mudge.name/re2/RE2/Regexp.html) which
takes a regular expression as a string and compiles it internally into an `RE2`
object. A global function `RE2` is available to concisely compile a new
`RE2::Regexp`:

```ruby
re = RE2('(\w+):(\d+)')
#=> #<RE2::Regexp /(\w+):(\d+)/>
re.ok? #=> true

re = RE2('abc)def')
re.ok?   #=> false
re.error #=> "missing ): abc(def"
```

> [!TIP]
> Note the use of *single quotes* when passing the regular expression as
> a string to `RE2` so that the backslashes aren't interpreted as escapes.

When compiling a regular expression, an optional second argument can be used to change RE2's default options, e.g. stop logging syntax and execution errors to stderr with `log_errors`:

```ruby
RE2('abc)def', log_errors: false)
```

See the API documentation for [`RE2::Regexp#initialize`](https://mudge.name/re2/RE2/Regexp.html#initialize-instance_method) for all the available options.

### Matching interface

There are two main methods for matching: [`RE2::Regexp#full_match?`](https://mudge.name/re2/RE2/Regexp.html#full_match%3F-instance_method) requires the regular expression to match the entire input text, and [`RE2::Regexp#partial_match?`](https://mudge.name/re2/RE2/Regexp.html#partial_match%3F-instance_method) looks for a match for a substring of the input text, returning a boolean to indicate whether a match was successful or not.

```ruby
RE2('h.*o').full_match?("hello")    #=> true
RE2('e').full_match?("hello")       #=> false

RE2('h.*o').partial_match?("hello") #=> true
RE2('e').partial_match?("hello")    #=> true
```

### Submatch extraction

> [!TIP]
> Only extract the number of submatches you need as performance is improved
> with fewer submatches (with the best performance when avoiding submatch
> extraction altogether).

Both matching methods have a second form that can extract submatches as [`RE2::MatchData`](https://mudge.name/re2/RE2/MatchData.html) objects: [`RE2::Regexp#full_match`](https://mudge.name/re2/RE2/Regexp.html#full_match-instance_method) and [`RE2::Regexp#partial_match`](https://mudge.name/re2/RE2/Regexp.html#partial_match-instance_method).

```ruby
m = RE2('(\w+):(\d+)').full_match("ruby:1234")
#=> #<RE2::MatchData "ruby:1234" 1:"ruby" 2:"1234">

m[0] #=> "ruby:1234"
m[1] #=> "ruby"
m[2] #=> "1234"

m = RE2('(\w+):(\d+)').full_match("r")
#=> nil
```

`RE2::MatchData` supports retrieving submatches by numeric index or by name if present in the regular expression:

```ruby
m = RE2('(?P<word>\w+):(?P<number>\d+)').full_match("ruby:1234")
#=> #<RE2::MatchData "ruby:1234" 1:"ruby" 2:"1234">

m["word"]   #=> "ruby"
m["number"] #=> "1234"
```

They can also be used with Ruby's [pattern matching](https://docs.ruby-lang.org/en/3.2/syntax/pattern_matching_rdoc.html):

```ruby
case RE2('(\w+):(\d+)').full_match("ruby:1234")
in [word, number]
  puts "Word: #{word}, Number: #{number}"
else
  puts "No match"
end
# Word: ruby, Number: 1234

case RE2('(?P<word>\w+):(?P<number>\d+)').full_match("ruby:1234")
in word:, number:
  puts "Word: #{word}, Number: #{number}"
else
  puts "No match"
end
# Word: ruby, Number: 1234
```

By default, both `full_match` and `partial_match` will extract all submatches into the `RE2::MatchData` based on the number of capturing groups in the regular expression. This can be changed by passing an optional second argument when matching:

```ruby
m = RE2('(\w+):(\d+)').full_match("ruby:1234", submatches: 1)
=> #<RE2::MatchData "ruby:1234" 1:"ruby">
```

> [!WARNING]
> If the regular expression has no capturing groups or you pass `submatches:
> 0`, the matching method will behave like its `full_match?` or
> `partial_match?` form and only return `true` or `false` rather than
> `RE2::MatchData`.

### Scanning text incrementally

If you want to repeatedly match regular expressions from the start of some input text, you can use [`RE2::Regexp#scan`](https://mudge.name/re2/RE2/Regexp.html#scan-instance_method) to return an `Enumerable` [`RE2::Scanner`](https://mudge.name/re2/RE2/Scanner.html) object which will lazily consume matches as you iterate over it:

```ruby
scanner = RE2('(\w+)').scan(" one two three 4")
scanner.each do |match|
  puts match.inspect
end
# ["one"]
# ["two"]
# ["three"]
# ["4"]
```

### Searching simultaneously

[`RE2::Set`](https://mudge.name/re2/RE2/Set.html) represents a collection of
regular expressions that can be searched for simultaneously. Calling
[`RE2::Set#add`](https://mudge.name/re2/RE2/Set.html#add-instance_method) with
a regular expression will return the integer index at which it is stored within
the set. After all patterns have been added, the set can be compiled using
[`RE2::Set#compile`](https://mudge.name/re2/RE2/Set.html#compile-instance_method),
and then
[`RE2::Set#match`](https://mudge.name/re2/RE2/Set.html#match-instance_method)
will return an array containing the indices of all the patterns that matched.
[`RE2::Set#size`](https://mudge.name/re2/RE2/Set.html#size-instance_method)
will return the number of patterns in the set.

```ruby
set = RE2::Set.new
set.add("abc")         #=> 0
set.add("def")         #=> 1
set.add("ghi")         #=> 2
set.size               #=> 3
set.compile            #=> true
set.match("abcdefghi") #=> [0, 1, 2]
set.match("ghidefabc") #=> [2, 1, 0]
```

### Encoding

> [!WARNING]
> Note RE2 only supports UTF-8 and ISO-8859-1 encoding so strings will be
> returned in UTF-8 by default or ISO-8859-1 if the `:utf8` option for the
> `RE2::Regexp` is set to `false` (any other encoding's behaviour is undefined).

For backward compatibility: re2 won't automatically convert string inputs to
the right encoding so this is the responsibility of the caller, e.g.

```ruby
# By default, RE2 will process patterns and text as UTF-8
RE2(non_utf8_pattern.encode("UTF-8")).match(non_utf8_text.encode("UTF-8"))

# If the :utf8 option is false, RE2 will process patterns and text as ISO-8859-1
RE2(non_latin1_pattern.encode("ISO-8859-1"), utf8: false).match(non_latin1_text.encode("ISO-8859-1"))
```

## Requirements

This gem requires the following to run:

* [Ruby](https://www.ruby-lang.org/en/) 2.6 to 3.4

It supports the following RE2 ABI versions:

* libre2.0 (prior to release 2020-03-02) to libre2.11 (2023-07-01 to 2025-07-17)

### Native gems

Where possible, a pre-compiled native gem will be provided for the following platforms:

* Linux
    * `aarch64-linux`, `arm-linux`, `x86-linux` and `x86_64-linux` (requires [glibc](https://www.gnu.org/software/libc/) 2.29+, RubyGems 3.3.22+ and Bundler 2.3.21+)
    * [musl](https://musl.libc.org/)-based systems such as [Alpine](https://alpinelinux.org) are supported with Bundler 2.5.6+
* macOS `x86_64-darwin` and `arm64-darwin`
* Windows `x64-mingw32` and `x64-mingw-ucrt`

### Verifying the gems

SHA256 checksums are included in the [release notes](https://github.com/mudge/re2/releases) for each version and can be checked with `sha256sum`, e.g.

```console
$ gem fetch re2 -v 2.14.0
Fetching re2-2.14.0-arm64-darwin.gem
Downloaded re2-2.14.0-arm64-darwin
$ sha256sum re2-2.14.0-arm64-darwin.gem
3c922d54a44ac88499f6391bc2f9740559381deaf7f4e49eef5634cf32efc2ce  re2-2.14.0-arm64-darwin.gem
```

[GPG](https://www.gnupg.org/) signatures are attached to each release (the assets ending in `.sig`) and can be verified if you import [our signing key `0x39AC3530070E0F75`](https://mudge.name/39AC3530070E0F75.asc) (or fetch it from a public keyserver, e.g. `gpg --keyserver keyserver.ubuntu.com --recv-key 0x39AC3530070E0F75`):

```console
$ gpg --verify re2-2.14.0-arm64-darwin.gem.sig re2-2.14.0-arm64-darwin.gem
gpg: Signature made Fri  2 Aug 12:39:12 2024 BST
gpg:                using RSA key 702609D9C790F45B577D7BEC39AC3530070E0F75
gpg: Good signature from "Paul Mucur <mudge@mudge.name>" [unknown]
gpg:                 aka "Paul Mucur <paul@ghostcassette.com>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 7026 09D9 C790 F45B 577D  7BEC 39AC 3530 070E 0F75
```

The fingerprint should be as shown above or you can independently verify it with the ones shown in the footer of https://mudge.name.

### Installing the `ruby` platform gem

> [!WARNING]
> We strongly recommend using the native gems where possible to avoid the need
> for compiling the C++ extension and its dependencies which will take longer
> and be less reliable.

If you wish to compile the gem, you will need to explicitly install the `ruby` platform gem:

```ruby
# In your Gemfile with Bundler 2.3.18+
gem "re2", force_ruby_platform: true

# With Bundler 2.1+
bundle config set force_ruby_platform true

# With older versions of Bundler
bundle config force_ruby_platform true

# Without Bundler
gem install re2 --platform=ruby
```

You will need a full compiler toolchain for compiling Ruby C extensions (see
[Nokogiri's "The Compiler
Toolchain"](https://nokogiri.org/tutorials/installing_nokogiri.html#appendix-a-the-compiler-toolchain))
plus the toolchain required for compiling the vendored version of RE2 and its
dependency [Abseil][] which includes [CMake](https://cmake.org), a compiler
with C++14 support such as [clang](http://clang.llvm.org/) 3.4 or
[gcc](https://gcc.gnu.org/) 5 and a recent version of
[pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/). On
Windows, you'll also need pkgconf 2.1.0+ to avoid [`undefined reference`
errors](https://github.com/pkgconf/pkgconf/issues/322) when attempting to
compile Abseil.

### Using system libraries

If you already have RE2 installed, you can instruct the gem not to use its own vendored version:

```ruby
gem install re2 --platform=ruby -- --enable-system-libraries

# If RE2 is not installed in /usr/local, /usr, or /opt/homebrew:
gem install re2 --platform=ruby -- --enable-system-libraries --with-re2-dir=/path/to/re2/prefix
```

Alternatively, you can set the `RE2_USE_SYSTEM_LIBRARIES` environment variable instead of passing `--enable-system-libraries` to the `gem` command.


## Thanks

* Thanks to [Jason Woods](https://github.com/driskell) who contributed the
  original implementations of `RE2::MatchData#begin` and `RE2::MatchData#end`.
* Thanks to [Stefano Rivera](https://github.com/stefanor) who first contributed
  C++11 support.
* Thanks to [Stan Hu](https://github.com/stanhu) for reporting a bug with empty
  patterns and `RE2::Regexp#scan`, contributing support for libre2.11
  (2023-07-01) and for vendoring RE2 and abseil and compiling native gems in
  2.0.
* Thanks to [Sebastian Reitenbach](https://github.com/buzzdeee) for reporting
  the deprecation and removal of the `utf8` encoding option in RE2.
* Thanks to [Sergio Medina](https://github.com/serch) for reporting a bug when
  using `RE2::Scanner#scan` with an invalid regular expression.
* Thanks to [Pritam Baral](https://github.com/pritambaral) for contributing the
  initial support for `RE2::Set`.
* Thanks to [Mike Dalessio](https://github.com/flavorjones) for reviewing the
  precompilation of native gems in 2.0.
* Thanks to [Peter Zhu](https://github.com/peterzhu2118) for
  [ruby_memcheck](https://github.com/Shopify/ruby_memcheck) and helping find
  the memory leaks fixed in 2.1.3.
* Thanks to [Jean Boussier](https://github.com/byroot) for contributing the
  switch to Ruby's `TypedData` API and the resulting garbage collection
  improvements in 2.4.0.
* Thanks to [Manuel Jacob](https://github.com/manueljacob) for reporting a bug
  when passing strings with null bytes.

## Contact

All issues and suggestions should go to [GitHub Issues](https://github.com/mudge/re2/issues).

## License

This library is licensed under the BSD 3-Clause License, see `LICENSE.txt`.

Copyright © 2010, Paul Mucur.

### Dependencies

The source code of [RE2][] is distributed in the `ruby` platform gem. This code is licensed under the BSD 3-Clause License, see `LICENSE-DEPENDENCIES.txt`.

The source code of [Abseil][] is distributed in the `ruby` platform gem. This code is licensed under the Apache License 2.0, see `LICENSE-DEPENDENCIES.txt`.

  [RE2]: https://github.com/google/re2
  [Abseil]: https://abseil.io
