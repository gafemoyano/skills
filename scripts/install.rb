#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'pathname'

# Keep the original markers and backup names compatible with existing installs.
module SkillsInstaller
  ROOT = Pathname.new(__FILE__).realpath.parent.parent
  START = '<!-- agent-kit:begin -->'
  FINISH = '<!-- agent-kit:end -->'
  INSTRUCTIONS = %w[.pi/agent/AGENTS.md .codex/AGENTS.md .claude/CLAUDE.md .config/amp/AGENTS.md].freeze

  def self.merge_instructions(old, block, path)
    if old.include?(START) || old.include?(FINISH)
      unless old.scan(START).size == 1 && old.scan(FINISH).size == 1 && old.index(START) < old.index(FINISH)
        raise ArgumentError, "Malformed managed block in #{path}; nothing changed."
      end
      old[0...old.index(START)] + block + old[(old.index(FINISH) + FINISH.length)..]
    else
      old + (old.empty? ? '' : "\n\n") + block + "\n"
    end
  end

  def self.install(home)
    skills = ROOT.glob('skills/*/SKILL.md').sort.map(&:parent)
    links = %w[.agents/skills .claude/skills].flat_map do |folder|
      skills.map { |skill| [home.join(folder, skill.basename), skill] }
    end
    links.each do |dest, source|
      next if dest.symlink? && dest.exist? && dest.realpath == source.realpath
      if dest.exist? || dest.symlink?
        raise ArgumentError, "Conflict: #{dest}; move it aside manually. Nothing changed."
      end
    end

    names = JSON.parse(ROOT.join('always-on.json').read)
    unless names.is_a?(Array) && names.all? { |name| name.is_a?(String) }
      raise ArgumentError, 'always-on.json must contain an array of skill names.'
    end
    sections = names.map do |name|
      skill = skills.find { |candidate| candidate.basename.to_s == name }
      raise ArgumentError, "Unknown always-on skill: #{name}" unless skill

      text = skill.join('SKILL.md').read
      if text.start_with?("---\n")
        match = text.match(/\A---\n.*?\n---(?:\n|\z)(.*)\z/m)
        raise ArgumentError, "Unclosed frontmatter in #{skill}/SKILL.md" unless match

        text = match[1]
      end
      text.strip
    end
    block = "#{START}\n\n#{sections.join("\n\n")}\n\n#{FINISH}"
    updates = INSTRUCTIONS.map do |relative|
      dest = home.join(relative)
      override = dest.dirname.join('AGENTS.override.md')
      dest = override if dest.basename.to_s == 'AGENTS.md' && override.exist?
      old = dest.exist? ? dest.read : ''
      [dest, old, merge_instructions(old, block, dest)]
    end

    # Finish preflight checks before changing any files or links.
    links.each do |dest, source|
      next if dest.symlink?

      dest.dirname.mkpath
      dest.make_symlink(source)
      puts "Linked #{dest} -> #{source}"
    end
    updates.each do |dest, old, updated|
      next if old == updated

      dest.dirname.mkpath
      backup = Pathname.new("#{dest}.pre-agent-kit.bak")
      backup.write(old) if dest.exist? && !backup.exist?
      dest.write(updated)
      puts "Updated #{dest}"
    end
    puts 'Installed. Reload/restart agents to discover changes.'
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    home = Dir.home
    parser = OptionParser.new do |options|
      options.banner = 'Usage: ruby scripts/install.rb [--home DIRECTORY]'
      options.on('--home DIRECTORY', 'Alternate home directory (for testing)') { |value| home = value }
      options.on('-h', '--help', 'Show help') { puts options; exit }
    end
    parser.parse!
    raise OptionParser::InvalidArgument, ARGV.join(' ') unless ARGV.empty?

    SkillsInstaller.install(Pathname.new(File.expand_path(home)))
  rescue ArgumentError, JSON::ParserError, SystemCallError, OptionParser::ParseError => e
    abort e.message
  end
end
