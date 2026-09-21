module Ask
  module Skills
    class Registry
      attr_reader :skills

      def initialize(sources)
        @skills = {}
        @sources = sources
        load_all
      end

      def [](name)
        @skills[name]
      end

      def names
        @skills.keys
      end

      def format_for_prompt
        return "" if @skills.empty?
        Formatter.new(@skills).to_prompt_section
      end

      # Full instructions for skills with +always: true+ in their frontmatter.
      # These skills are auto-injected into the system prompt rather than
      # being listed for the LLM to load on demand.
      def always_active_skills
        @skills.values.select { |s| s.metadata["always"] == "true" || s.metadata["always"] == true }
      end

      private

      def load_all
        @sources.each do |source|
          source.load.each do |skill|
            next unless skill
            if @skills.key?(skill.name)
              existing = @skills[skill.name]
              if skill_equivalent?(existing, skill)
                # Exact duplicate (e.g. local + installed gem copy) — skip silently
                next
              end
              # Same gem identity (e.g. local sibling gem vs installed gem of
              # the same name) — expected duplicate source, not a collision.
              next if same_gem?(existing, skill)

              warn "[ask-skills] Collision: skill '#{skill.name}' already loaded from " \
                   "#{existing.source}, skipping #{skill.source}"
            else
              @skills[skill.name] = skill
            end
          end
        end
      end

      # Two skills are equivalent when they share the same description and
      # instructions (the two fields that matter for prompt entry and loading).
      # Different sources (local vs gem) for the exact same content are
      # silently deduplicated.
      def skill_equivalent?(a, b)
        a.description == b.description && a.instructions == b.instructions
      end

      # Two skills belong to the same gem when their source paths share a
      # common ask-* gem directory (e.g. local sibling gem vs installed gem
      # of the same name).  Returns +nil+ when no gem name can be extracted.
      def same_gem?(a, b)
        a_name = extract_gem_name(a.source)
        b_name = extract_gem_name(b.source)
        return false if a_name.nil? || b_name.nil?

        a_name == b_name
      end

      # Extract the gem directory name from a source path.  Checks the
      # immediate parent directory first, then walks up ancestors only if
      # the parent is not an ask-* directory.  This prevents false matches
      # when an ask-* directory is nested inside another ask-* directory
      # (e.g. +ask-x/ask-y/SKILL.md+ → +ask-y+, not +ask-x+).
      # Strips version suffixes (e.g. +ask-skills-0.5.1+ → +ask-skills+).
      def extract_gem_name(path)
        return nil unless path
        dir = File.dirname(path)
        # Check immediate parent first — the most specific ask-* ancestor
        parent = File.basename(dir)
        if parent.match?(/\Aask-\w/)
          return parent.sub(/-[\d.]+$/, "")
        end
        # Walk up ancestors until we find an ask-* directory
        parent = File.dirname(dir)
        while parent != File.dirname(parent)
          component = File.basename(parent)
          if component.match?(/\Aask-\w/)
            return component.sub(/-[\d.]+$/, "")
          end
          parent = File.dirname(parent)
        end
        nil
      end
    end
  end
end
