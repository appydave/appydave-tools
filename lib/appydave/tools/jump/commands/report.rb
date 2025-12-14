# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Report command generates various reports about locations
        class Report < Base
          VALID_REPORTS = %w[
            categories brands clients types tags
            by-brand by-client by-type by-tag
            summary
          ].freeze

          attr_reader :report_type, :filter

          def initialize(config, report_type, filter: nil, path_validator: PathValidator.new, **options)
            super(config, path_validator: path_validator, **options)
            @report_type = report_type
            @filter = filter
          end

          def run
            unless VALID_REPORTS.include?(report_type)
              return error_result(
                "Unknown report type: #{report_type}",
                code: 'INVALID_INPUT',
                suggestion: "Valid types: #{VALID_REPORTS.join(', ')}"
              )
            end

            send("report_#{report_type.gsub('-', '_')}")
          end

          private

          def report_categories
            categories = config.categories.map do |name, info|
              {
                name: name,
                description: info['description'] || info[:description],
                values: info['values'] || info[:values] || []
              }
            end

            success_result(
              report: 'categories',
              count: categories.size,
              results: categories
            )
          end

          def report_brands
            brands = config.brands.map do |key, info|
              location_count = config.locations.count { |loc| loc.brand == key }
              {
                key: key,
                description: info['description'] || info[:description],
                aliases: info['aliases'] || info[:aliases] || [],
                location_count: location_count
              }
            end

            success_result(
              report: 'brands',
              count: brands.size,
              results: brands.sort_by { |b| -b[:location_count] }
            )
          end

          def report_clients
            clients = config.clients.map do |key, info|
              location_count = config.locations.count { |loc| loc.client == key }
              {
                key: key,
                description: info['description'] || info[:description],
                aliases: info['aliases'] || info[:aliases] || [],
                location_count: location_count
              }
            end

            success_result(
              report: 'clients',
              count: clients.size,
              results: clients.sort_by { |c| -c[:location_count] }
            )
          end

          def report_types
            type_counts = Hash.new(0)
            config.locations.each do |loc|
              type_counts[loc.type || 'untyped'] += 1
            end

            types = type_counts.map do |type, count|
              { type: type, location_count: count }
            end

            success_result(
              report: 'types',
              count: types.size,
              results: types.sort_by { |t| -t[:location_count] }
            )
          end

          def report_tags
            tag_counts = Hash.new(0)
            config.locations.each do |loc|
              loc.tags.each { |tag| tag_counts[tag] += 1 }
            end

            tags = tag_counts.map do |tag, count|
              { tag: tag, location_count: count }
            end

            success_result(
              report: 'tags',
              count: tags.size,
              results: tags.sort_by { |t| -t[:location_count] }
            )
          end

          def report_by_brand
            grouped = group_by_field(:brand, filter)
            success_result(
              report: 'by-brand',
              filter: filter,
              groups: grouped
            )
          end

          def report_by_client
            grouped = group_by_field(:client, filter)
            success_result(
              report: 'by-client',
              filter: filter,
              groups: grouped
            )
          end

          def report_by_type
            grouped = group_by_field(:type, filter)
            success_result(
              report: 'by-type',
              filter: filter,
              groups: grouped
            )
          end

          def report_by_tag
            grouped = {}
            config.locations.each do |loc|
              loc.tags.each do |tag|
                next if filter && tag != filter

                grouped[tag] ||= []
                grouped[tag] << location_summary(loc)
              end
            end

            success_result(
              report: 'by-tag',
              filter: filter,
              groups: grouped.sort_by { |_, locs| -locs.size }.to_h
            )
          end

          def report_summary
            success_result(
              report: 'summary',
              total_locations: config.locations.size,
              total_brands: config.brands.size,
              total_clients: config.clients.size,
              by_type: count_by_field(:type),
              by_brand: count_by_field(:brand),
              by_client: count_by_field(:client),
              config_info: config.info
            )
          end

          def group_by_field(field, filter_value)
            grouped = {}
            config.locations.each do |loc|
              value = loc.send(field) || 'unassigned'
              next if filter_value && value != filter_value

              grouped[value] ||= []
              grouped[value] << location_summary(loc)
            end
            grouped.sort_by { |_, locs| -locs.size }.to_h
          end

          def count_by_field(field)
            counts = Hash.new(0)
            config.locations.each do |loc|
              value = loc.send(field) || 'unassigned'
              counts[value] += 1
            end
            counts.sort_by { |_, count| -count }.to_h
          end

          def location_summary(location)
            {
              key: location.key,
              path: location.path,
              jump: location.jump,
              description: location.description
            }.compact
          end
        end
      end
    end
  end
end
