module RE2
  class MatchData

    # Returns the offset of the start of a match
    def begin(n)
      until_begin(n).scan(/./mu).size
    end

    # Returns the offset of the character following the end of a match
    def end(n)
      until_end(n).scan(/./mu).size
    end
  end
end
