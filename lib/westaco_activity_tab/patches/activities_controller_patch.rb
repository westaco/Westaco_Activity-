module WestacoActivityTab
  module Patches
    module ActivitiesControllerPatch
      def self.included(base)
        base.class_eval do
          helper :queries
          include QueriesHelper

          layout 'activities', only: :index

          def index
            @query = ActivityQuery.new(:name => "_", :project => @project)
            @query.build_from_params(params)

            if @query.has_filter?('updated_on') && params[:submit]
              params[:from] = @query.values_for('updated_on').first
              params[:to] = @query.values_for('updated_on').last
            end

            filters = @query.filters

            if params[:to]
              begin; @date_to = params[:to].to_date + 1; rescue; end
            end

            if params[:from]
              begin; @date_from = params[:from].to_date + 1; rescue; end
            end

            @days = Setting.activity_days_default.to_i
            @date_to ||= User.current.today + 1
            @date_from ||= @date_to - @days
            @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')

            if params[:user_id].present?
              @author = User.visible.active.find(params[:user_id])
              @query.add_filter 'author_id', '=', [params[:user_id]]
            end

            @query.add_filter 'updated_on', '><', [(@date_from - 1).to_s, (@date_to - 1).to_s(:db)]

            @activity = Redmine::Activity::Fetcher.new(
              User.current,
              :project => @project,
              :with_subprojects => @with_subprojects,
              :author => @author
            )

            pref = User.current.pref
            @activity.scope_select {|t| !params["show_#{t}"].nil?}

            if @activity.scope.present?
              if params[:submit].present?
                pref.activity_scope = @activity.scope
                pref.save
              end
            else
              if @author.nil?
                scope = pref.activity_scope & @activity.event_types
                @activity.scope = scope.present? ? scope : :default
              else
                @activity.scope = :all
              end
            end

            events =
            if params[:format] == 'atom'
              @activity.events(nil, nil, :limit => Setting.feeds_limit.to_i)
            else
              @activity.events_with_query(@date_from, @date_to, { :query => @query })
            end

            @query.filters = filters

            if events.empty? || stale?(:etag => [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, events.size, User.current, current_language])
              respond_to do |format|
                format.html do
                  @events_by_day = events.group_by {|event| User.current.time_to_date(event.event_datetime)}
                  render :layout => false if request.xhr?
                end
                format.atom do
                  title = l(:label_activity)

                  if @author
                    title = @author.name
                  elsif @activity.scope.size == 1
                    title = l("label_#{@activity.scope.first.singularize}_plural")
                  end

                  render_feed(events, :title => "#{@project || Setting.app_title}: #{title}")
                end
              end
            end
          rescue ActiveRecord::RecordNotFound
            render_404
          end
        end
      end
    end
  end
end

unless ActivitiesController.included_modules.include?(WestacoActivityTab::Patches::ActivitiesControllerPatch)
  ActivitiesController.send(:include, WestacoActivityTab::Patches::ActivitiesControllerPatch)
end
