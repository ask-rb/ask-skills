require_relative "lib/ask/skills/version"

Gem::Specification.new do |spec|
  spec.name = "ask-skills"
  spec.version = Ask::Skills::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Skill discovery and management for the ask-rb ecosystem"
  spec.description = "Discovers, validates, and formats agent skills from project directories, " \
                     "user config, and installed gems. Ships built-in skills (codebase exploration, " \
                     "debugging methodology). Each skill is a markdown file with step-by-step " \
                     "instructions that the agent loads on demand."
  spec.homepage = "https://github.com/ask-rb/ask-skills"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
