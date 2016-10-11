# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'mr_bump/version'
require 'mr_bump/slack'
require 'mr_bump/config'
require 'mr_bump/git_config'
require 'mr_bump/change'

# Add helper functions to the MrBump namespace
module MrBump
  def self.current_branch
    @current_branch ||= `git rev-parse --abbrev-ref HEAD`
    @current_branch.strip
  end

  def self.release_branch_regex
    prefix = Regexp.escape(config_file['release_prefix'])
    suffix = Regexp.escape(config_file['release_suffix'])
    "#{prefix}(\\d+\\.\\d+)(\\.\\d+)?#{suffix}"
  end

  def self.on_release_branch?
    regex = Regexp.new("^#{release_branch_regex}$")
    !MrBump.current_branch[regex].nil?
  end

  def self.on_master_branch?
    !MrBump.current_branch[/^master$/].nil?
  end

  def self.latest_release_from_list(branches)
    regex = Regexp.new("^origin/#{release_branch_regex}$")
    branches.map do |branch|
      matches = regex.match(branch)
      MrBump::Version.new(matches[1]) if matches
    end.compact.max || MrBump::Version.new('0.0.0')
  end

  def self.current_uat_major
    branches = `git branch -r`.each_line.map(&:strip)
    latest_release_from_list(branches)
  end

  def self.uat_branch
    config = MrBump.config_file
    "#{config['release_prefix']}#{current_uat_major}#{config['release_suffix']}"
  end

  def self.all_tags
    `git tag -l`.each_line.map(&:strip)
  end

  def self.all_tagged_versions
    all_tags.map do |tag|
      begin
        MrBump::Version.new(tag)
      rescue
        nil
      end
    end.compact
  end

  def self.current_uat
    uat = current_uat_major
    all_tagged_versions.select { |ver| ver.major == uat.major && ver.minor == uat.minor }.max
  end

  def self.current_master
    uat = current_uat_major
    all_tagged_versions.select { |ver| ver < uat }.max
  end

  def self.merge_logs(rev, head)
    git_cmd = "git log --pretty='format:%B' --grep " \
              "'(^Merge pull request | into #{current_branch}$)' --merges -E"
    log = `#{git_cmd} #{rev}..#{head}`
    log.each_line.map(&:strip).select { |str| !(str.nil? || str == '' || str[0] == '#') }
  end

  def self.ignored_merges_regex
    @ignored_merges_regex ||= begin
      ignored_branch = '(release|master|develop)'
      regex_pr = "^Merge pull request #\\d+ from Intellection/#{ignored_branch}"
      regex_manual = "^Merge branch '?#{ignored_branch}"
      Regexp.new("#{regex_pr}|#{regex_manual}")
    end
  end

  def self.change_log_items_for_range(rev, head)
    ignored_branch = Regexp.new("^(#{release_branch_regex}|master|develop)$")
    make_change = lambda do |title, comment = []|
      change = MrBump::Change.new(config_file, title, comment)
      change unless ignored_branch.match(change.branch_name)
    end

    chunked_log = merge_logs(rev, head).chunk { |change| change[/^Merge/].nil? }
    chunked_log.each_slice(2).map do |merge_str, comment|
      begin
        no_comment_changes = merge_str[1][0..-2].map(&make_change)
        commented_changes = make_change.call(merge_str[1][-1], comment[1])
        no_comment_changes.push(commented_changes)
      rescue ArgumentError => e
        puts e
      end
    end.flatten.compact
  end

  def self.file_prepend(file, str)
    new_contents = ''
    File.open(file, 'r') do |fd|
      contents = fd.read
      new_contents = str + contents
    end
    File.open(file, 'w') do |fd|
      fd.write(new_contents)
    end
  end

  def self.config_file
    @config_file ||= MrBump::Config.new.config
  end

  def self.slack_notifier(version, changelog)
    if config_file.key? 'slack'
      MrBump::Slack.new(git_config, config_file['slack']).bump(version, changelog)
    end
  end

  def self.git_config
    @git_config ||= MrBump::GitConfig.from_current_path
  end
end
