# frozen_string_literal: true

# re2 (https://github.com/mudge/re2)
# Ruby bindings to RE2, a "fast, safe, thread-friendly alternative to
# backtracking regular expression engines like those used in PCRE, Perl, and
# Python".
#
# Copyright (c) 2010, Paul Mucur (https://mudge.name)
# Released under the BSD Licence, please see LICENSE.txt


module RE2
  class Regexp
    # Match the pattern against any substring of the given `text` and return a
    # {RE2::MatchData} instance with the specified number of submatches
    # (defaults to the total number of capturing groups) or a boolean (if no
    # submatches are required).
    #
    # The number of submatches has a significant impact on performance: requesting
    # one submatch is much faster than requesting more than one and requesting
    # zero submatches is faster still.
    #
    # @param [String] text the text to search
    # @param [Hash] options the options with which to perform the match
    # @option options [Integer] :submatches how many submatches to extract (0
    #   is fastest), defaults to the total number of capturing groups
    # @return [RE2::MatchData, nil] if extracting any submatches
    # @return [Boolean] if not extracting any submatches
    # @raise [ArgumentError] if given a negative number of submatches
    # @raise [NoMemoryError] if there was not enough memory to allocate the
    #   matches
    # @raise [TypeError] if given non-numeric submatches or non-hash options
    # @example
    #   r = RE2::Regexp.new('w(o)(o)')
    #   r.partial_match('woot')                #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
    #   r.partial_match('nope')                #=> nil
    #   r.partial_match('woot', submatches: 1) #=> #<RE2::MatchData "woo" 1:"o">
    #   r.partial_match('woot', submatches: 0) #=> true
    def partial_match(text, options = {})
      match(text, Hash(options).merge(anchor: :unanchored))
    end

    # Match the pattern against the given `text` exactly and return a
    # {RE2::MatchData} instance with the specified number of submatches
    # (defaults to the total number of capturing groups) or a boolean (if no
    # submatches are required).
    #
    # The number of submatches has a significant impact on performance: requesting
    # one submatch is much faster than requesting more than one and requesting
    # zero submatches is faster still.
    #
    # @param [String] text the text to search
    # @param [Hash] options the options with which to perform the match
    # @option options [Integer] :submatches how many submatches to extract (0
    #   is fastest), defaults to the total number of capturing groups
    # @return [RE2::MatchData, nil] if extracting any submatches
    # @return [Boolean] if not extracting any submatches
    # @raise [ArgumentError] if given a negative number of submatches
    # @raise [NoMemoryError] if there was not enough memory to allocate the
    #   matches
    # @raise [TypeError] if given non-numeric submatches or non-hash options
    # @example
    #   r = RE2::Regexp.new('w(o)(o)')
    #   r.full_match('woo')                #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
    #   r.full_match('woot')               #=> nil
    #   r.full_match('woo', submatches: 1) #=> #<RE2::MatchData "woo" 1:"o">
    #   r.full_match('woo', submatches: 0) #=> true
    def full_match(text, options = {})
      match(text, Hash(options).merge(anchor: :anchor_both))
    end

    # Match the pattern against any substring of the given `text`, returning
    # `false` if it is not a `String`, `Symbol`, or object responding to
    # `to_str` so that an {RE2::Regexp} can be used in a `case` statement like
    # Ruby's own `Regexp#===`.
    #
    # @param [Object] text the text to search; anything other than a `String`,
    #   `Symbol`, or object responding to `to_str` returns `false`
    # @return [Boolean] whether the match was successful
    # @example
    #   case "bob 123"
    #   when RE2::Regexp.new('\d+')
    #     "numbers"
    #   end
    def ===(text)
      text = text.to_s if text.is_a?(Symbol)
      text = ::String.try_convert(text)
      return false unless text

      match?(text)
    end

    # Return whether this regular expression has the same pattern and options
    # as another {RE2::Regexp}.
    #
    # @param [Object] other the object to compare against
    # @return [Boolean] whether the two regular expressions are equal
    # @example
    #   RE2::Regexp.new('abc') == RE2::Regexp.new('abc')                        #=> true
    #   RE2::Regexp.new('abc') == RE2::Regexp.new('abc', case_sensitive: false) #=> false
    def ==(other)
      other.is_a?(RE2::Regexp) && source == other.source && options == other.options
    end

    alias_method :eql?, :==

    # Return a hash based on the pattern and options so that equal
    # {RE2::Regexp}s can be used as Hash keys.
    #
    # @return [Integer] the hash of the regular expression
    def hash
      [source, options].hash
    end
  end
end
