module RE2
  class Consumer
    include Enumerable

    def each
      if block_given?
        while matches = consume
          yield matches
        end
      else
        to_enum(:each)
      end
    end
  end
end
