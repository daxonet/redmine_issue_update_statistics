module RedmineIssueUpdateStatistics
  module Hooks
    class ViewIssuesShowDescriptionBottomHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom, partial: 'issues/reason'
      render_on :view_issues_bulk_edit_details_bottom, partial: 'issues/reason'
      render_on :view_layouts_base_html_head, partial: 'issue_update_statistics/agile_reason'
    end
  end
end