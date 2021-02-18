#!/bin/bash
set -euo pipefail

ruby_version=$1
libre2_url=$2

# Install libre2-dev
wget -O libre2-dev.deb "$libre2_url"
dpkg -i libre2-dev.deb

# Install Ruby
ruby-build "$ruby_version" "/opt/rubies/${ruby_version}"
export PATH=/opt/rubies/${ruby_version}/bin:$PATH

# Install dependencies for tests
gem install bundler -v '~> 1.11'
bundle install --jobs=2 --retry=3 --deployment

# Run tests
bundle exec rake
