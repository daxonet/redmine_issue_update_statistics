module RedmineIssueUpdateStatistics
    module IssuesHelperPatch
        def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
            alias_method :issue_history_tabs_without_update_satisitics, :issue_history_tabs
            alias_method :issue_history_tabs, :issue_history_tabs_with_update_satisitics
        end
        end

        module InstanceMethods

        def issue_history_tabs_with_update_satisitics
            tabs = issue_history_tabs_without_update_satisitics
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
end

 IssuesHelper.send(:include, RedmineIssueUpdateStatistics::IssuesHelperPatch)

