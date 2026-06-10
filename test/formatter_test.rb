# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class FormatterTest < Minitest::Test
      def setup
        @skill_a = Skill.new(
          name: "rails.db_debug",
          description: "Debug database issues in Rails",
          instructions: "Check indexes.\nCheck queries.",
          source: "/path/to/a.md"
        )
        @skill_b = Skill.new(
          name: "github.pr_review",
          description: "Review pull requests",
          instructions: "Read diff.\nCheck tests.",
          source: "/path/to/b.md"
        )
      end

      def test_prompt_section_with_skills
        skills = { "a" => @skill_a, "b" => @skill_b }
        formatter = Formatter.new(skills)
        output = formatter.to_prompt_section

        assert_includes output, "## Available Skills"
        assert_includes output, "rails.db_debug"
        assert_includes output, "Debug database issues in Rails"
        assert_includes output, "github.pr_review"
        assert_includes output, "Review pull requests"
        assert_includes output, "load it for step-by-step methodology"
      end

      def test_prompt_section_empty
        formatter = Formatter.new({})
        assert_equal "", formatter.to_prompt_section
      end

      def test_prompt_section_with_registry
        registry = stub(skills: { "a" => @skill_a })
        formatter = Formatter.new(registry)
        output = formatter.to_prompt_section

        assert_includes output, "rails.db_debug"
      end

      def test_xml_output
        skills = { "a" => @skill_a }
        formatter = Formatter.new(skills)
        output = formatter.to_xml

        assert_includes output, "<available_skills>"
        assert_includes output, "<skill>"
        assert_includes output, "<name>rails.db_debug</name>"
        assert_includes output, "<description>Debug database issues in Rails</description>"
        assert_includes output, "</skill>"
        assert_includes output, "</available_skills>"
      end

      def test_xml_output_empty
        formatter = Formatter.new({})
        assert_equal "", formatter.to_xml
      end

      def test_xml_escapes_special_characters
        skill = Skill.new(
          name: "test.skill",
          description: 'Uses "quotes" & <tags>',
          instructions: "Body",
          source: "src"
        )
        formatter = Formatter.new({ "t" => skill })
        output = formatter.to_xml

        assert_includes output, "&quot;quotes&quot;"
        assert_includes output, "&amp;"
        assert_includes output, "&lt;tags&gt;"
        refute_includes output, "<tags>"
      end

      def test_xml_with_multiple_skills
        skills = { "a" => @skill_a, "b" => @skill_b }
        formatter = Formatter.new(skills)
        output = formatter.to_xml

        assert_includes output, "rails.db_debug"
        assert_includes output, "github.pr_review"
        assert_equal 2, output.scan("<skill>").size
      end
    end
  end
end
