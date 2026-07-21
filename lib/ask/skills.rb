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
      # Discover skills from all configured sources.
      #
      # @param agent_dir [String, nil] optional agent directory to discover
      #   per-agent skills from (e.g. "agents/health_check")
      # @param sources [Array<Source::Base>, nil] custom source list
      # @return [Registry]
      def discover(sources: nil, agent_dir: nil)
        all_sources = sources || build_source_list(agent_dir: agent_dir)
        Registry.new(all_sources)
      end

      # Default sources when no custom sources or agent directory given.
      # Legacy `.agents/skills/` is kept for backward compatibility.
      def default_sources
        build_source_list
      end

      # Built-in skills that ship with the gem.
      def builtin_skills_dir
        File.join(__dir__, "skills")
      end

      # Load a skill from an arbitrary markdown file path.
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

      private

      # Build the prioritized source list.
      # Order: per-agent → shared project → legacy → user → gems → built-in
      def build_source_list(agent_dir: nil)
        sources = []

        # Per-agent skills (highest priority — agent-specific first)
        if agent_dir
          per_agent = File.join(agent_dir, "skills")
          sources << Source::Filesystem.new(dir: per_agent)
        end

        # Shared project skills
        sources << Source::Filesystem.new(project_dir: "agents/shared/skills")
        sources << Source::Filesystem.new(project_dir: "app/agents/shared/skills")

        # Legacy project skills (backward compat)
        sources << Source::Filesystem.new(project_dir: ".agents/skills")

        # User-global skills
        sources << Source::Filesystem.new(user_dir: "~/.config/ask/skills")

        # Gems
        sources << Source::Gems.new

        # Built-in
        sources << Source::Filesystem.new(dir: builtin_skills_dir)

        sources
      end
    end
  end
end
