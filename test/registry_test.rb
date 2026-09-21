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

      # --- Deduplication tests ---

      def test_exact_duplicate_silently_deduplicated
        # Same name, description, instructions, different source — no warning
        local = Skill.new(name: "shell.patterns", description: "Shell patterns", instructions: "Body", source: "/local/shell.patterns/SKILL.md")
        gem = Skill.new(name: "shell.patterns", description: "Shell patterns", instructions: "Body", source: "/gems/shell.patterns/SKILL.md")

        source1 = stub(load: [local])
        source2 = stub(load: [gem])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_empty output, "Exact duplicates should be silently deduplicated"
        assert_equal 1, Registry.new([source1, source2]).skills.size
      end

      def test_differing_definition_warns_on_collision
        local = Skill.new(name: "shell.patterns", description: "Local description", instructions: "Local body", source: "/local/shell.patterns/SKILL.md")
        gem = Skill.new(name: "shell.patterns", description: "Gem description", instructions: "Gem body", source: "/gems/shell.patterns/SKILL.md")

        source1 = stub(load: [local])
        source2 = stub(load: [gem])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_includes output, "Collision"
        assert_includes output, "shell.patterns"
      end

      def test_same_description_different_instructions_warns
        a = Skill.new(name: "x", description: "Same desc", instructions: "Body A", source: "a.md")
        b = Skill.new(name: "x", description: "Same desc", instructions: "Body B", source: "b.md")

        source1 = stub(load: [a])
        source2 = stub(load: [b])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_includes output, "Collision"
      end

      def test_same_instructions_different_description_warns
        a = Skill.new(name: "x", description: "Desc A", instructions: "Same body", source: "a.md")
        b = Skill.new(name: "x", description: "Desc B", instructions: "Same body", source: "b.md")

        source1 = stub(load: [a])
        source2 = stub(load: [b])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_includes output, "Collision"
      end

      def test_three_sources_exact_dups_deduplicated
        skill = Skill.new(name: "shared", description: "Shared", instructions: "Body", source: "a.md")
        dup1 = Skill.new(name: "shared", description: "Shared", instructions: "Body", source: "b.md")
        dup2 = Skill.new(name: "shared", description: "Shared", instructions: "Body", source: "c.md")

        output = capture_warn do
          registry = Registry.new([stub(load: [skill]), stub(load: [dup1]), stub(load: [dup2])])
          assert_equal 1, registry.skills.size
        end
        assert_empty output
      end

      def test_first_wins_even_for_equivalent_dups
        first = Skill.new(name: "eq", description: "Desc", instructions: "Body", source: "first.md")
        second = Skill.new(name: "eq", description: "Desc", instructions: "Body", source: "second.md")

        registry = nil
        capture_warn { registry = Registry.new([stub(load: [first]), stub(load: [second])]) }
        assert_equal "first.md", registry["eq"].source
      end

      def test_same_gem_name_different_content_silently_deduplicated
        # Same skill name, different content, but both from ask-skills gem
        # (local sibling gem vs installed gem of the same name)
        local = Skill.new(name: "skill.compose", description: "Local compose", instructions: "Local body",
                          source: "/Users/dev/Code/ask-rb/ask-skills/lib/ask/skills/skill.compose/SKILL.md")
        gem = Skill.new(name: "skill.compose", description: "Gem compose", instructions: "Gem body",
                        source: "/Users/dev/.local/share/mise/installs/ruby/4.0.1/lib/ruby/gems/4.0.0/gems/ask-skills-0.5.1/lib/ask/skills/skill.compose/SKILL.md")

        source1 = stub(load: [local])
        source2 = stub(load: [gem])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_empty output, "Same gem name should silently deduplicate even with different content"
        assert_equal 1, Registry.new([source1, source2]).skills.size
        assert_equal "Local compose", Registry.new([source1, source2]).skills["skill.compose"].description
      end

      def test_different_gem_name_same_content_warns
        # Same skill name, different content, from genuinely different gems
        a = Skill.new(name: "shared_tool", description: "From gem A", instructions: "Body A",
                      source: "/gems/ask-tools-1.0/lib/ask/skills/shared_tool/SKILL.md")
        b = Skill.new(name: "shared_tool", description: "From gem B", instructions: "Body B",
                      source: "/gems/ask-other-2.0/lib/ask/skills/shared_tool/SKILL.md")

        source1 = stub(load: [a])
        source2 = stub(load: [b])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_includes output, "Collision"
        assert_includes output, "shared_tool"
      end

      def test_different_gem_name_different_content_warns
        a = Skill.new(name: "x", description: "Desc A", instructions: "Body A",
                      source: "/gems/ask-foo-1.0/lib/ask/skills/x/SKILL.md")
        b = Skill.new(name: "x", description: "Desc B", instructions: "Body B",
                      source: "/gems/ask-bar-2.0/lib/ask/skills/x/SKILL.md")

        source1 = stub(load: [a])
        source2 = stub(load: [b])

        output = capture_warn { Registry.new([source1, source2]) }
        assert_includes output, "Collision"
      end

      private

      def capture_warn
        old_stderr = $stderr
        $stderr = StringIO.new
        yield
        $stderr.string
      ensure
        $stderr = old_stderr
      end
    end
  end
end
