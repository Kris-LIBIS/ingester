# frozen_string_literal: true

module Teneo
  module Ingester

    class IeBuilder < Teneo::Ingester::Task

      taskgroup :preingester

      parameter recursive: true

      protected

      def pre_process(item, *_args)
        # Check if there exists an IE somewhere up the hierarchy
        return false if get_ie(item)
        super
      end

      def process(item, *_args)

        case item
          when Teneo::Ingester::FileItem
            ie = create_ie(item)
            ie.save!
            item = ie.move_item(item)
            debug 'File item %s moved to IE item %s', item, item.name, ie.name
          when ::Teneo::Ingester::ItemGroup
            ie = create_ie(item)
            # ItemGroup objects are replaced with the IE
            # move the sub items over to the IE
            item.items.each { |i| ie.move_item(i) }
            debug 'Moved contents of %s from ItemGroup item to IE item.', item, item.name
            item.parent = nil
            item.destroy!
            item = ie
          else
            # do nothing
        end
        item
      end

      def get_ie(for_item)
        ([for_item] + for_item.ancestors).select do |i|
          i.is_a? ::Teneo::Ingester::IntellectualEntity
        end.first rescue nil
      end

      def create_ie(item)
        # Create an the IE for this item
        debug "Creating new IE item for item #{item.name}", item
        ie = Teneo::Ingester::IntellectualEntity.new
        ie.name = item.name
        ie.label = item.label

        # Add IE to item's parent
        item.parent.add_item(ie)

        # returns the newly created IE
        ie
      end


    end

  end
end
