module RedmineIssueUpdateStatistics
  module IssuePatch
    def self.included(base)
      base.class_eval do
          validate :validate_reason
      end
    end
    
    def validate_reason
      return if current_journal.reason.present? || has_tracked_field_updated == false
      errors.add :base, 'Reason cannot be blank'
    end  

    def has_tracked_field_updated
      Array(Setting.plugin_redmine_issue_update_statistics['core_fields']).each do |f|            
        old_val, new_val = changes[f]
        return if old_val.to_s != new_val.to_s
      end
      
      Array(Setting.plugin_redmine_issue_update_statistics['custom_fields']).each do |f|
        old_val = custom_values.detect { |v| v.custom_field.id == f.to_i }
        new_val = self.custom_field_value(f.to_s)
        return if old_val.to_s != new_val.to_s
      end

      false
    end
    
  end
end

Issue.send(:include, RedmineIssueUpdateStatistics::IssuePatch)