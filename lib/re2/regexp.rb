module RE2
  class Regexp
    # Match the pattern against any substring of the given +text+ and return
    # either a boolean (if no submatches are required) or a {RE2::MatchData}
    # instance with the specified number of submatches (defaults to the total
    # number of capturing groups).
    #
    # The number of submatches has a significant impact on performance: requesting
    # one submatch is much faster than requesting more than one and requesting
    # zero submatches is faster still.
    #
    # @param [String] text the text to search
    # @param [Hash] options the options with which to perform the match
    # @option options [Integer] :submatches how many submatches to extract (0
    #   is fastest), defaults to the total number of capturing groups
    # @return [RE2::MatchData] if extracting any submatches
    # @return [Boolean] if not extracting any submatches
    # @raise [ArgumentError] if given a negative number of submatches
    # @raise [NoMemoryError] if there was not enough memory to allocate the
    #   matches
    # @raise [TypeError] if given non-numeric submatches or non-hash options
    # @example
    #   r = RE2::Regexp.new('w(o)(o)')
    #   r.partial_match('woot')
    #   #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
    #   r.partial_match('woot', submatches: 1) #=> #<RE2::MatchData "woo" 1:"o">
    #   r.partial_match('woot', submatches: 0) #=> true
    def partial_match(text, options = {})
      match(text, Hash(options).merge(anchor: :unanchored))
    end

    # Match the pattern against the given +text+ exactly and return either a
    # boolean (if no submatches are required) or a {RE2::MatchData} instance
    # with the specified number of submatches (defaults to the total number of
    # capturing groups).
    #
    # The number of submatches has a significant impact on performance: requesting
    # one submatch is much faster than requesting more than one and requesting
    # zero submatches is faster still.
    #
    # @param [String] text the text to search
    # @param [Hash] options the options with which to perform the match
    # @option options [Integer] :submatches how many submatches to extract (0
    #   is fastest), defaults to the total number of capturing groups
    # @return [RE2::MatchData] if extracting any submatches
    # @return [Boolean] if not extracting any submatches
    # @raise [ArgumentError] if given a negative number of submatches
    # @raise [NoMemoryError] if there was not enough memory to allocate the
    #   matches
    # @raise [TypeError] if given non-numeric submatches or non-hash options
    # @example
    #   r = RE2::Regexp.new('w(o)(o)')
    #   r.full_match('woo')
    #   #=> #<RE2::MatchData "woo" 1:"o" 2:"o">
    #   r.full_match('woo', submatches: 1) #=> #<RE2::MatchData "woo" 1:"o">
    #   r.full_match('woo', submatches: 0) #=> true
    #   r.full_match('woot') #=> nil
    def full_match(text, options = {})
      match(text, Hash(options).merge(anchor: :anchor_both))
    end

    alias_method :=~, :match?
    alias_method :===, :match?
    alias_method :partial_match?, :match?
  end
end
