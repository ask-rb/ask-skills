module Ask
  module Skills
    class Formatter
      def initialize(registry)
        @registry = registry
      end

      def to_prompt_section
        return "" if @registry.skills.empty?

        lines = ["", "## Available Skills", ""]
        @registry.skills.each_value do |skill|
          lines << skill.to_prompt_entry
        end
        lines << ""
        lines << "When you need domain-specific guidance, call the relevant skill by name."
        lines << "Each skill contains step-by-step methodology for that domain."
        lines << ""
        lines.join("\n")
      end

      def to_xml
        return "" if @registry.skills.empty?

        lines = ["", "<available_skills>"]
        @registry.skills.each_value do |skill|
          lines << "  <skill>"
          lines << "    <name>#{escape_xml(skill.name)}</name>"
          lines << "    <description>#{escape_xml(skill.description)}</description>"
          lines << "  </skill>"
        end
        lines << "</available_skills>"
        lines << ""
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
