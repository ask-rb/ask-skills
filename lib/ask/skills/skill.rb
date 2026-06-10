module Ask
  module Skills
    Skill = Data.define(:name, :description, :instructions, :source) do
      def to_s
        "#{name}: #{description}"
      end

      def to_prompt_entry
        "- **#{name}**: #{description}"
      end
    end
  end
end
