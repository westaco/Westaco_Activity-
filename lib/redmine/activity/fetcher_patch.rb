module Redmine
  module Activity

    module FetcherPatch
      def self.included(base)
        base.class_eval do
          def events_with_query(from = nil, to = nil, options={})
            e = []
            @options[:limit] = options[:limit]

            query = options[:query]
            filters = query.try(:filters)
            @scope.each do |event_type|
              constantized_providers(event_type).each do |provider|
                if filters.present?
                  query.queried_table_name = provider.table_name
                  query_filtered = {}
                  filters.each_key.each do |key|
                    query_filtered.merge!(key => filters[key]) if provider.column_names.include?(key)
                  end
                  query.filters = query_filtered
                  @options[:query_full_statement] = filters.keys.length == query_filtered.keys.length
                  @options[:query_exist] = true
                  @options[:query_statement] = query.statement
                end

                e += provider.find_events_with_query(event_type, @user, from, to, @options)
              end
            end

            e.sort! {|a, b| b.event_datetime <=> a.event_datetime}

            if options[:limit]
              e = e.slice(0, options[:limit])
            end
            e
          end
        end
      end
    end

  end
end

Redmine::Activity::Fetcher.include Redmine::Activity::FetcherPatch
