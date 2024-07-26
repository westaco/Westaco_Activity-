class ActivityQuery < Query
  attr_accessor :queried_table_name

  self.queried_class ||= Issue
  self.view_permission = :view_issues

  def initialize(attributes = nil, *args)
    super(attributes)
    self.filters ||= {}
  end

  # Initializes the available filters for the activity query.
  def initialize_available_filters
    add_available_filter(
      'status_id',
      :type => :list_status,
      :values => lambda { issue_statuses_values }
    )

    add_available_filter(
      'project_id',
      :type => :list,
      :values => lambda { project_values }
    ) if project.nil?

    add_available_filter(
      'subproject_id',
      :type => :list_subprojects,
      :values => lambda { subproject_values }
    ) if project && !project.leaf?

    add_available_filter(
      "tracker_id",
      :type => :list_with_history,
      :values => trackers.collect{|s| [s.name, s.id.to_s]}
    )

    add_available_filter(
      "attachment",
      :type => :text,
      :name => l(:label_attachment)
    )

    add_available_filter "subject", :type => :text
    add_available_filter "description", :type => :text
    add_available_filter "notes", :type => :text
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past, :name => l(:label_activity_date)
    add_available_filter "closed_on", :type => :date_past
    add_available_filter "start_date", :type => :date
    add_available_filter "due_date", :type => :date
    add_available_filter "estimated_hours", :type => :float
  end

  def base_scope
    ActivityQuery.queried_class.visible.joins(:project).where(statement)
  end
end
