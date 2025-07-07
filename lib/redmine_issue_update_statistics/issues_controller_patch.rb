require_dependency 'issues_controller'

module RedmineIssueUpdateStatistics
  module IssuesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        before_action :prepare_field_stats, only: [:show]
      end
    end
    
    include ActionView::Helpers::DateHelper

    module InstanceMethods
      def prepare_field_stats
        @issue = Issue.find(params[:id])
        @stats_data = generate_field_stats(@issue)
      end

      private

      def generate_field_stats(issue)
        stats = []
        # Load tracked fields for the issue's tracker, fall back to default
        tracked_fields = Setting.plugin_redmine_issue_update_statistics['tracked_fields_by_tracker']&.dig(issue.tracker_id.to_s) ||
                         Setting.plugin_redmine_issue_update_statistics['tracked_fields_by_tracker']&.dig('default') ||
                         ['status_id', 'assigned_to_id']
        journals = issue.journals.includes(:details, :user).order(created_on: :asc)
        issue_created = issue.created_on
        total_lifetime = (Time.now - issue_created).to_f / (60 * 60 * 24) # Days
        total_lifetime = 1.0 if total_lifetime < 1.0 # Avoid division by zero

        tracked_fields.each do |field|
          field_name = field_name_for(field)
          current_value = issue.send(field) rescue issue.custom_field_values.detect { |cf| cf.custom_field.id.to_s == field.split('_').last }&.value
          last_change_time = issue_created

          # Process journal details for this field
          journals.each do |journal|
            journal.details.each do |detail|
              next unless detail.prop_key == field || (field.start_with?('custom_field_') && detail.prop_key == "custom_#{detail.custom_field_id}")

              stats << {
                field: field_name,
                value: format_value(field, detail.old_value, issue),
                modified_by: journal.user&.name || 'Unknown',
                modified_date: last_change_time,
                lasted_for: distance_of_time_in_words(0,(journal.updated_on - last_change_time), include_seconds: true),
                percentage: (((journal.updated_on - last_change_time) / (60 * 60 * 24)) / total_lifetime * 100).round(2)
              }
              last_change_time = journal.updated_on
            end
          end

          stats << {
            field: field_name,
            value: format_value(field, current_value, issue),
            modified_by: journals.last&.user&.name || issue.author&.name || 'Unknown',
            modified_date: last_change_time,
            lasted_for: distance_of_time_in_words(0,(Time.now - last_change_time), include_seconds: true),
            percentage: (((Time.now - last_change_time) / (60 * 60 * 24)) / total_lifetime * 100).round(2)
          }


        end
        
        stats.sort_by {|obj| obj[:modified_date] }.reverse
        
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
    end
  end
end

IssuesController.send(:include, RedmineIssueUpdateStatistics::IssuesControllerPatch)