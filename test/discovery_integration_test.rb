# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

module Ask
  module Skills
    class DiscoveryIntegrationTest < Minitest::Test
      def setup
        @tmpdir = Dir.mktmpdir("ask_skills_integration")
        @orig_pwd = Dir.pwd
        Dir.chdir(@tmpdir)
      end

      def teardown
        Dir.chdir(@orig_pwd)
        FileUtils.rm_rf(@tmpdir)
      end

      def test_discovers_shared_skills_from_agents_shared_skills
        create_skill("agents/shared/skills/rails_debug", "rails_debug", "Debugging Rails apps", "Debug methodology")
        registry = Ask::Skills.discover
        assert registry["rails_debug"], "Should discover from agents/shared/skills/"
        assert_equal "Debugging Rails apps", registry["rails_debug"].description
      end

      def test_discovers_shared_skills_from_app_agents_shared_skills
        create_skill("app/agents/shared/skills/deploy_bot", "deploy_bot", "How to deploy", "Deploy steps")
        registry = Ask::Skills.discover
        assert registry["deploy_bot"], "Should discover from app/agents/shared/skills/"
      end

      def test_legacy_dot_agents_skills_still_works
        create_skill(".agents/skills/legacy_skill", "legacy_skill", "Old skill", "Backward compat content")
        registry = Ask::Skills.discover
        assert registry["legacy_skill"], "Should discover from .agents/skills/ (backward compat)"
      end

      def test_per_agent_skills_via_agent_dir
        create_skill("agents/health_check/skills/nginx_debug", "nginx_debug", "Debug Nginx", "Nginx debugging steps")
        registry = Ask::Skills.discover(agent_dir: "agents/health_check")
        assert registry["nginx_debug"], "Should discover per-agent skills"
      end

      def test_per_agent_skills_have_highest_priority
        create_skill("agents/shared/skills/debug", "debug", "Generic", "Generic debug content")
        create_skill("agents/health_check/skills/debug", "debug", "Specific health debug", "Specific debug content")
        registry = Ask::Skills.discover(agent_dir: "agents/health_check")
        assert registry["debug"]
        assert_includes registry["debug"].description, "Specific"
      end

      def test_shared_skills_override_legacy
        create_skill("agents/shared/skills/database", "database", "Shared DB skill", "Shared content")
        create_skill(".agents/skills/database", "database", "Legacy DB skill", "Legacy content")
        registry = Ask::Skills.discover
        assert registry["database"]
        assert_includes registry["database"].description, "Shared DB"
      end

      def test_multiple_shared_skill_paths
        create_skill("agents/shared/skills/skill_a", "skill_a", "First skill", "Content A")
        create_skill("app/agents/shared/skills/skill_b", "skill_b", "Second skill", "Content B")
        registry = Ask::Skills.discover
        assert registry["skill_a"]
        assert registry["skill_b"]
      end

      def test_discover_without_agent_dir_still_finds_shared
        create_skill("agents/shared/skills/shared_only", "shared_only", "Shared skill", "Found")
        create_skill("agents/health_check/skills/per_agent", "per_agent", "Per-agent skill", "Not found without dir")
        registry = Ask::Skills.discover
        assert registry["shared_only"]
        assert_nil registry["per_agent"], "Per-agent skills should not be found without agent_dir"
      end

      def test_ask_skills_discover_default_sources
        sources = Ask::Skills.send(:build_source_list)
        paths = sources.select { |s| s.is_a?(Ask::Skills::Source::Filesystem) }.map { |s| s.instance_variable_get(:@path) }
        assert paths.any? { |p| p&.end_with?("agents/shared/skills") },
               "Should include agents/shared/skills/"
        assert paths.any? { |p| p&.end_with?("app/agents/shared/skills") },
               "Should include app/agents/shared/skills/"
        assert paths.any? { |p| p&.end_with?(".agents/skills") },
               "Should include legacy .agents/skills/"
      end

      def test_build_source_list_includes_per_agent_when_given
        sources = Ask::Skills.send(:build_source_list, agent_dir: "agents/my_bot")
        filesystem_sources = sources.select { |s| s.is_a?(Ask::Skills::Source::Filesystem) }
        paths = filesystem_sources.map { |s| s.instance_variable_get(:@path) }
        assert paths.any? { |p| p&.end_with?("agents/my_bot/skills") },
               "Should include per-agent skills directory"
      end

      private

      def create_skill(rel_path, name, description, body)
        dir = File.join(@tmpdir, rel_path)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "SKILL.md"), <<~MD)
          ---
          name: #{name}
          description: #{description}
          ---

          #{body}
        MD
      end
    end
  end
end
