module RE2
  class Scanner
    include Enumerable

    def each
      if block_given?
        while matches = scan
          yield matches
        end
      else
        to_enum(:each)
      end
    end
  end
end
