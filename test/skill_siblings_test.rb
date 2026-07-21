# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

class SkillSiblingsTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("ask_skills_siblings")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def create_skill(name, description: "A test skill", body: "Do the thing", tags: nil)
    skill_dir = File.join(@tmpdir, name)
    FileUtils.mkdir_p(skill_dir)
    frontmatter = "---\nname: #{name}\ndescription: #{description}\n"
    frontmatter << "tags: #{tags}\n" if tags
    frontmatter << "---\n\n"
    File.write(File.join(skill_dir, "SKILL.md"), frontmatter + body)
    skill_dir
  end

  def create_sibling(skill_name, category, file_name, content = "content")
    path = File.join(@tmpdir, skill_name, category, file_name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  # -- Enhanced frontmatter --

  def test_parses_tags_from_frontmatter
    create_skill("my_skill", tags: "rails, database, debugging")
    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_equal 1, skills.length
    assert_equal %w[rails database debugging], skills.first.tags
  end

  def test_no_tags_returns_empty
    create_skill("my_skill")
    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_empty skills.first.tags
  end

  def test_tags_without_frontmatter_name
    FileUtils.mkdir_p(File.join(@tmpdir, "tagged_skill"))
    File.write(File.join(@tmpdir, "tagged_skill", "SKILL.md"), <<~MD)
      ---
      description: A tagged skill
      tags: deploy, automation
      ---

      Body
    MD
    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_equal %w[deploy automation], skills.first.tags
  end

  def test_metadata_preserves_all_frontmatter
    FileUtils.mkdir_p(File.join(@tmpdir, "meta_skill"))
    File.write(File.join(@tmpdir, "meta_skill", "SKILL.md"), <<~MD)
      ---
      name: meta_skill
      description: Skill with metadata
      tags: test, example
      version: "2"
      author: Test Author
      ---

      Body
    MD
    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    meta = skills.first.metadata
    assert_equal "test, example", meta["tags"]
    assert_equal "2", meta["version"]
    assert_equal "Test Author", meta["author"]
  end

  # -- Sibling files --

  def test_discovers_references_siblings
    create_skill("my_skill")
    create_sibling("my_skill", "references", "api_guide.md")
    create_sibling("my_skill", "references", "migration.md")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_equal ["references/api_guide.md", "references/migration.md"],
                 skills.first.references.sort
  end

  def test_discovers_scripts_siblings
    create_skill("my_skill")
    create_sibling("my_skill", "scripts", "setup.sh")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_equal ["scripts/setup.sh"], skills.first.scripts
  end

  def test_discovers_assets_siblings
    create_skill("my_skill")
    create_sibling("my_skill", "assets", "diagram.png")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_equal ["assets/diagram.png"], skills.first.assets
  end

  def test_discovers_all_sibling_categories
    create_skill("my_skill")
    create_sibling("my_skill", "references", "doc.md")
    create_sibling("my_skill", "scripts", "run.sh")
    create_sibling("my_skill", "assets", "logo.png")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    siblings = skills.first.siblings
    assert siblings.key?("references")
    assert siblings.key?("scripts")
    assert siblings.key?("assets")
  end

  def test_skips_hidden_sibling_files
    create_skill("my_skill")
    create_sibling("my_skill", "references", ".hidden_doc.md")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_empty skills.first.references
  end

  def test_siblings_returns_empty_when_none
    create_skill("my_skill")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    assert_empty skills.first.siblings
  end

  def test_flat_files_in_skill_dir
    create_skill("my_skill")
    create_sibling("my_skill", ".", "CHECKLIST.txt")
    create_sibling("my_skill", ".", "NOTES.md")

    source = Ask::Skills::Source::Filesystem.new(dir: @tmpdir)
    skills = source.load
    siblings = skills.first.siblings
    assert siblings.key?("files")
    assert_includes siblings["files"], "CHECKLIST.txt"
    assert_includes siblings["files"], "NOTES.md"
  end

  def test_load_file_does_not_discover_siblings
    # load_file loads a single .md file, not a directory
    # So it shouldn't have sibling discovery
    path = File.join(@tmpdir, "standalone.md")
    File.write(path, "---\nname: standalone\ndescription: A lone skill\n---\n\nBody")
    skill = Ask::Skills.load_file(path)
    assert_empty skill.siblings
    assert_empty skill.tags
  end

  # -- Skill data object --

  def test_skill_data_with_defaults
    skill = Ask::Skills::Skill.new(
      name: "test",
      description: "Test description",
      instructions: "Do stuff",
      source: "/path/to/SKILL.md"
    )
    assert_equal ({}), skill.metadata
    assert_equal ({}), skill.siblings
    assert_empty skill.tags
    assert_empty skill.references
  end

  def test_skill_to_prompt_entry
    skill = Ask::Skills::Skill.new(
      name: "deploy",
      description: "Deploy the app",
      instructions: "Steps",
      source: "/path"
    )
    assert_includes skill.to_prompt_entry, "deploy"
    assert_includes skill.to_prompt_entry, "Deploy the app"
  end

  def test_skill_tags_method
    skill = Ask::Skills::Skill.new(
      name: "test",
      description: "Test",
      instructions: "Body",
      source: "/path",
      metadata: { "tags" => "rails, database" }
    )
    assert_equal %w[rails database], skill.tags
  end

  # -- Formatter --

  def test_xml_formatter_includes_tags
    skill = Ask::Skills::Skill.new(
      name: "tagged",
      description: "Has tags",
      instructions: "Body",
      source: "/path",
      metadata: { "tags" => "rails, db" }
    )
    formatter = Ask::Skills::Formatter.new({ "tagged" => skill })
    xml = formatter.to_xml
    assert_includes xml, "<tags>rails, db</tags>"
  end

  def test_xml_formatter_includes_siblings
    skill = Ask::Skills::Skill.new(
      name: "with_siblings",
      description: "Has siblings",
      instructions: "Body",
      source: "/path",
      siblings: { "references" => ["references/doc.md"], "scripts" => ["scripts/run.sh"] }
    )
    formatter = Ask::Skills::Formatter.new({ "with_siblings" => skill })
    xml = formatter.to_xml
    assert_includes xml, "<references>"
    assert_includes xml, "references/doc.md"
    assert_includes xml, "<scripts>"
  end

  def test_xml_formatter_skips_empty_siblings
    skill = Ask::Skills::Skill.new(
      name: "bare",
      description: "No siblings",
      instructions: "Body",
      source: "/path"
    )
    formatter = Ask::Skills::Formatter.new({ "bare" => skill })
    xml = formatter.to_xml
    refute_includes xml, "<siblings>"
  end
end
