re2
===

A work-in-progress Ruby binding to [re2][], an "efficient, principled regular expression library".

Dependencies
------------

You will need [re2][] and Ruby's headers installed as well as a C++ compiler such as [gcc][].

What currently works?
---------------------

* Pre-compiling regular expressions with [`RE2.new(re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#96) (including specifying options, e.g. `RE2.new("pattern", :case_sensitive => false)`
* Performing full matches with [`RE2::FullMatch(text, re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#30)
* Performing partial matches with [`RE2::PartialMatch(text, re)`](http://code.google.com/p/re2/source/browse/re2/re2.h#82)
* Performing in-place replacement with [`RE2::Replace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#335)
* Performing in-place global replacement with [`RE2::GlobalReplace(str, pattern, replace)`](http://code.google.com/p/re2/source/browse/re2/re2.h#352)

Why would I want to use this?
----------------------------

At the moment, just to investigate [re2][] as it actually performs *worse* than Ruby's own `=~`, `sub!` and `gsub!` method unless you pre-compile the expression by using `RE2.new`.

What's wrong with [rre2][]?
---------------------------

Nothing, I just wanted to teach myself to write Ruby extensions in C++ and match re2's native interface.

  [gcc]: http://gcc.gnu.org/
  [re2]: http://code.google.com/p/re2/
  [rre2]: http://github.com/axic/rre2
