module RedmineIssueUpdateStatistics
  module IssuesHelperPatch
    def issue_history_tabs
        tabs = super
        #if @issue.has_update_statistics_history?
        tabs << {
            :name => 'update_satisitics',
            :label => :property_changes_statistics,
            :remote => true,
            :onclick =>
                "getRemoteTab('update_satisitics', " \
                "'#{tab_issue_path(@issue, :name => 'update_satisitics')}', " \
                "'#{issue_path(@issue, :tab => 'update_satisitics')}')"
        }
        #end
        tabs
    end
  end
end

IssuesHelper.prepend(RedmineIssueUpdateStatistics::IssuesHelperPatch) unless IssuesHelper.ancestors.include?(RedmineIssueUpdateStatistics::IssuesHelperPatch)
