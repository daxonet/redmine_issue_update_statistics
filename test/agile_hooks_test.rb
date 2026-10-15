# Run with Redmine's bundle: bundle exec ruby plugins/redmine_issue_update_statistics/test/agile_hooks_test.rb
require 'minitest/autorun'
require 'ostruct'
require 'active_support/core_ext/object/blank'

module Redmine
  module Hook
    class Listener; end
  end
end
require_relative '../lib/redmine_issue_update_statistics/agile_hooks'

class AgileHooksTest < Minitest::Test
  def setup
    @hook = RedmineIssueUpdateStatistics::AgileHooks.new
    @journal = OpenStruct.new(reason: nil)
    @issue = OpenStruct.new(current_journal: @journal, update_reason: nil)
  end

  def test_attaches_reason_to_validation_and_current_journal
    @hook.controller_agile_boards_update_before_save(issue: @issue, params: {reason: '客户确认，开始实施'})
    assert_equal '客户确认，开始实施', @issue.update_reason
    assert_equal '客户确认，开始实施', @journal.reason
  end

  def test_accepts_nested_reason
    @hook.controller_agile_boards_update_before_save(issue: @issue, params: {issue: {reason: 'Reviewed'}})
    assert_equal 'Reviewed', @issue.update_reason
    assert_equal 'Reviewed', @journal.reason
  end

  def test_blank_outer_reason_does_not_hide_nested_reason
    @hook.controller_agile_boards_update_before_save(issue: @issue, params: {reason: '', issue: {reason: 'Reviewed'}})
    assert_equal 'Reviewed', @journal.reason
  end

  def test_does_not_invent_a_reason_or_bypass_validation
    [nil, '', '   '].each do |reason|
      @hook.controller_agile_boards_update_before_save(issue: @issue, params: {reason: reason})
      assert_nil @issue.update_reason
      assert_nil @journal.reason
    end
  end

  def test_missing_journal_does_not_crash
    @issue.current_journal = nil
    @hook.controller_agile_boards_update_before_save(issue: @issue, params: {reason: 'Reviewed'})
    assert_equal 'Reviewed', @issue.update_reason
  end

  def test_ignores_incomplete_hook_context
    assert_nil @hook.controller_agile_boards_update_before_save({})
    assert_nil @hook.controller_agile_boards_update_before_save(issue: @issue)
  end
end
