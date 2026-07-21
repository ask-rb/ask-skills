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
              # First-wins collision: log diagnostic but keep first
              warn "[ask-skills] Collision: skill '#{skill.name}' already loaded from " \
                   "#{@skills[skill.name].source}, skipping #{skill.source}"
            else
              @skills[skill.name] = skill
            end
          end
        end
      end
    end
  end
end
