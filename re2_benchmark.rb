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
  x.report("compiled RE2::PartialMatch") do
    r = RE2.new("R{5}R{2}R?")
    100_000.times do
      RE2::PartialMatch(a, r)
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
  x.report("compiled RE2::Replace") do
    r = RE2.new("R{5}R{2}R?")
    100_000.times do
      RE2::Replace(a.dup, r, "W")
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
  x.report("compiled RE2::GlobalReplace") do
    r = RE2.new("R{5}R{2}R?")
    100_000.times do
      RE2::GlobalReplace(a.dup, r, "W")
    end
  end
end

# $ ruby re2_benchmark.rb 
# Rehearsal ---------------------------------------------------------------
# =~                            0.060000   0.000000   0.060000 (  0.063951)
# RE2::PartialMatch             3.930000   0.000000   3.930000 (  3.923722)
# compiled RE2::PartialMatch    0.060000   0.000000   0.060000 (  0.062996)
# sub!                          0.240000   0.020000   0.260000 (  0.255508)
# RE2::Replace                  6.690000   0.060000   6.750000 (  6.822031)
# compiled RE2::Replace         0.440000   0.050000   0.490000 (  0.492322)
# gsub!                        10.500000   0.020000  10.520000 ( 10.557074)
# RE2::GlobalReplace           14.520000   0.040000  14.560000 ( 14.674756)
# compiled RE2::GlobalReplace   7.810000   0.030000   7.840000 (  7.891212)
# ----------------------------------------------------- total: 44.470000sec
# 
#                                   user     system      total        real
# =~                            0.070000   0.000000   0.070000 (  0.064467)
# RE2::PartialMatch             3.910000   0.000000   3.910000 (  3.914005)
# compiled RE2::PartialMatch    0.060000   0.000000   0.060000 (  0.064046)
# sub!                          0.260000   0.030000   0.290000 (  0.289495)
# RE2::Replace                  6.690000   0.050000   6.740000 (  6.745414)
# compiled RE2::Replace         0.440000   0.050000   0.490000 (  0.491500)
# gsub!                        10.650000   0.010000  10.660000 ( 10.651548)
# RE2::GlobalReplace           14.460000   0.030000  14.490000 ( 14.496685)
# compiled RE2::GlobalReplace   7.760000   0.030000   7.790000 (  7.786408)
# 
