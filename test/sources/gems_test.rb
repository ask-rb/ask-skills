# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

module Ask
  module Skills
    module Source
      class GemsTest < Minitest::Test
        def setup
          @tmpdir = Dir.mktmpdir("ask_skills_gems_test")
          @gem_skills = File.join(@tmpdir, "gems", "lib", "ask", "skills")
          FileUtils.mkdir_p(File.join(@gem_skills, "gem.skill_a"))
          File.write(File.join(@gem_skills, "gem.skill_a", "SKILL.md"), <<~MD)
            ---
            name: gem.skill_a
            description: Skill from a gem
            ---

            Step 1: Use the gem feature.
          MD
          FileUtils.mkdir_p(File.join(@gem_skills, "gem.skill_b"))
          File.write(File.join(@gem_skills, "gem.skill_b", "SKILL.md"), <<~MD)
            ---
            name: gem.skill_b
            description: Another gem skill
            ---

            Step 1: Do the gem thing.
          MD
        end

        def teardown
          FileUtils.rm_rf(@tmpdir)
        end

        def test_discovers_skills_from_installed_gems
          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns(Dir[File.join(@gem_skills, "*", "SKILL.md")])

          source = Gems.new
          skills = source.load

          assert_equal 2, skills.size
          names = skills.map(&:name).sort
          assert_equal %w[gem.skill_a gem.skill_b], names
        end

        def test_returns_empty_when_no_gem_skills
          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([])

          source = Gems.new
          skills = source.load

          assert_equal [], skills
        end

        def test_parses_skill_frontmatter
          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([File.join(@gem_skills, "gem.skill_a", "SKILL.md")])

          source = Gems.new
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "gem.skill_a", skills.first.name
          assert_equal "Skill from a gem", skills.first.description
          assert_includes skills.first.instructions, "Use the gem feature"
        end

        def test_uses_dir_name_when_no_frontmatter_name
          FileUtils.mkdir_p(File.join(@gem_skills, "no_name_skill"))
          File.write(File.join(@gem_skills, "no_name_skill", "SKILL.md"), <<~MD)
            ---
            description: No name in frontmatter
            ---

            Instructions body.
          MD

          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([File.join(@gem_skills, "no_name_skill", "SKILL.md")])

          source = Gems.new
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "no_name_skill", skills.first.name
        end

        def test_skips_skill_with_empty_description
          FileUtils.mkdir_p(File.join(@gem_skills, "empty_desc"))
          File.write(File.join(@gem_skills, "empty_desc", "SKILL.md"), <<~MD)
            ---
            name: empty_desc
            description:
            ---

            Instructions.
          MD

          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([File.join(@gem_skills, "empty_desc", "SKILL.md")])

          source = Gems.new
          skills = source.load

          assert_equal 0, skills.size
        end

        def test_skips_skill_with_quoted_empty_description
          FileUtils.mkdir_p(File.join(@gem_skills, "quoted_empty"))
          File.write(File.join(@gem_skills, "quoted_empty", "SKILL.md"), <<~MD)
            ---
            name: quoted_empty
            description: ""
            ---

            Instructions.
          MD

          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([File.join(@gem_skills, "quoted_empty", "SKILL.md")])

          source = Gems.new
          skills = source.load

          assert_equal 0, skills.size
        end

        def test_sets_source_to_file_path
          file_path = File.join(@gem_skills, "gem.skill_a", "SKILL.md")
          Gem.expects(:find_files)
             .with(Gems::GLOB)
             .returns([file_path])

          source = Gems.new
          skills = source.load

          assert_equal file_path, skills.first.source
        end
      end
    end
  end
end
