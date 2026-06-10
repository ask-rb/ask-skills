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

    class << self
      def discover(sources: nil)
        Registry.new(sources || default_sources)
      end

      def default_sources
        [
          # Highest priority first — first source wins in Registry
          Source::Filesystem.new(project_dir: ".agents/skills"),
          Source::Filesystem.new(user_dir: "~/.config/ask/skills"),
          Source::Gems.new,
          Source::Filesystem.new(dir: builtin_skills_dir),
        ]
      end

      def builtin_skills_dir
        # Skills live in lib/ask/skills/<skill_name>/SKILL.md
        # __dir__ in this file (lib/ask/skills.rb) is lib/ask/
        # The skill directories are in lib/ask/skills/
        File.join(__dir__, "skills")
      end
    end
  end
end
