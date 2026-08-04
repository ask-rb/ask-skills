# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class LoadSkillToolTest < Minitest::Test
      def setup
        @skill = Skill.new(
          name: "writing-guide", description: "Guide for writing",
          instructions: "Write clearly and concisely.", source: "writing-guide/SKILL.md"
        )
        @registry = Registry.new([stub(load: [@skill])])
      end

      def test_loads_skill_instructions
        result = LoadSkillTool.new(registry: @registry).execute(name: "writing-guide")

        assert result.ok?
        assert_includes result.output[:content], "## Skill: writing-guide"
        assert_includes result.output[:content], "Write clearly and concisely."
      end

      def test_unknown_skill_returns_failure_with_available_names
        result = LoadSkillTool.new(registry: @registry).execute(name: "nope")

        refute result.ok?
        assert_includes result.error_message, "writing-guide"
      end

      def test_nil_registry_reports_none_available
        result = LoadSkillTool.new(registry: nil).execute(name: "nope")

        refute result.ok?
        assert_includes result.error_message, "none"
      end

      def test_tool_name
        assert_equal "load_skill", LoadSkillTool.new(registry: @registry).name
      end
    end
  end
end
