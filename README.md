re2 [![Build Status](https://secure.travis-ci.org/mudge/re2.png?branch=master)](http://travis-ci.org/mudge/re2)
===

A Ruby binding to [re2][], an "efficient, principled regular expression
library".

Installation
------------

You will need [re2][] installed as well as a C++ compiler such as [gcc][] (on
Debian and Ubuntu, this is provided by the [build-essential][] package). If
you are using Mac OS X, I recommend installing re2 with [Homebrew][] by
running the following:

    $ brew install re2

If you are using Debian, you can install the [libre2-dev][] package like so:

    $ sudo apt-get install libre2-dev

If you are using a packaged Ruby distribution, make sure you also have the
Ruby header files installed such as those provided by the [ruby-dev][] package
on Debian and Ubuntu.

You can then install the library via RubyGems with `gem install re2` or `gem
install re2 -- --with-re2-dir=/opt/local/re2` if re2 is not installed in the
default location of `/usr/local/`.

Documentation
-------------

Full documentation automatically generated from the latest version is
available at <http://rubydoc.info/github/mudge/re2>.

Bear in mind that re2's regular expression syntax differs from PCRE, see the
[official syntax page][] for more details.

Usage
-----

You can use re2 as a mostly drop-in replacement for Ruby's own [Regexp][] and
[MatchData][] classes:

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
> r =~ "w1234"
=> true
> r !~ "bob"
=> true
> r.match("bob")
=> nil
```

As `RE2::Regexp.new` (or `RE2::Regexp.compile`) can be quite verbose, a helper
method has been defined against `Kernel` so you can use a shorter version to
create regular expressions:

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

As of 0.4.0, you can mix `RE2::String` into strings to provide helpers from
the opposite direction:

```console
> require "re2/string"
> string = "My name is Robert Paulson"
=> "My name is Robert Paulson"
> string.extend(RE2::String)
=> "My name is Robert Paulson"
> string.re2_sub("Robert", "Dave")
=> "My name is Dave Paulson"
> string.re2_gsub("a", "e")
=> "My neme is Deve Peulson"
> string.re2_match('D(\S+)')
=> #<RE2::MatchData "Deve" 1:"eve">
> string.re2_escape
=> "My\\ neme\\ is\\ Deve\\ Peulson"
```

If you want these available to all strings, you can reopen `String` like so:

```ruby
class String
  include RE2::String
end
```

As of 0.5.0, you can use `RE2::Regexp#consume` to incrementally scan text for
matches (similar in purpose to Ruby's
[`String#scan`](http://ruby-doc.org/core-2.0.0/String.html#method-i-scan)).
Calling `consume` will return an `RE2::Consumer` which is
[enumerable](http://ruby-doc.org/core-2.0.0/Enumerable.html) meaning you can
use `each` to iterate through the matches (and even use
[`Enumerator::Lazy`](http://ruby-doc.org/core-2.0/Enumerator/Lazy.html)):

```ruby
re = RE2('(\w+)')
consumer = re.consume("It is a truth universally acknowledged")
consumer.each do |match|
  puts match
end

consumer.rewind

enum = consumer.to_enum
enum.next #=> ["It"]
enum.next #=> ["is"]
```

Features
--------

* Pre-compiling regular expressions with
  [`RE2::Regexp.new(re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#96),
  `RE2::Regexp.compile(re)` or `RE2(re)` (including specifying options, e.g.
  `RE2::Regexp.new("pattern", :case_sensitive => false)`

* Extracting matches with `re2.match(text)` (and an exact number of matches
  with `re2.match(text, number_of_matches)` such as `re2.match("123-234", 2)`)

* Extracting matches by name (both with strings and symbols)

* Checking for matches with `re2 =~ text`, `re2 === text` (for use in `case`
  statements) and `re2 !~ text`

* Incrementally scanning text with `re2.consume(text)`

* Checking regular expression compilation with `re2.ok?`, `re2.error` and
  `re2.error_arg`

* Checking regular expression "cost" with `re2.program_size`

* Checking the options for an expression with `re2.options` or individually
  with `re2.case_sensitive?`

* Performing in-place replacement with [`RE2.Replace(str, pattern,
  replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#335)

* Performing in-place global replacement with [`RE2.GlobalReplace(str,
  pattern,
  replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#352)

* Escaping regular expressions with
  [`RE2::Regexp.escape(unquoted)`](http://code.google.com/p/re2/source/browse/re2/re2.h#377),
  `RE2::Regexp.quote(unquoted)` or `RE2.QuoteMeta(unquoted)`

Contact
-------

All feedback should go to the mailing list: <mailto:ruby.re2@librelist.com>

  [re2]: http://code.google.com/p/re2/
  [gcc]: http://gcc.gnu.org/
  [ruby-dev]: http://packages.debian.org/ruby-dev
  [build-essential]: http://packages.debian.org/build-essential
  [Regexp]: http://ruby-doc.org/core/classes/Regexp.html
  [MatchData]: http://ruby-doc.org/core/classes/MatchData.html 
  [Homebrew]: http://mxcl.github.com/homebrew
  [libre2-dev]: http://packages.debian.org/search?keywords=libre2-dev
  [official syntax page]: http://code.google.com/p/re2/wiki/Syntax

