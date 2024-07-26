require File.dirname(__FILE__) + '/lib/redmine/activity/fetcher_patch.rb'
require File.dirname(__FILE__) + '/lib/redmine/acts/activity_provider_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_activity_tab/patches/activities_controller_patch.rb'

Redmine::Plugin.register :westaco_activity_tab do
  name 'Westaco Activity Tab plugin'
  author 'Yanto Daryanto'
  description 'This is a plugin for adding enhanced filters to the activity tab in Redmine'
  version '0.0.1'
  url 'https://github.com/westaco/westaco_activity_tab'
  author_url 'https://github.com/yan13to'
end
