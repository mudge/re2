re2
===

A Ruby binding to [re2][], an "efficient, principled regular expression library".

Installation
------------

You will need [re2][] installed as well as a C++ compiler such as [gcc][] (on Debian and Ubuntu, this is provided by the [build-essential][] package).

If you are using a packaged Ruby distribution, make sure you also have the Ruby header files installed such as those provided by the [ruby-dev][] package on Debian and Ubuntu.

You can then install the library via RubyGems with `gem install re2` or `gem install re2 -- --with-re2-dir=/opt/local/re2` if re2 is not installed in the default location of `/usr/local/`.

Documentation
-------------

Full documentation automatically generated from the latest version is available at <http://rdoc.info/projects/mudge/re2> and <http://yardoc.org/docs/mudge-re2/>.

Usage
-----

You can use re2 as a mostly drop-in replacement for Ruby's own [Regexp][] and [MatchData][] classes:

    $ irb -rubygems
    > require 're2'
    > r = RE2::Regexp.compile('w(\d)(\d+)')
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

Features
--------

* Pre-compiling regular expressions with [`RE2::Regexp.new(re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#96), `RE2::Regexp.compile(re)` or `RE2(re)` (including specifying options, e.g. `RE2::Regexp.new("pattern", :case_sensitive => false)`

  * Extracting matches with `re2.match(text)` (and an exact number of matches with `re2.match(text, number_of_matches)` such as `re2.match("123-234", 2)`)

  * Checking for matches with `re2 =~ text`, `re2 === text` (for use in `case` statements) and `re2 !~ text`

  * Checking regular expression compilation with `re2.ok?`, `re2.error` and `re2.error_arg`

  * Checking regular expression "cost" with `re2.program_size`

  * Checking the options for an expression with `re2.options` or individually with `re2.case_sensitive?`

* Performing in-place replacement with [`RE2::Replace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#335)

* Performing in-place global replacement with [`RE2::GlobalReplace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#352)

* Escaping regular expressions with [`RE2::Regexp.escape(unquoted)`](http://code.google.com/p/re2/source/browse/re2/re2.h#377), `RE2::Regexp.quote(unquoted)` or `RE2::QuoteMeta(unquoted)`

Contact
-------

All feedback should go to the mailing list: <mailto:ruby.re2@librelist.com>

  [re2]: http://code.google.com/p/re2/
  [gcc]: http://gcc.gnu.org/
  [ruby-dev]: http://packages.debian.org/ruby-dev
  [build-essential]: http://packages.debian.org/build-essential
  [Regexp]: http://ruby-doc.org/core/classes/Regexp.html
  [MatchData]: http://ruby-doc.org/core/classes/MatchData.html 
