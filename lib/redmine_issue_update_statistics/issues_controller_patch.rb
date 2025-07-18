require_dependency 'issues_controller'

module RedmineIssueUpdateStatistics
  module IssuesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        
        alias_method :update_issue_from_params_without_update_satisitics, :update_issue_from_params
        alias_method :update_issue_from_params, :update_issue_from_params_with_update_satisitics

        alias_method :issue_tab_without_update_satisitics, :issue_tab
        alias_method :issue_tab, :issue_tab_with_update_satisitics
      end
    end
    
    include ActionView::Helpers::DateHelper

    module InstanceMethods
      
      def issue_tab_with_update_satisitics
        return render_error :status => 422 unless request.xhr?

        if params[:name] == 'update_satisitics'
          @stats_data = generate_field_stats(@issue)
          render :partial => 'issues/update_satisitics', :locals => {:stats_data => @stats_data}
        else
          issue_tab_without_update_satisitics
        end      
      end

      private

      def generate_field_stats(issue)
        stats = []
        tracked_fields = []

        Array(Setting.plugin_redmine_issue_update_statistics['core_fields']).each do |field|
          tracked_fields.push(field)
        end
        
        Array(Setting.plugin_redmine_issue_update_statistics['custom_fields']).each do |field|
          tracked_fields.push("custom_field_#{field}")
        end

        journals = issue.journals.includes(:details, :user).order(created_on: :asc)
        issue_created = issue.created_on
        total_lifetime = (Time.now - issue_created).to_f / (60 * 60 * 24) # Days
        total_lifetime = 1.0 if total_lifetime < 1.0 # Avoid division by zero

        tracked_fields.each do |field|
          field_name = field_name_for(field)
          current_value = issue.send(field) rescue issue.custom_field_values.detect { |cf| cf.custom_field.id.to_s == field.split('_').last }&.value
          last_change_time = issue_created
          last_reason = 'Initial value'
          has_journal = false
          journals.each do |journal|
            journal.details.each do |detail|
              next unless detail.prop_key == field || (field.start_with?('custom_field_') && "custom_field_#{detail.prop_key}" == field)
              
              current_reason = last_reason
              current_change_time = last_change_time

              last_change_time = journal.updated_on
              last_reason = journal.reason
              
              next if has_journal == false && detail.old_value.blank?

              has_journal = true
              stats << {
                field: field_name,
                value: format_value(field, detail.old_value, issue),
                reason: current_reason,
                modified_by: journal.user&.name || 'Unknown',
                modified_date: current_change_time,
                lasted_for: distance_of_time_in_words(0,(journal.updated_on - current_change_time), include_seconds: true),
                percentage: (((journal.updated_on - current_change_time) / (60 * 60 * 24)) / total_lifetime * 100).round(2)
              }
              
            end
          end

          next if has_journal == false && current_value.blank?
          stats << {
            field: field_name,
            value: format_value(field, current_value, issue),
            reason: last_reason,
            modified_by: journals.last&.user&.name || issue.author&.name || 'Unknown',
            modified_date: last_change_time,
            lasted_for: distance_of_time_in_words(0,(Time.now - last_change_time), include_seconds: true),
            percentage: (((Time.now - last_change_time) / (60 * 60 * 24)) / total_lifetime * 100).round(2)
          }


        end
        
        stats.sort_by {|obj| obj[:modified_date] }.reverse.sort_by {|obj| obj[:field] }
        
      end

      def field_name_for(field)
        if field.start_with?('custom_field_')
          CustomField.find_by(id: field.split('_').last)&.name || 'Unknown Custom Field'
        elsif field == 'status_id'
          'Status'
        elsif field == 'assigned_to_id'
          'Assignee'
        else
          field.humanize
        end
      end

      def format_value(field, value, issue)
        if field == 'status_id'
          IssueStatus.find_by(id: value)&.name || value
        elsif field == 'assigned_to_id'
          User.find_by(id: value)&.name || value
        elsif field.start_with?('custom_field_')
          value || 'None'
        else
          value || 'None'
        end
      end

      def update_issue_from_params_with_update_satisitics
        update_issue_from_params_without_update_satisitics
        @issue.current_journal.reason = params[:reason]
      end

    end
  end
end

IssuesController.send(:include, RedmineIssueUpdateStatistics::IssuesControllerPatch)