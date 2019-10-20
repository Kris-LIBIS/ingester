# frozen_string_literal: true

module Teneo
  module Ingester
    class Collection < WorkItem

      include Libis::Workflow::FileItem

      def filename=(dir)
        raise "'#{dir}' is not a directory" unless File.directory? dir
        self.name = File.basename(dir)
        super
      end

      def navigate
        options[:navigate]
      end

      def navigate=(value)
        options[:navigate] = value
      end

      def publish
        options[:publish]
      end

      def publish=(value)
        options[:publish] = value
      end

      def collections
        items.where(type: 'Teneo::Ingester::Collection')
      end

      def intellectual_entities
        items.where(type: 'Teneo::Ingester::IntellectualEntity')
      end

      def navigate?
        options[:navigate].nil? ? true : options[:navigate]
      end

      def publish?
        options[:publish].nil? ? false : options[:publish]
      end

    end
  end
end
