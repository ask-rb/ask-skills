module Ask
  module Skills
    module Source
      class Filesystem < Base
        def initialize(dir: nil, project_dir: nil, user_dir: nil)
          @path = dir || project_dir || (user_dir ? File.expand_path(user_dir) : nil)
        end

        def load
          return [] unless @path && Dir.exist?(@path)
          skills = []
          Dir.entries(@path).each do |entry|
            next if entry.start_with?(".")
            skill_dir = File.join(@path, entry)
            next unless File.directory?(skill_dir)
            skill_file = File.join(skill_dir, "SKILL.md")
            next unless File.exist?(skill_file)
            next if File.directory?(skill_file)
            if (skill = parse_skill(skill_file))
              skills << skill
            end
          end
          skills
        end

        private

        def parse_skill(path)
          content = File.read(path)
          frontmatter = parse_frontmatter(content)
          body = extract_body(content)

          name = frontmatter["name"] || File.basename(File.dirname(path))
          description = frontmatter["description"] || ""

          return nil if description.empty?

          Skill.new(name: name, description: description, instructions: body, source: path)
        end

        def parse_frontmatter(content)
          return {} unless content.start_with?("---\n")
          end_idx = content.index("\n---\n", 4)
          return {} unless end_idx
          yaml_str = content[4...end_idx]
          yaml = {}
          yaml_str.split("\n").each do |line|
            if (m = line.match(/\A(\w+):\s*(.+)\z/))
              value = m[2].strip
              value = value.gsub(/\A"|"\z/, "").gsub(/\A'|'\z/, "")
              yaml[m[1]] = value
            end
          end
          yaml
        end

        def extract_body(content)
          return content unless content.start_with?("---\n")
          end_idx = content.index("\n---\n", 4)
          return content unless end_idx
          body = content[(end_idx + 5)..] || ""
          body.sub(/\A\n/, "").strip
        end
      end
    end
  end
end
