re2
===

What is this?
-------------

A work-in-progress Ruby binding to [re2][], an "efficient, principled regular expression library".

Dependencies
------------

You will need [re2][] and Ruby's headers installed as well as a C++ compiler such as [gcc][].

What currently works?
---------------------

Only `RE2::FullMatch(text, re)` and `RE2::PartialMatch(text, re)` at the moment.

What's wrong with [rre2][]?
---------------------------

Nothing, I just wanted to teach myself to write Ruby extensions in C++ and match re2's native interface.

  [gcc]: http://gcc.gnu.org/
  [re2]: http://code.google.com/p/re2/
  [rre2]: http://github.com/axic/rre2
