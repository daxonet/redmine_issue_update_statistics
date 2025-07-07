module RedmineIssueUpdateStatistics
  module Hooks
    class ViewIssuesShowDescriptionBottomHook < Redmine::Hook::ViewListener
      def view_issues_show_description_bottom(context={})
        context[:controller].send(:render_to_string, {
          partial: 'issues/field_stats_table',
          locals: { issue: context[:issue], stats_data: context[:controller].instance_variable_get(:@stats_data) }
        })
      end
    end
  end
end