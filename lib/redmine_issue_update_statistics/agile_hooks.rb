module RedmineIssueUpdateStatistics
  # Use Agile's public hook so its controller and commercial source stay intact.
  class AgileHooks < Redmine::Hook::Listener
    def controller_agile_boards_update_before_save(context = {})
      issue = context[:issue]
      params = context[:params]
      return unless issue && params

      reason = params[:reason].presence || params.dig(:issue, :reason).presence
      return if reason.blank?

      issue.update_reason = reason
      issue.current_journal.reason = reason if issue.current_journal
    end
  end
end
