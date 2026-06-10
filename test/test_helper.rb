$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "ask/skills"
require "minitest/autorun"
require "mocha/minitest" if Gem.loaded_specs.key?("mocha")
