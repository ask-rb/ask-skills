module Ask
  module Skills
    module Format
      class Prompt
        def self.render(skills)
          new(skills).render
        end

        def initialize(skills)
          @skills = skills
        end

        def render
          Formatter.new(@skills).to_prompt_section
        end
      end
    end
  end
end
