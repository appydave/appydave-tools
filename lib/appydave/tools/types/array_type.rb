# frozen_string_literal: true

module Appydave
  module Tools
    module Types
      # Used by the ActiveModel attributes API to cast values to arrays
      class ArrayType < ActiveModel::Type::Value
        def cast(value)
          case value
          when String
            value.split(',')
          when Array
            value
          else
            raise ArgumentError, "Cannot cast #{value.class} to Array"
          end
        end

        def serialize(value)
          value.join(',')
        end
      end
    end
  end
end

ActiveModel::Type.register(:array, Appydave::Tools::Types::ArrayType)
