Redmine::Plugin.register :redmine_issue_update_statistics do
  name 'Redmine Issue Update Statistics plugin'
  author 'LS MARK'
  description 'Show fields update statistics for the issues in issues page.'
  version '0.0.1'
  url 'https://daxonet.com'
  author_url 'https://daxonet.com/about'

  settings default: {
    'tracked_fields' => {
      'default' => ['status_id', 'assigned_to_id'], # Default fields if tracker not configured
      # Example: '1' => ['status_id', 'assigned_to_id', 'custom_field_1']
    }
  }, partial: 'settings/issue_update_statistics_settings'  
end

# Require necessary files
require_dependency File.dirname(__FILE__) + '/lib/redmine_issue_update_statistics/hooks'
require_dependency File.dirname(__FILE__) + '/lib/redmine_issue_update_statistics/issues_controller_patch'