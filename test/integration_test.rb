# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

module Ask
  module Skills
    class IntegrationTest < Minitest::Test
      def setup
        @tmpdir = Dir.mktmpdir("ask_skills_integration")
        @orig_dir = Dir.pwd
      end

      def teardown
        Dir.chdir(@orig_dir)
        FileUtils.rm_rf(@tmpdir)
      end

      def test_discover_returns_registry_with_builtin_skills
        registry = Ask::Skills.discover(sources: [
          Source::Filesystem.new(dir: Ask::Skills.builtin_skills_dir)
        ])

        assert_kind_of Registry, registry
        assert_includes registry.names, "skill.design"
        assert_includes registry.names, "skill.compose"
      end

      def test_full_discovery_pipeline
        # Build a test project structure
        project_skills = File.join(@tmpdir, ".agents", "skills", "project.custom")
        FileUtils.mkdir_p(project_skills)
        File.write(File.join(project_skills, "SKILL.md"), <<~MD)
          ---
          name: project.custom
          description: Project-specific customization skill
          ---

          Step 1: Customize the thing.
        MD

        Dir.chdir(@tmpdir) do
          registry = Ask::Skills.discover(sources: Ask::Skills.default_sources)
          refute_nil registry["project.custom"], "Project skill should be in registry"
          assert registry.names.include?("skill.design"), "Built-in skills should be in registry"
        end
      end

      def test_project_overrides_gem
        # Create a project-level override of a built-in skill
        project_skill_dir = File.join(@tmpdir, ".agents", "skills", "skill.design")
        FileUtils.mkdir_p(project_skill_dir)
        File.write(File.join(project_skill_dir, "SKILL.md"), <<~MD)
          ---
          name: skill.design
          description: Overridden project description for skill.design
          ---

          Project-level methodology.
        MD

        Dir.chdir(@tmpdir) do
          registry = Ask::Skills.discover(sources: Ask::Skills.default_sources)
          skill = registry["skill.design"]
          assert_equal "Overridden project description for skill.design", skill.description
        end
      end

      def test_discover_with_custom_sources
        custom_dir = File.join(@tmpdir, "custom")
        FileUtils.mkdir_p(File.join(custom_dir, "custom.skill"))
        File.write(File.join(custom_dir, "custom.skill", "SKILL.md"), <<~MD)
          ---
          name: custom.skill
          description: A custom skill
          ---

          Custom content.
        MD

        custom_source = Source::Filesystem.new(dir: custom_dir)
        registry = Ask::Skills.discover(sources: [custom_source])

        assert_equal 1, registry.names.size
        assert_equal "custom.skill", registry.names.first
      end

      def test_priority_first_source_wins
        # Two sources providing same skill name — first should win
        source1_dir = File.join(@tmpdir, "source1")
        FileUtils.mkdir_p(File.join(source1_dir, "dup.skill"))
        File.write(File.join(source1_dir, "dup.skill", "SKILL.md"), <<~MD)
          ---
          name: dup.skill
          description: FROM SOURCE 1
          ---

          Source 1 content.
        MD

        source2_dir = File.join(@tmpdir, "source2")
        FileUtils.mkdir_p(File.join(source2_dir, "dup.skill"))
        File.write(File.join(source2_dir, "dup.skill", "SKILL.md"), <<~MD)
          ---
          name: dup.skill
          description: FROM SOURCE 2
          ---

          Source 2 content.
        MD

        sources = [
          Source::Filesystem.new(dir: source1_dir),
          Source::Filesystem.new(dir: source2_dir),
        ]
        registry = Ask::Skills.discover(sources: sources)

        assert_equal "FROM SOURCE 1", registry["dup.skill"].description
      end

      def test_markdown_format_integration
        registry = Ask::Skills.discover(sources: [
          Source::Filesystem.new(dir: Ask::Skills.builtin_skills_dir)
        ])

        output = registry.format_for_prompt
        assert_match(/## Available Skills/, output)
        assert_match(/skill\.design/, output)
        assert_match(/skill\.compose/, output)
      end

      def test_xml_format_integration
        registry = Ask::Skills.discover(sources: [
          Source::Filesystem.new(dir: Ask::Skills.builtin_skills_dir)
        ])

        formatter = Formatter.new(registry)
        output = formatter.to_xml
        assert_includes output, "<available_skills>"
        assert_includes output, "skill.design"
        assert_includes output, "skill.compose"
      end
    end
  end
end
