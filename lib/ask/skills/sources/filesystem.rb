# frozen_string_literal: true

module Ask
  module Skills
    module Source
      class Filesystem < Base
        SIBLING_CATEGORIES = %w[references scripts assets].freeze

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

          # Separate known metadata from reserved fields
          reserved = %w[name description]
          metadata = frontmatter.reject { |k, _| reserved.include?(k) }

          # Discover sibling files
          skill_dir = File.dirname(path)
          siblings = discover_siblings(skill_dir)

          Skill.new(
            name: name,
            description: description,
            instructions: body,
            source: path,
            metadata: metadata,
            siblings: siblings
          )
        end

        # Scan the skill directory for sibling files and categorize them.
        def discover_siblings(skill_dir)
          siblings = {}
          return siblings unless File.directory?(skill_dir)

          Dir.entries(skill_dir).each do |entry|
            next if entry.start_with?(".")
            next if entry == "SKILL.md"
            entry_path = File.join(skill_dir, entry)

            if File.directory?(entry_path)
              # Categorized sibling directories
              category = entry
              files = Dir.children(entry_path)
                        .reject { |f| f.start_with?(".") }
                        .map { |f| File.join(entry, f) }
              siblings[category] = files if files.any?
            else
              # Individual files go into a general "files" category
              siblings["files"] ||= []
              siblings["files"] << entry
            end
          end

          siblings
        end

        def parse_frontmatter(content)
          return {} unless content.start_with?("---\n")
          end_idx = content.index("\n---\n", 4)
          return {} unless end_idx

          yaml_str = content[4...end_idx]
          yaml = {}
          current_key = nil
          current_value = nil

          yaml_str.split("\n").each do |line|
            if (m = line.match(/\A(\w[\w_]*):\s*(.*)\z/))
              # Store previous key if any
              if current_key
                yaml[current_key] = process_value(current_value.strip)
              end
              current_key = m[1]
              current_value = m[2].strip
            elsif current_key && line.match?(/\A\s+/)
              # Continuation of multi-line value (e.g. tags on next line)
              current_value << " #{line.strip}"
            end
          end

          # Store last key
          if current_key
            yaml[current_key] = process_value(current_value.strip)
          end

          yaml
        end

        def process_value(value)
          return value unless value
          # Remove surrounding quotes
          value = value.gsub(/\A"|"\z/, "").gsub(/\A'|'\z/, "")
          value
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
