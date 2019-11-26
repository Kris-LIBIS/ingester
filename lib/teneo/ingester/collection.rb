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

      def description
        options[:description]
      end

      def description=(value)
        options[:description] = value
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

      def external_system
        options[:external_system]
      end

      def external_system=(value)
        options[:external_system] = value
      end

      def external_id
        options[:external_id]
      end

      def external_id=(value)
        options[:external_id] = value
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
