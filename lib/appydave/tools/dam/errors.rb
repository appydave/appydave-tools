# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Base error for all DAM operations
      class DamError < StandardError; end

      # Raised when brand directory not found
      class BrandNotFoundError < DamError
        def initialize(brand, available_brands = nil)
          message = "Brand directory not found: #{brand}"
          message += "\n\nAvailable brands:\n#{available_brands}" if available_brands && !available_brands.empty?
          super(message)
        end
      end

      # Raised when project not found in brand
      class ProjectNotFoundError < DamError; end

      # Raised when configuration invalid or missing
      class ConfigurationError < DamError; end

      # Raised when S3 operation fails
      class S3OperationError < DamError; end

      # Raised when git operation fails
      class GitOperationError < DamError; end
    end
  end
end
