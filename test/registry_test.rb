# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class RegistryTest < Minitest::Test
      def setup
        @skill_a = Skill.new(name: "skill.a", description: "Skill A", instructions: "Do A", source: "a.md")
        @skill_b = Skill.new(name: "skill.b", description: "Skill B", instructions: "Do B", source: "b.md")
      end

      def test_empty_registry
        registry = Registry.new([])
        assert_equal({}, registry.skills)
        assert_equal [], registry.names
        assert_equal "", registry.format_for_prompt
      end

      def test_registry_with_skills
        source = stub(load: [@skill_a, @skill_b])
        registry = Registry.new([source])

        assert_equal 2, registry.skills.size
        assert_equal %w[skill.a skill.b], registry.names.sort
      end

      def test_lookup_by_name
        source = stub(load: [@skill_a])
        registry = Registry.new([source])

        assert_equal @skill_a, registry["skill.a"]
        assert_nil registry["nonexistent"]
      end

      def test_first_source_wins_priority
        override = Skill.new(name: "skill.a", description: "OVERRIDDEN", instructions: "Override", source: "override.md")
        source1 = stub(load: [override])
        source2 = stub(load: [@skill_a])

        registry = Registry.new([source1, source2])
        assert_equal "OVERRIDDEN", registry["skill.a"].description
      end

      def test_second_source_fills_gaps
        source1 = stub(load: [@skill_a])
        source2 = stub(load: [@skill_b])

        registry = Registry.new([source1, source2])
        assert_equal "Skill A", registry["skill.a"].description
        assert_equal "Skill B", registry["skill.b"].description
      end

      def test_skips_nil_skills
        source = stub(load: [@skill_a, nil, @skill_b])
        registry = Registry.new([source])

        assert_equal 2, registry.skills.size
      end

      def test_format_for_prompt
        source = stub(load: [@skill_a, @skill_b])
        registry = Registry.new([source])

        output = registry.format_for_prompt
        assert_match(/^$/, output)
        assert_match(/## Available Skills/, output)
        assert_match(/\*\*skill\.a\*\*: Skill A/, output)
        assert_match(/\*\*skill\.b\*\*: Skill B/, output)
        assert_match(/^$/, output)
      end
    end
  end
end
