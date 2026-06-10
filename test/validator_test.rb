# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class ValidatorTest < Minitest::Test
      def test_valid_skill_passes
        skill = Skill.new(
          name: "valid.skill",
          description: "A valid skill",
          instructions: "Do the thing",
          source: "/path/to/skill.md"
        )
        validator = Validator.new([skill])
        errors = validator.validate_all

        assert_empty errors
      end

      def test_empty_name_fails
        skill = Skill.new(
          name: "",
          description: "No name",
          instructions: "Body",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert_equal 1, errors.size
        assert_match(/Name is empty/i, errors.first.message)
      end

      def test_empty_description_fails
        skill = Skill.new(
          name: "no.desc",
          description: "",
          instructions: "Body",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert_equal 1, errors.size
        assert_match(/Description is empty/i, errors.first.message)
      end

      def test_empty_instructions_fails
        skill = Skill.new(
          name: "no.inst",
          description: "Has a description",
          instructions: "   ",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert_equal 1, errors.size
        assert_match(/Instructions are empty/i, errors.first.message)
      end

      def test_invalid_name_format_fails
        skill = Skill.new(
          name: "Invalid Name!",
          description: "Bad name",
          instructions: "Body",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert errors.any? { |e| e.message =~ /lowercase/ }
      end

      def test_name_with_dots_passes
        skill = Skill.new(
          name: "rails.db_debug",
          description: "Valid name with dots",
          instructions: "Body",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert_empty errors
      end

      def test_name_with_hyphens_passes
        skill = Skill.new(
          name: "my-skill",
          description: "Hyphenated name",
          instructions: "Body",
          source: "src"
        )
        errors = Validator.new([skill]).validate_all

        assert_empty errors
      end

      def test_duplicate_name_detection
        skill1 = Skill.new(name: "dup", description: "First", instructions: "Body", source: "src1")
        skill2 = Skill.new(name: "dup", description: "Second", instructions: "Body", source: "src2")

        errors = Validator.new([skill1, skill2]).validate_all

        assert errors.any? { |e| e.message =~ /Duplicate/ }
      end

      def test_multiple_errors_on_one_skill
        skill = Skill.new(name: "", description: "", instructions: "", source: "src")
        errors = Validator.new([skill]).validate_all

        assert errors.size >= 3
      end

      def test_validates_multiple_skills
        skills = [
          Skill.new(name: "good", description: "First", instructions: "Body", source: "s1"),
          Skill.new(name: "also_good", description: "Second", instructions: "Body", source: "s2"),
        ]
        errors = Validator.new(skills).validate_all

        assert_empty errors
      end

      def test_single_validation
        skill = Skill.new(name: "", description: "desc", instructions: "body", source: "src")
        errors = Validator.new([]).validate(skill)

        assert_equal 1, errors.size
        assert_match(/Name is empty/i, errors.first.message)
      end

      def test_validation_error_structure
        error = Validator::ValidationError.new("skill.name", "Something went wrong")
        assert_equal "skill.name", error.skill_name
        assert_equal "Something went wrong", error.message
      end
    end
  end
end
