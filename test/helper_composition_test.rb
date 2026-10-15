# Run without a Redmine database: ruby test/helper_composition_test.rb
require 'minitest/autorun'

module IssuesHelper
  def issue_history_tabs = [{ name: 'history' }]
end

# A view may include the helper before the plugin is loaded.
View = Class.new do
  include IssuesHelper

  def initialize
    @issue = Object.new
  end

  def tab_issue_path(_issue, **_options) = '/issues/1/tab'
  def issue_path(_issue, **_options) = '/issues/1'
end

module OtherHistoryTabs
  def issue_history_tabs = super + [{ name: 'other_plugin' }]
end
IssuesHelper.prepend(OtherHistoryTabs)

require_relative '../lib/redmine_issue_update_statistics/issues_helper_patch'

class HelperCompositionTest < Minitest::Test
  def test_keeps_core_and_other_plugin_tabs_in_existing_views
    tabs = View.new.issue_history_tabs
    assert_equal %w[history other_plugin update_satisitics], tabs.map { |tab| tab[:name] }
    assert tabs.last[:remote]
  end

  def test_loading_the_patch_again_does_not_duplicate_tabs
    load File.expand_path('../lib/redmine_issue_update_statistics/issues_helper_patch.rb', __dir__)
    assert_equal 1, View.new.issue_history_tabs.count { |tab| tab[:name] == 'update_satisitics' }
  end
end
