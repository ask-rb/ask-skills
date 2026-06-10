module Ask
  module Skills
    module Source
      class Gems < Base
        GLOB = "ask/skills/*/SKILL.md"

        def load
          skills = []
          Gem.find_files(GLOB).each do |path|
            if (skill = parse_skill(path))
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
            if line =~ /^(\w+):\s*(.+)$/
              yaml[$1] = $2.strip
            end
          end
          yaml
        end

        def extract_body(content)
          return content unless content.start_with?("---\n")
          end_idx = content.index("\n---\n", 4)
          return content unless end_idx
          content[(end_idx + 5)..] || ""
        end
      end
    end
  end
end
