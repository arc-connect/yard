require 'date'
require 'rake/file_utils'

namespace :release do
  module ReleaseTagHelpers
    extend self
    include Rake::FileUtilsExt

    VERSION_FILE = File.expand_path('../lib/yard/version.rb', __dir__)
    CHANGELOG_FILE = File.expand_path('../CHANGELOG.md', __dir__)

    def release_version!
      version = ENV['VERSION'].to_s.strip
      raise 'VERSION=X.Y.Z is required' if version.empty?

      tag_name = "v#{version}"
      raise "Git tag #{tag_name} already exists" if tag_exists?(tag_name)

      ensure_clean_worktree!

      previous_version = current_version
      update_version_file(version)
      rotate_changelog(previous_version, version, Date.today)

      sh('git', 'add', VERSION_FILE, CHANGELOG_FILE)
      sh('npx', 'vpr', 'release-commit', version)
      sh('git', '--no-pager', 'show')
    end

    def current_version
      contents = File.read(VERSION_FILE)
      match = contents.match(/VERSION = ['"](.+?)['"]/)
      raise "Could not find VERSION in #{VERSION_FILE}" unless match

      match[1]
    end

    def update_version_file(version)
      contents = File.read(VERSION_FILE)
      updated = contents.sub(/VERSION = ['"](.+?)['"]/, "VERSION = '#{version}'")
      raise "Could not update VERSION in #{VERSION_FILE}" if updated == contents

      File.write(VERSION_FILE, updated)
    end

    def rotate_changelog(previous_version, version, date)
      contents = File.read(CHANGELOG_FILE)
      match = contents.match(/\A# main\n+(?<entries>.*?)(?=^# \[[^\]]+\] - )/m)
      raise "Could not find '# main' release entries in #{CHANGELOG_FILE}" unless match

      entries = match[:entries].strip
      raise "No unreleased entries found under '# main' in #{CHANGELOG_FILE}" if entries.empty?

      release_heading = "# [#{version}] - #{format_release_date(date)}"
      compare_link = "[#{version}]: https://github.com/lsegal/yard/compare/v#{previous_version}...v#{version}"
      replacement = [
        '# main',
        '',
        release_heading,
        '',
        compare_link,
        '',
        entries,
        '',
        ''
      ].join("\n")

      File.write(CHANGELOG_FILE, contents.sub(match[0], replacement))
    end

    def format_release_date(date)
      "#{date.strftime('%B')} #{date.day}#{ordinal_suffix(date.day)}, #{date.year}"
    end

    def ordinal_suffix(day)
      return 'th' if (11..13).cover?(day % 100)

      { 1 => 'st', 2 => 'nd', 3 => 'rd' }.fetch(day % 10, 'th')
    end

    def ensure_clean_worktree!
      status = `git status --porcelain`
      raise 'Git worktree must be clean before tagging' unless status.strip.empty?
    end

    def tag_exists?(tag_name)
      system('git', 'rev-parse', '--verify', '--quiet', tag_name, out: File::NULL, err: File::NULL)
    end
  end

  desc 'Updates version/changelog, commits the release, and tags VERSION=X.Y.Z'
  task :tag do
    ReleaseTagHelpers.release_version!

    version = ENV['VERSION'].to_s.strip
    puts
    puts "Tag v#{version} created. To publish, type the following:"
    puts
    puts "  bundle exec rake release:push VERSION=#{version}"
  end

  desc 'Pushes the main branch and tag for VERSION=X.Y.Z'
  task :push do
    sh "git push origin main v#{ENV['VERSION']}"
  end
end
