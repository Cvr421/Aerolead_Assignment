ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Ensure Ruby's stdlib Logger is loaded early so ActiveSupport's logger helpers
# can reference Logger during boot (works around load-order issues observed in
# some environments with bootsnap/activesupport).
require 'logger'

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
