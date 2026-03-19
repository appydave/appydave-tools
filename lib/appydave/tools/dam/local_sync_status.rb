# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Enriches S3 scan project data with local s3-staging sync status
      module LocalSyncStatus
        module_function

        # Mutates matched_projects hash to add :local_status and :local_file_count keys
        # @param matched_projects [Hash] Map of project_id => S3 data hash
        # @param brand_key [String] Brand key (e.g., 'appydave')
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def enrich!(matched_projects, brand_key)
          matched_projects.each do |project_id, data|
            project_path = Appydave::Tools::Dam::Config.project_path(brand_key, project_id)
            s3_staging_path = File.join(project_path, 's3-staging')

            if !Dir.exist?(project_path)
              data[:local_status] = :no_project # Project directory doesn't exist
            elsif !Dir.exist?(s3_staging_path)
              data[:local_status] = :no_files # Project exists but no downloads yet
            else
              # Count local files in s3-staging
              local_files = Dir.glob(File.join(s3_staging_path, '**', '*'))
                               .select { |f| File.file?(f) }
                               .reject { |f| File.basename(f).include?('Zone.Identifier') } # Exclude Windows metadata

              s3_file_count = data[:file_count]
              local_file_count = local_files.size

              data[:local_status] = if local_file_count.zero?
                                      :no_files
                                    elsif local_file_count == s3_file_count
                                      :synced # Fully synced
                                    else
                                      :partial # Some files downloaded
                                    end

              data[:local_file_count] = local_file_count
            end
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        # Format local sync status symbol for display
        # @param status [Symbol] :synced, :no_files, :partial, :no_project
        # @param local_count [Integer, nil] Number of local files
        # @param s3_count [Integer] Number of S3 files
        # @return [String] Formatted status string
        def format(status, local_count, s3_count)
          case status
          when :synced
            '✓ Synced'
          when :no_files
            '⚠ None'
          when :partial
            "⚠ #{local_count}/#{s3_count}"
          when :no_project
            '✗ Missing'
          else
            'Unknown'
          end
        end
      end
    end
  end
end
