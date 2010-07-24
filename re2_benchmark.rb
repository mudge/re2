require File.join(File.dirname(__FILE__), "re2")
require "benchmark"

a = "R" * 1000

Benchmark.bmbm do |x|
  x.report("=~") do
    100_000.times do
      a =~ /R{5}R{2}R?/
    end
  end
  x.report("RE2::PartialMatch") do
    100_000.times do
      RE2::PartialMatch(a, "R{5}R{2}R?")
    end
  end
  x.report("sub!") do
    100_000.times do
      a.dup.sub!(/R{5}R{2}R?/, "W")
    end
  end
  x.report("RE2::Replace") do
    100_000.times do
      RE2::Replace(a.dup, "R{5}R{2}R?", "W")
    end
  end
  x.report("gsub!") do
    100_000.times do
      a.dup.gsub!(/R{5}R{2}R?/, "W")
    end
  end
  x.report("RE2::GlobalReplace") do
    100_000.times do
      RE2::GlobalReplace(a.dup, "R{5}R{2}R?", "W")
    end
  end
end
