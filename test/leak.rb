$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 're2'

loops = if ENV["LOOPS"]
  ENV["LOOPS"].to_i
else
  150
end

puts "Looping #{loops} times..."

loops.times do
  r = RE2::Regexp.new('woo(oo)(o+)(\d*)')
  r.ok?
  r.match('wooo')
  r.match('wooo', 0)
  r.match('wooo', 1)
  r.match('wooo', 2)
  r =~ 'woooo'
  r =~ 'bob'
  RE2::Replace("woo", "woo", "bob")
  RE2::GlobalReplace("woo", "woo", "bob")
  m = r.match('woooooo1234')
  m[0]
  m[1]
  m[0,2]
  m[1..-1]
  m.string
  m.regexp
  m.inspect
  sleep 0.1
end
