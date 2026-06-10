# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

module Ask
  module Skills
    module Source
      class FilesystemTest < Minitest::Test
        def setup
          @tmpdir = Dir.mktmpdir("ask_skills_test")
        end

        def teardown
          FileUtils.rm_rf(@tmpdir)
        end

        def test_loads_skills_from_directory
          create_skill("my.skill", "My skill description", "Step 1: Do the thing")

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "my.skill", skills.first.name
          assert_equal "My skill description", skills.first.description
          assert_equal "Step 1: Do the thing", skills.first.instructions
        end

        def test_loads_multiple_skills
          create_skill("skill.one", "First", "Do one thing")
          create_skill("skill.two", "Second", "Do another thing")

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 2, skills.size
          names = skills.map(&:name).sort
          assert_equal %w[skill.one skill.two], names
        end

        def test_skips_directories_without_skill_md
          create_skill("valid.skill", "Valid", "Do valid things")
          FileUtils.mkdir_p(File.join(@tmpdir, "no_skill_here"))
          FileUtils.mkdir_p(File.join(@tmpdir, "empty_subdir"))
          File.write(File.join(@tmpdir, "empty_subdir", "README.md"), "No SKILL.md here")

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "valid.skill", skills.first.name
        end

        def test_skips_hidden_directories
          create_skill("visible", "Visible", "Do visible things")
          FileUtils.mkdir_p(File.join(@tmpdir, ".hidden"))
          File.write(File.join(@tmpdir, ".hidden", "SKILL.md"),
            "---\nname: hidden\ndescription: Hidden\n---\n\nBody")

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "visible", skills.first.name
        end

        def test_returns_empty_for_nonexistent_directory
          source = Filesystem.new(dir: "/nonexistent/path/12345")
          skills = source.load

          assert_equal [], skills
        end

        def test_returns_empty_for_empty_directory
          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal [], skills
        end

        def test_parses_yaml_frontmatter
          FileUtils.mkdir_p(File.join(@tmpdir, "test_skill"))
          File.write(File.join(@tmpdir, "test_skill", "SKILL.md"), <<~MD)
            ---
            name: test.skill
            description: A test skill
            version: 2
            ---

            Step 1: Test
            Step 2: Verify
          MD

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "test.skill", skills.first.name
          assert_equal "A test skill", skills.first.description
          assert_includes skills.first.instructions, "Step 1: Test"
          assert_includes skills.first.instructions, "Step 2: Verify"
        end

        def test_uses_dir_name_when_no_frontmatter_name
          FileUtils.mkdir_p(File.join(@tmpdir, "my_skill"))
          File.write(File.join(@tmpdir, "my_skill", "SKILL.md"), <<~MD)
            ---
            description: A skill without a name in frontmatter
            ---

            Instructions body.
          MD

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "my_skill", skills.first.name
        end

        def test_skips_skill_with_empty_description_in_yaml
          FileUtils.mkdir_p(File.join(@tmpdir, "no_desc"))
          File.write(File.join(@tmpdir, "no_desc", "SKILL.md"), <<~MD)
            ---
            name: no_desc
            description:
            ---

            Instructions.
          MD

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 0, skills.size
        end

        def test_skips_skill_with_quoted_empty_description
          FileUtils.mkdir_p(File.join(@tmpdir, "quoted_empty"))
          File.write(File.join(@tmpdir, "quoted_empty", "SKILL.md"), <<~MD)
            ---
            name: quoted_empty
            description: ""
            ---

            Instructions.
          MD

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 0, skills.size
        end

        def test_skips_file_without_frontmatter_and_no_description
          # Files without frontmatter have no description and are skipped
          FileUtils.mkdir_p(File.join(@tmpdir, "plain_skill"))
          File.write(File.join(@tmpdir, "plain_skill", "SKILL.md"),
            "Just some markdown content\n\nNo frontmatter here.")

          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          assert_equal 0, skills.size
        end

        def test_returns_source_path
          create_skill("sourced_skill", "Sourced", "Instructions")
          source = Filesystem.new(dir: @tmpdir)
          skills = source.load

          expected_path = File.join(@tmpdir, "sourced_skill", "SKILL.md")
          assert_equal expected_path, skills.first.source
        end

        def test_project_dir_parameter
          create_skill("project.skill", "Project skill", "Do project stuff")

          source = Filesystem.new(project_dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "project.skill", skills.first.name
        end

        def test_user_dir_parameter
          create_skill("user.skill", "User skill", "Do user stuff")

          source = Filesystem.new(user_dir: @tmpdir)
          skills = source.load

          assert_equal 1, skills.size
          assert_equal "user.skill", skills.first.name
        end

        def test_dir_takes_precedence_over_project_dir
          dir_path = File.join(@tmpdir, "dir_source")
          project_path = File.join(@tmpdir, "project_source")
          FileUtils.mkdir_p(dir_path)
          FileUtils.mkdir_p(project_path)

          create_skill_in(dir_path, "from.dir", "Dir skill", "Dir content")
          create_skill_in(project_path, "from.project", "Project skill", "Project content")

          source = Filesystem.new(dir: dir_path, project_dir: project_path)
          skills = source.load
          names = skills.map(&:name)

          assert_includes names, "from.dir"
          refute_includes names, "from.project"
        end

        private

        def create_skill(name, description, body)
          create_skill_in(@tmpdir, name, description, body)
        end

        def create_skill_in(base_dir, name, description, body)
          skill_dir = File.join(base_dir, name)
          FileUtils.mkdir_p(skill_dir)
          File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
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
end
