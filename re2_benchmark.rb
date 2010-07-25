# re2 (http://github.com/mudge/re2)
# Ruby bindings to re2, an "efficient, principled regular expression library"
#
# Copyright (c) 2010, Paul Mucur (http://mucur.name)
# Released under the BSD Licence, please see LICENSE.txt

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
  x.report("compiled RE2.match") do
    r = RE2.new("R{5}R{2}R?")
    100_000.times do
      r.match(a, 0)
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
  x.report("match") do
    100_000.times do
      /w(o)(o)/.match("woo")
    end
  end
  x.report("compiled RE2.match") do
    r = RE2.new('w(o)(o)')
    100_000.times do
      r.match("woo")
    end
  end
end

# $ ruby re2_benchmark.rb 
# Rehearsal ---------------------------------------------------------------
# =~                            0.060000   0.000000   0.060000 (  0.077770)
# RE2::PartialMatch             4.030000   0.070000   4.100000 (  4.901453)
# compiled RE2::PartialMatch    0.070000   0.000000   0.070000 (  0.091874)
# compiled RE2.match            0.070000   0.000000   0.070000 (  0.084624)
# sub!                          0.290000   0.030000   0.320000 (  0.408859)
# RE2::Replace                  6.830000   0.170000   7.000000 (  8.203150)
# compiled RE2::Replace         0.470000   0.050000   0.520000 (  0.615735)
# gsub!                        11.530000   0.160000  11.690000 ( 13.450838)
# RE2::GlobalReplace           14.950000   0.250000  15.200000 ( 17.855678)
# compiled RE2::GlobalReplace   7.890000   0.140000   8.030000 (  9.415177)
# match                         0.180000   0.010000   0.190000 (  0.245689)
# compiled RE2.match            0.350000   0.010000   0.360000 (  0.417716)
# ----------------------------------------------------- total: 47.610000sec
# 
#                                   user     system      total        real
# =~                            0.070000   0.000000   0.070000 (  0.084216)
# RE2::PartialMatch             3.850000   0.050000   3.900000 (  4.483494)
# compiled RE2::PartialMatch    0.080000   0.000000   0.080000 (  0.138104)
# compiled RE2.match            0.060000   0.010000   0.070000 (  0.083209)
# sub!                          0.280000   0.000000   0.280000 (  0.366958)
# RE2::Replace                  6.860000   0.110000   6.970000 (  8.153816)
# compiled RE2::Replace         0.470000   0.020000   0.490000 (  0.546738)
# gsub!                        11.920000   0.180000  12.100000 ( 14.063139)
# RE2::GlobalReplace           14.990000   0.240000  15.230000 ( 17.837624)
# compiled RE2::GlobalReplace   7.950000   0.110000   8.060000 (  9.483715)
# match                         0.180000   0.000000   0.180000 (  0.213272)
# compiled RE2.match            0.350000   0.010000   0.360000 (  0.447519)

