# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'pathname'
require 'open3'
require 'rbconfig'

class InstallerTest < Minitest::Test
  ROOT = Pathname.new(__dir__).parent.realpath
  INSTRUCTIONS = %w[.pi/agent/AGENTS.md .codex/AGENTS.md .claude/CLAUDE.md .config/amp/AGENTS.md].freeze

  def with_home
    Dir.mktmpdir('skills-test') { |dir| yield Pathname.new(dir) }
  end

  def install(home)
    Open3.capture3(RbConfig.ruby, ROOT.join('scripts/install.rb').to_s, '--home', home.to_s)
  end

  def write(path, content)
    path.dirname.mkpath
    path.write(content)
  end

  def test_install_preserves_instructions_and_is_idempotent
    with_home do |home|
      existing = home.join('.claude/CLAUDE.md')
      write(existing, "Keep my existing rules.\n")
      _, stderr, status = install(home)
      assert status.success?, stderr
      INSTRUCTIONS.each do |relative|
        text = home.join(relative).read
        assert_includes text, '# Test Behavior, Not Implementation'
        refute_includes text, '# Design red flags'
        refute_includes text, 'description:'
      end
      first = existing.read
      assert first.start_with?("Keep my existing rules.\n")
      backup = Pathname.new("#{existing}.pre-agent-kit.bak")
      assert_equal "Keep my existing rules.\n", backup.read
      ROOT.glob('skills/*/SKILL.md').each do |skill|
        %w[.agents/skills .claude/skills].each do |folder|
          assert_equal skill.parent.realpath, home.join(folder, skill.parent.basename).realpath
        end
      end
      stdout, stderr, status = install(home)
      assert status.success?, stderr
      assert_equal first, existing.read
      assert_equal "Keep my existing rules.\n", backup.read
      refute_includes stdout, 'Updated'
    end
  end

  def test_directory_conflict_changes_nothing
    with_home do |home|
      conflict = home.join('.agents/skills/design-red-flags/mine.txt')
      write(conflict, 'keep')
      _, stderr, status = install(home)
      refute status.success?
      assert_includes stderr, 'Conflict:'
      assert_equal 'keep', conflict.read
      refute home.join('.claude').exist?
      refute home.join('.pi').exist?
    end
  end

  def test_broken_symlink_conflict_is_preserved
    with_home do |home|
      link = home.join('.claude/skills/design-red-flags')
      link.dirname.mkpath
      link.make_symlink('/nonexistent/other-skills')
      _, stderr, status = install(home)
      refute status.success?
      assert_includes stderr, 'Conflict:'
      assert_equal '/nonexistent/other-skills', link.readlink.to_s
      refute home.join('.agents').exist?
    end
  end

  def test_existing_override_takes_precedence
    with_home do |home|
      override = home.join('.codex/AGENTS.override.md')
      write(override, "Override rules.\n")
      _, stderr, status = install(home)
      assert status.success?, stderr
      assert override.read.start_with?("Override rules.\n")
      assert_includes override.read, '# Test Behavior, Not Implementation'
      refute home.join('.codex/AGENTS.md').exist?
    end
  end

  def test_replaces_legacy_block_without_changing_surrounding_text
    with_home do |home|
      dest = home.join('.pi/agent/AGENTS.md')
      write(dest, "Before\n<!-- agent-kit:begin -->\nStale guidance\n<!-- agent-kit:end -->\nAfter\n")
      _, stderr, status = install(home)
      assert status.success?, stderr
      assert dest.read.start_with?("Before\n")
      assert dest.read.end_with?("\nAfter\n")
      refute_includes dest.read, 'Stale guidance'
      assert_includes dest.read, '# Test Behavior, Not Implementation'
    end
  end

  def test_malformed_blocks_change_nothing
    ['<!-- agent-kit:begin -->',
     '<!-- agent-kit:end --><!-- agent-kit:begin -->',
     '<!-- agent-kit:begin --><!-- agent-kit:begin --><!-- agent-kit:end -->'].each do |text|
      with_home do |home|
        dest = home.join('.claude/CLAUDE.md')
        write(dest, text)
        _, stderr, status = install(home)
        refute status.success?
        assert_includes stderr, 'Malformed managed block'
        assert_equal text, dest.read
        refute home.join('.agents').exist?
      end
    end
  end
end
