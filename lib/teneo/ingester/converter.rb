# frozen_string_literal: true

require 'libis-format'

module Teneo
  module Ingester

    class Converter < Teneo::Ingester::Task

      taskgroup :converter

      parameter recursive: true

      def action
        parent.action
      end

      def action=(value)
        parent.action = value
      end

      protected

      def pre_process(item, *_args)
        return false unless item.is_a?(Teneo::Ingester::FileItem)
        super
      end

      def post_process(item, *_args)
        item.save!
        item.reload
      end

    end
  end
end
