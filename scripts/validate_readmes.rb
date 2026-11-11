#!/usr/bin/env ruby

require "uri"

ROOT = File.expand_path("..", __dir__)
CATEGORIES = [
  "Creational Patterns",
  "Structural Patterns",
  "Behavioral Patterns"
].freeze
EXPECTED_CATEGORY_COUNTS = {
  "Creational Patterns" => 5,
  "Structural Patterns" => 7,
  "Behavioral Patterns" => 11
}.freeze
REQUIRED_SECTIONS = [
  "At a glance",
  "The app problem",
  "Start with direct Swift",
  "The turning point",
  "Pattern intent",
  "Participants and responsibilities",
  "How the Swift implementation works",
  "Diagram",
  "Run the example",
  "Tests",
  "Trade-offs",
  "Alternatives",
  "When not to use it",
  "Source map",
  "Continue exploring"
].freeze
SUPPORTED_MERMAID = /\A(?:flowchart|graph|sequenceDiagram|stateDiagram(?:-v2)?|classDiagram)\b/

errors = []

def relative(path)
  path.delete_prefix("#{ROOT}/")
end

def hard_wrap_errors(path)
  failures = []
  in_code = false
  previous_plain = false

  File.readlines(path, chomp: true).each_with_index do |line, index|
    if line.start_with?("```")
      in_code = !in_code
      previous_plain = false
      next
    end
    next if in_code

    stripped = line.strip
    special = stripped.empty? ||
      stripped.start_with?("#", ">", "- ", "| ", "![", "<") ||
      stripped.match?(/^\d+\. /)
    plain = !special
    failures << "#{relative(path)}:#{index + 1} hard-wrapped prose" if plain && previous_plain
    previous_plain = plain
  end

  failures
end

canonical_guides = CATEGORIES.flat_map do |category|
  Dir.glob(File.join(ROOT, category, "*", "README.md"))
end.sort

errors << "Expected 23 canonical guides, found #{canonical_guides.count}" unless canonical_guides.count == 23

canonical_guides.each do |path|
  text = File.read(path)
  REQUIRED_SECTIONS.each do |section|
    errors << "#{relative(path)} missing section: #{section}" unless text.include?(section)
  end
  errors << "#{relative(path)} must contain exactly one normalized caption" unless text.scan(/^> \*\*Caption:\*\*/).count == 1
  errors << "#{relative(path)} must contain exactly one category navigation row" unless text.scan(/^\[← Pattern catalogue\]/).count == 1
  errors << "#{relative(path)} must contain exactly one At a glance section" unless text.scan(/^## ✨ At a glance$/).count == 1
  errors.concat(hard_wrap_errors(path))
end

CATEGORIES.each do |category|
  index_path = File.join(ROOT, category, "README.md")
  unless File.exist?(index_path)
    errors << "Missing category index: #{category}/README.md"
    next
  end

  expected_links = EXPECTED_CATEGORY_COUNTS.fetch(category)
  linked_guides = File.read(index_path)
    .scan(/\]\(([^)]+\/README\.md)\)/)
    .flatten
    .map { |target| target.split("#", 2).first }
    .select { |target| target.match?(/\A[^\/]+\/README\.md\z/) }
    .uniq
  errors << "#{category}/README.md expected #{expected_links} pattern links, found #{linked_guides.count}" unless linked_guides.count == expected_links
  errors.concat(hard_wrap_errors(index_path))
end

[File.join(ROOT, "README.md"), File.join(ROOT, "Documentation", "pattern-readme-template.md")].each do |path|
  errors.concat(hard_wrap_errors(path))
end

markdown_files = Dir.glob(File.join(ROOT, "**", "*.md"), File::FNM_DOTMATCH).reject do |path|
  path.include?("/.build/") || path.include?("/Editorial/")
end

local_target_count = 0
markdown_files.each do |path|
  text = File.read(path)
  text.scan(/!?\[[^\]]*\]\(([^)]+)\)/).flatten.each do |raw_target|
    target = raw_target.strip.sub(/\s+\"[^\"]*\"\z/, "")
    next if target.empty? || target.start_with?("#", "http://", "https://", "mailto:")
    next if target.include?("<pattern-directory>")
    next if relative(path) == "Documentation/pattern-readme-template.md" && (
      target.include?("[category]") ||
      target.start_with?("path/to/") ||
      target.start_with?("../../README.md#")
    )

    target = target[1...-1] if target.start_with?("<") && target.end_with?(">")
    decoded_path = URI.decode_www_form_component(target.split("#", 2).first)
    next if decoded_path.empty?

    local_target_count += 1
    resolved = File.expand_path(decoded_path, File.dirname(path))
    errors << "#{relative(path)} unresolved target: #{target}" unless File.exist?(resolved)
  end
end

mermaid_count = 0
markdown_files.each do |path|
  open_line = nil
  declaration = nil

  File.readlines(path, chomp: true).each_with_index do |line, index|
    if open_line
      if line.strip == "```"
        mermaid_count += 1
        unless declaration&.match?(SUPPORTED_MERMAID)
          errors << "#{relative(path)}:#{open_line} unsupported Mermaid declaration: #{declaration.inspect}"
        end
        open_line = nil
        declaration = nil
      elsif declaration.nil? && !line.strip.empty?
        declaration = line.strip
      end
    elsif line.strip == "```mermaid"
      open_line = index + 1
    end
  end

  errors << "#{relative(path)}:#{open_line} unclosed Mermaid fence" if open_line
end

unless errors.empty?
  warn errors.join("\n")
  exit 1
end

puts "README validation passed"
puts "  canonical guides: #{canonical_guides.count}"
puts "  category indexes: #{CATEGORIES.count}"
puts "  local targets: #{local_target_count}"
puts "  Mermaid blocks: #{mermaid_count}"
