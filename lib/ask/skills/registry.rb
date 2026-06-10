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
        lines = ["", "## Available Skills", ""]
        @skills.each_value do |skill|
          lines << skill.to_prompt_entry
        end
        lines << ""
        lines.join("\n")
      end

      private

      def load_all
        @sources.each do |source|
          source.load.each do |skill|
            next unless skill
            # First source wins (project overrides gems, user overrides project)
            @skills[skill.name] ||= skill
          end
        end
      end
    end
  end
end
