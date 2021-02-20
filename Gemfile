source "https://rubygems.org"

gemspec

rake_constraint = if RUBY_VERSION < "1.9.3"
                    "< 11.0.0"
                  elsif RUBY_VERSION < "2.0.0"
                    "< 12.0.0"
                  else
                    "> 12.3.2"
                  end

gem "rake", rake_constraint
