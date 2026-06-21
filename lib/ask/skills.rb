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

      # Load a skill from an arbitrary markdown file path.
      # Parses frontmatter if present, otherwise uses the filename as the skill name.
      #
      # @param path [String] absolute or relative path to a markdown (.md) file
      # @return [Skill] a skill with the file's content as instructions
      # @raise [Errno::ENOENT] if the file does not exist
      def load_file(path)
        path = File.expand_path(path)
        content = File.read(path)
        frontmatter = parse_frontmatter(content)
        body = extract_body(content)

        name = frontmatter["name"] || File.basename(path, ".md")
        description = frontmatter["description"] || "Ad-hoc skill loaded from #{File.basename(path)}"

        Skill.new(
          name: name,
          description: description,
          instructions: body.empty? ? content : body,
          source: path
        )
      end

      # Simple frontmatter parsing for skill files.
      # Returns a hash of key-value pairs from between --- markers.
      def parse_frontmatter(content)
        return {} unless content.start_with?("---\n")
        end_idx = content.index("\n---\n", 4)
        return {} unless end_idx
        yaml_str = content[4...end_idx]
        yaml = {}
        yaml_str.split("\n").each do |line|
          if (m = line.match(/\A(\w+):\s*(.+)\z/))
            value = m[2].strip
            value = value.gsub(/\A"|"\z/, "").gsub(/\A'|'\z/, "")
            yaml[m[1]] = value
          end
        end
        yaml
      end

      # Extract the markdown body from a file with frontmatter.
      def extract_body(content)
        return content unless content.start_with?("---\n")
        end_idx = content.index("\n---\n", 4)
        return content unless end_idx
        body = content[(end_idx + 5)..] || ""
        body.sub(/\A\n/, "").strip
      end
    end
  end
end
