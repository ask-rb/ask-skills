module Ask
  module Skills
    class Formatter
      def initialize(skills)
        @skills = skills.respond_to?(:skills) ? skills.skills : skills
      end

      def to_prompt_section
        return "" if @skills.empty? || @skills.values.all? { |s| s.is_a?(Array) && s.empty? }

        lines = ["", "## Available Skills", ""]
        @skills.each_value do |skill|
          lines << skill.to_prompt_entry
        end
        lines << ""
        lines << "When a task matches a skill's description, load it for step-by-step methodology."
        lines << ""
        lines.join("\n")
      end

      def to_xml
        return "" if @skills.empty?

        lines = ["", "<available_skills>"]
        @skills.each_value do |skill|
          lines << "  <skill>"
          lines << "    <name>#{escape_xml(skill.name)}</name>"
          lines << "    <description>#{escape_xml(skill.description)}</description>"
          lines << "  </skill>"
        end
        lines << "</available_skills>"
        lines.join("\n")
      end

      private

      def escape_xml(str)
        str.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
           .gsub('"', "&quot;").gsub("'", "&apos;")
      end
    end
  end
end
