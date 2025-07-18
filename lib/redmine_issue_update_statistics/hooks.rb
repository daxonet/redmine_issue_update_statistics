module RedmineIssueUpdateStatistics
  module Hooks
    class ViewIssuesShowDescriptionBottomHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom, partial: 'issues/reason'
      render_on :view_issues_bulk_edit_details_bottom, partial: 'issues/reason'
    end
  end
end