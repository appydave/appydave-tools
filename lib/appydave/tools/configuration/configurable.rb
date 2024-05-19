# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Configurable module for handling dynamic configurations in tools and components
      module Configurable
        def config
          Appydave::Tools::Configuration::Config
        end
      end
    end
  end
end
