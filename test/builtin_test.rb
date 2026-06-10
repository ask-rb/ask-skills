# frozen_string_literal: true

require_relative "test_helper"

module Ask
  module Skills
    class BuiltinTest < Minitest::Test
      def setup
        @builtin_dir = Ask::Skills.builtin_skills_dir
      end

      def test_builtin_dir_exists
        assert Dir.exist?(@builtin_dir), "Built-in skills directory should exist"
      end

      def test_skill_design_exists
        skill_path = File.join(@builtin_dir, "skill.design", "SKILL.md")
        assert File.exist?(skill_path), "skill.design/SKILL.md should exist"
      end

      def test_skill_compose_exists
        skill_path = File.join(@builtin_dir, "skill.compose", "SKILL.md")
        assert File.exist?(skill_path), "skill.compose/SKILL.md should exist"
      end

      def test_skill_design_has_frontmatter
        content = File.read(File.join(@builtin_dir, "skill.design", "SKILL.md"))
        assert content.start_with?("---\n"), "skill.design should have frontmatter"
        assert_includes content, "name: skill.design"
        assert_includes content, "description: How to design and write effective skills"
      end

      def test_skill_compose_has_frontmatter
        content = File.read(File.join(@builtin_dir, "skill.compose", "SKILL.md"))
        assert content.start_with?("---\n"), "skill.compose should have frontmatter"
        assert_includes content, "name: skill.compose"
        assert_includes content, "description: How skills interact, combine, and resolve"
      end

      def test_skill_design_loads_via_discover
        source = Source::Filesystem.new(dir: @builtin_dir)
        skills = source.load
        skill = skills.find { |s| s.name == "skill.design" }

        refute_nil skill, "skill.design should load from builtin dir"
        assert skill.description.start_with?("How to design")
        refute_empty skill.instructions
      end

      def test_skill_compose_loads_via_discover
        source = Source::Filesystem.new(dir: @builtin_dir)
        skills = source.load
        skill = skills.find { |s| s.name == "skill.compose" }

        refute_nil skill, "skill.compose should load from builtin dir"
        assert skill.description.start_with?("How skills interact")
        refute_empty skill.instructions
      end

      def test_both_builtin_skills_valid
        source = Source::Filesystem.new(dir: @builtin_dir)
        skills = source.load
        errors = Validator.new(skills).validate_all

        assert_empty errors, "Built-in skills should be valid"
      end
    end
  end
end
