module Ask
  module Skills
    class Validator
      ValidationError = Data.define(:skill_name, :message)

      def initialize(skills)
        @skills = skills
      end

      def validate_all
        errors = []
        names = {}
        @skills.each do |skill|
          errors.concat(validate(skill))
          if names[skill.name]
            errors << ValidationError.new(skill.name, "Duplicate skill name from #{names[skill.name]} and #{skill.source}")
          end
          names[skill.name] = skill.source
        end
        errors
      end

      def validate(skill)
        errors = []
        errors << ValidationError.new(skill.name, "Name is empty") if skill.name.empty?
        errors << ValidationError.new(skill.name, "Description is empty") if skill.description.empty?
        errors << ValidationError.new(skill.name, "Instructions are empty") if skill.instructions.strip.empty?
        unless skill.name =~ /^[a-z0-9_.-]+$/
          errors << ValidationError.new(skill.name, "Name must be lowercase, with only letters, numbers, dots, hyphens, underscores")
        end
        errors
      end
    end
  end
end
