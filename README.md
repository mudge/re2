re2 [![Build Status](https://github.com/mudge/re2/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/mudge/re2/actions)
===

A Ruby binding to [re2][], an "efficient, principled regular expression
library".

**Current version:** 1.4.0  
**Supported Ruby versions:** 1.8.7, 1.9.3, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.0  
**Supported re2 versions:** libre2.0 (< 2020-03-02), libre2.1 (2020-03-02), libre2.6 (2020-03-03), libre2.7 (2020-05-01), libre2.8 (2020-07-06), libre2.9 (2020-11-01)

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
install re2 -- --with-re2-dir=/path/to/re2/prefix` if re2 is not installed in
any of the following default locations:

* `/usr/local`
* `/opt/homebrew`
* `/usr`

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

On versions later than 1.4.0, you can use `RE2::Set` to match multiple patterns
against a string. Calling `RE2::Set#add` with a pattern will return an integer
index of the pattern. After all patterns have been added, the set can be
compiled using `RE2::Set#compile`, and then `RE2::Set#match` will return an
`Array<Integer>` containing the indexes of all the patterns that matched.

``` ruby
set = RE2::Set.new
set.add("abc") #=> 0
set.add("def") #=> 1
set.add("ghi") #=> 2
set.compile #=> true
set.match("abcdefghi") #=> [0, 1, 2]
set.match("ghidefabc") #=> [2, 1, 0]
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
* Thanks to [Stan Hu](https://github.com/stanhu) for reporting a bug with empty patterns and `RE2::Regexp#scan`;
* Thanks to [Sebastian Reitenbach](https://github.com/buzzdeee) for reporting
  the deprecation and removal of the `utf8` encoding option in re2;
* Thanks to [Sergio Medina](https://github.com/serch) for reporting a bug when
  using `RE2::Scanner#scan` with an invalid regular expression.

Contact
-------

All issues and suggestions should go to [GitHub Issues](https://github.com/mudge/re2/issues).

  [re2]: https://github.com/google/re2
  [gcc]: http://gcc.gnu.org/
  [ruby-dev]: http://packages.debian.org/ruby-dev
  [build-essential]: http://packages.debian.org/build-essential
  [Regexp]: http://ruby-doc.org/core/classes/Regexp.html
  [MatchData]: http://ruby-doc.org/core/classes/MatchData.html
  [Homebrew]: http://mxcl.github.com/homebrew
  [libre2-dev]: http://packages.debian.org/search?keywords=libre2-dev
  [official syntax page]: https://github.com/google/re2/wiki/Syntax

