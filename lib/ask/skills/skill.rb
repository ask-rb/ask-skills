# frozen_string_literal: true

module Ask
  module Skills
    # A discovered skill with its metadata, instructions, and sibling files.
    #
    # Skills live in directories following the SKILL.md convention:
    #
    #   rails_debug/
    #   ├── SKILL.md          → name, description, tags, instructions
    #   ├── references/       → reference documents (loaded on demand)
    #   ├── scripts/          → executable helpers
    #   └── assets/           → images, templates, other resources
    #
    # The +siblings+ hash maps category names to arrays of file paths,
    # relative to the skill's directory. Categories are inferred from
    # sibling directory names (references, scripts, assets) or files.
    Skill = Data.define(:name, :description, :instructions, :source, :metadata, :siblings) do
      def initialize(name:, description:, instructions:, source:, metadata: {}, siblings: {})
        super(name: name, description: description, instructions: instructions,
              source: source, metadata: metadata, siblings: siblings)
      end

      def to_s
        "#{name}: #{description}"
      end

      def to_prompt_entry
        line = "- **#{name}**: #{description}"
        line
      end

      # Reference documents bundled with this skill.
      # @return [Array<String>] file paths relative to skill directory
      def references
        siblings["references"] || []
      end

      # Executable scripts bundled with this skill.
      # @return [Array<String>] file paths relative to skill directory
      def scripts
        siblings["scripts"] || []
      end

      # Asset files bundled with this skill.
      # @return [Array<String>] file paths relative to skill directory
      def assets
        siblings["assets"] || []
      end

      # Comma-separated tags from frontmatter.
      # @return [Array<String>]
      def tags
        raw = metadata["tags"] || metadata[:tags] || ""
        raw.split(",").map(&:strip).reject(&:empty?)
      end
    end
  end
end
