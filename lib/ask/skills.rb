require_relative "skills/version"

module Ask
  module Skills
    class Error < StandardError; end

    autoload :Skill, "ask/skills/skill"
    autoload :Registry, "ask/skills/registry"
    autoload :Formatter, "ask/skills/formatter"
    autoload :Validator, "ask/skills/validator"

    module Source
      autoload :Base, "ask/skills/sources/base"
      autoload :Filesystem, "ask/skills/sources/filesystem"
      autoload :Gems, "ask/skills/sources/gems"
    end

    module Format
      autoload :Prompt, "ask/skills/formats/prompt"
    end

    class << self
      def discover(sources: nil)
        Registry.new(sources || default_sources)
      end

      def default_sources
        [
          Source::Gems.new,
          Source::Filesystem.new(project_dir: ".agents/skills"),
          Source::Filesystem.new(user_dir: "~/.config/ask/skills"),
        ]
      end

      def builtin_skills_dir
        File.expand_path("../skills", __dir__)
      end
    end
  end
end
