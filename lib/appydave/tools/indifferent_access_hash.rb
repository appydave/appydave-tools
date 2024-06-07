# frozen_string_literal: true

module Appydave
  module Tools
    # Hash with indifferent access
    class IndifferentAccessHash < Hash
      def initialize(initial_hash = {})
        super()
        update(initial_hash)
      end

      def [](key)
        super(convert_key(key))
      end

      def []=(key, value)
        super(convert_key(key), value)
      end

      def fetch(key, *args)
        super(convert_key(key), *args)
      end

      def delete(key)
        super(convert_key(key))
      end

      private

      def convert_key(key)
        key.is_a?(Symbol) ? key.to_s : key
      end

      def update(initial_hash)
        initial_hash.each do |key, value|
          self[convert_key(key)] = value
        end
      end
    end
  end
end
