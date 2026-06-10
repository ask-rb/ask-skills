# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class SkillTest < Minitest::Test
      def test_construction
        skill = Skill.new(
          name: "rails.db_debug",
          description: "Debug database issues in Rails",
          instructions: "Step 1: Check schema\nStep 2: Check indexes",
          source: "/path/to/skill.md"
        )

        assert_equal "rails.db_debug", skill.name
        assert_equal "Debug database issues in Rails", skill.description
        assert_equal "Step 1: Check schema\nStep 2: Check indexes", skill.instructions
        assert_equal "/path/to/skill.md", skill.source
      end

      def test_to_s
        skill = Skill.new(
          name: "rails.db_debug",
          description: "Debug database issues in Rails",
          instructions: "Some content",
          source: "/path/to/skill.md"
        )

        assert_equal "rails.db_debug: Debug database issues in Rails", skill.to_s
      end

      def test_to_prompt_entry
        skill = Skill.new(
          name: "rails.db_debug",
          description: "Debug database issues in Rails",
          instructions: "Some content",
          source: "/path/to/skill.md"
        )

        assert_equal "- **rails.db_debug**: Debug database issues in Rails", skill.to_prompt_entry
      end

      def test_equality
        skill1 = Skill.new(name: "a", description: "desc", instructions: "body", source: "s1")
        skill2 = Skill.new(name: "a", description: "desc", instructions: "body", source: "s2")

        refute_equal skill1, skill2
      end

      def test_missing_description
        skill = Skill.new(name: "no_desc", description: "", instructions: "body", source: "src")
        assert_equal "", skill.description
      end
    end
  end
end
