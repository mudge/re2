re2 [![Build Status](https://travis-ci.org/mudge/re2.svg?branch=master)](http://travis-ci.org/mudge/re2)
===

A Ruby binding to [re2][], an "efficient, principled regular expression
library".

**Current version:** 1.1.1  
**Supported Ruby versions:** 1.8.7, 1.9.2, 1.9.3, 2.0.0, 2.1.0, 2.2, 2.3, Rubinius 3.8

Installation
------------

You will need [re2][] installed as well as a C++ compiler such as [gcc][] (on
Debian and Ubuntu, this is provided by the [build-essential][] package). If
you are using Mac OS X, I recommend installing re2 with [Homebrew][] by
running the following:

    $ brew install re2

If you are using Debian, you can install the [libre2-dev][] package like so:

    $ sudo apt-get install libre2-dev

Recent versions of re2 require a compiler with C++11 support such as [clang](http://clang.llvm.org/) 3.4 or [gcc](https://gcc.gnu.org/) 4.8.

If you are using a packaged Ruby distribution, make sure you also have the
Ruby header files installed such as those provided by the [ruby-dev][] package
on Debian and Ubuntu.

You can then install the library via RubyGems with `gem install re2` or `gem
install re2 -- --with-re2-dir=/opt/local/re2` if re2 is not installed in the
default location of `/usr/local/`.

Documentation
-------------

Full documentation automatically generated from the latest version is
available at <http://mudge.name/re2/>.

Note that re2's regular expression syntax differs from PCRE and Ruby's
built-in [`Regexp`][Regexp] library, see the [official syntax page][] for more
details.

Usage
-----

While re2 uses the same naming scheme as Ruby's built-in regular expression
library (with [`Regexp`](http://mudge.name/re2/RE2/Regexp.html) and
[`MatchData`](http://mudge.name/re2/RE2/MatchData.html)), its API is slightly
different:

```console
$ irb -rubygems
> require 're2'
> r = RE2::Regexp.new('w(\d)(\d+)')
=> #<RE2::Regexp /w(\d)(\d+)/>
> m = r.match("w1234")
=> #<RE2::MatchData "w1234" 1:"1" 2:"234">
> m[1]
=> "1"
> m.string
=> "w1234"
> m.begin(1)
=> 1
> m.end(1)
=> 2
> r =~ "w1234"
=> true
> r !~ "bob"
=> true
> r.match("bob")
=> nil
```

As
[`RE2::Regexp.new`](http://mudge.name/re2/RE2/Regexp.html#initialize-instance_method)
(or `RE2::Regexp.compile`) can be quite verbose, a helper method has been
defined against `Kernel` so you can use a shorter version to create regular
expressions:

```console
> RE2('(\d+)')
=> #<RE2::Regexp /(\d+)/>
```

Note the use of *single quotes* as double quotes will interpret `\d` as `d` as
in the following example:

```console
> RE2("(\d+)")
=> #<RE2::Regexp /(d+)/>
```

As of 0.3.0, you can use named groups:

```console
> r = RE2::Regexp.new('(?P<name>\w+) (?P<age>\d+)')
=> #<RE2::Regexp /(?P<name>\w+) (?P<age>\d+)/>
> m = r.match("Bob 40")
=> #<RE2::MatchData "Bob 40" 1:"Bob" 2:"40">
> m[:name]
=> "Bob"
> m["age"]
=> "40"
```

As of 0.6.0, you can use `RE2::Regexp#scan` to incrementally scan text for
matches (similar in purpose to Ruby's
[`String#scan`](http://ruby-doc.org/core-2.0.0/String.html#method-i-scan)).
Calling `scan` will return an `RE2::Scanner` which is
[enumerable](http://ruby-doc.org/core-2.0.0/Enumerable.html) meaning you can
use `each` to iterate through the matches (and even use
[`Enumerator::Lazy`](http://ruby-doc.org/core-2.0/Enumerator/Lazy.html)):

```ruby
re = RE2('(\w+)')
scanner = re.scan("It is a truth universally acknowledged")
scanner.each do |match|
  puts match
end

scanner.rewind

enum = scanner.to_enum
enum.next #=> ["It"]
enum.next #=> ["is"]
```

Features
--------

* Pre-compiling regular expressions with
  [`RE2::Regexp.new(re)`](https://github.com/google/re2/blob/2016-02-01/re2/re2.h#L100),
  `RE2::Regexp.compile(re)` or `RE2(re)` (including specifying options, e.g.
  `RE2::Regexp.new("pattern", :case_sensitive => false)`

* Extracting matches with `re2.match(text)` (and an exact number of matches
  with `re2.match(text, number_of_matches)` such as `re2.match("123-234", 2)`)

* Extracting matches by name (both with strings and symbols)

* Checking for matches with `re2 =~ text`, `re2 === text` (for use in `case`
  statements) and `re2 !~ text`

* Incrementally scanning text with `re2.scan(text)`

* Checking regular expression compilation with `re2.ok?`, `re2.error` and
  `re2.error_arg`

* Checking regular expression "cost" with `re2.program_size`

* Checking the options for an expression with `re2.options` or individually
  with `re2.case_sensitive?`

* Performing a single string replacement with `pattern.replace(replacement,
  original)`

* Performing a global string replacement with
  `pattern.replace_all(replacement, original)`

* Escaping regular expressions with
  [`RE2.escape(unquoted)`](https://github.com/google/re2/blob/2016-02-01/re2/re2.h#L418) and
  `RE2.quote(unquoted)`

Contributions
-------------

* Thanks to [Jason Woods](https://github.com/driskell) who contributed the
original implementations of `RE2::MatchData#begin` and `RE2::MatchData#end`;
* Thanks to [Stefano Rivera](https://github.com/stefanor) who first contributed C++11 support;
* Thanks to [Stan Hu](https://github.com/stanhu) for reporting a bug with empty patterns and `RE2::Regexp#scan`.

Contact
-------

All feedback should go to the mailing list: <mailto:ruby.re2@librelist.com>

  [re2]: https://github.com/google/re2
  [gcc]: http://gcc.gnu.org/
  [ruby-dev]: http://packages.debian.org/ruby-dev
  [build-essential]: http://packages.debian.org/build-essential
  [Regexp]: http://ruby-doc.org/core/classes/Regexp.html
  [MatchData]: http://ruby-doc.org/core/classes/MatchData.html
  [Homebrew]: http://mxcl.github.com/homebrew
  [libre2-dev]: http://packages.debian.org/search?keywords=libre2-dev
  [official syntax page]: https://github.com/google/re2/wiki/Syntax

