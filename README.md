re2
===

A work-in-progress Ruby binding to [re2][], an "efficient, principled regular expression library".

Dependencies
------------

You will need [re2][] and Ruby's headers installed (sometimes provided by a `ruby-dev` package) as well as a C++ compiler such as [gcc][].

Installation
------------

1. `ruby extconf.rb --with-re2-dir=/usr/local`
2. `make`

Then you can use the compiled library from the working directory with something like the following:

    $ irb
    > require './re2' # the ./ is necessary for Ruby 1.9.2
    > r = RE2.new('w(\d)(\d+)')
     => /w(\d)(\d+)/
    > r.match("w1234")
     => ["w1234", "1", "234"]
    > r.match("w1234", 0)
     => true
    > r.match("bob")
     => nil
    > r.match("bob", 0)
     => false

What currently works?
---------------------

* Pre-compiling regular expressions with [`RE2.new(re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#96) (including specifying options, e.g. `RE2.new("pattern", :case_sensitive => false)`

  * Extracting matches with `re2.match(text)`
  * Checking regular expression compilation with `re2.ok?`, `re2.error` and `re2.error_arg`
  * Checking regular expression "cost" with `re2.program_size`
  * Checking the options for an expression with `re2.options`

* Performing full matches with [`RE2::FullMatch(text, re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#30)

* Performing partial matches with [`RE2::PartialMatch(text, re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#82)

* Performing in-place replacement with [`RE2::Replace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#335)

* Performing in-place global replacement with [`RE2::GlobalReplace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#352)

* Escaping regular expressions with [`RE2::QuoteMeta(unquoted)`](http://code.google.com/p/re2/source/browse/re2/re2.h#377)

re2.cc should be well-documented so feel free to consult this file to see what can currently be used.

Why would I want to use this?
----------------------------

To investigate [re2][]; be warned that not using a pre-compiled expression (viz. `RE2.new(pattern)`) will result in *worse* performance than Ruby's native regular expression library (see `re2_benchmark.rb` for rudimentary benchmarks).

What's wrong with [rre2][]?
---------------------------

Nothing, I just wanted to teach myself to write Ruby extensions in C++ and match re2's native interface more closely.

  [gcc]: http://gcc.gnu.org/
  [re2]: http://code.google.com/p/re2/
  [rre2]: http://github.com/axic/rre2
