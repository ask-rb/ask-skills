$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../ask-core/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../ask-tools/lib", __dir__)
require "ask/skills"
require "ask/tools"
require "minitest/autorun"
require "mocha/minitest" if Gem.loaded_specs.key?("mocha")
