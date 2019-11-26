# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class CollectionBuilderFromPattern < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_ingest

        description 'Groups files into a collection based on file name pattern.'

        help_text <<~STR
          Files that have common properties can be grouped into a Collection with this task.

          By default the File item's filename is used to group files, but this can be changed with the 'value' parameter.

          First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
          should define groups that will be used to extract the common pieces of the file property. Based on the result 
          of the regex matching and using references to the regex groups, the collection path will be calculated.

          Both the value and path parameter values are generated by interpolating the given string using the 
          [Kernel#sprintf](https://ruby-doc.org/core/Kernel.html#method-i-sprintf) syntax. The pattern groups can be 
          referenced with m1, m2, ... and the item's properties by their respective names.

          Note: for the value parameter only the item properties are available.

          Collection hierarchy should be specified with the '/' as separator.

          The value of the parameters 'navigate' and 'publish' set the respective properties of the newly created 
          collections.
        STR

        parameter pattern: nil,
                  description: 'Regular expression for matching; nothing happens if nil or empty.'
        parameter value: '%{filename}',
                  description: 'The item property to be used for the matching.'
        parameter path: nil,
                  description: 'String with interpolation placeholders for the path of the collections.'
        parameter navigate: true,
                  description: 'Allow navigation through the collections.'
        parameter publish: true,
                  description: 'Publish the collections.'

        recursive true
        item_types Teneo::Ingester::FileItem

        protected

        def process(item, *_args)
          pattern = parameter(:pattern)
          if pattern && !pattern.blank?
            value = item.interpolate(parameter(:value))
            m = Regexp.new(pattern).match(value)
            return if m.nil?
            m = match_to_hash(m)
            collections = item.interpolate(parameter(:path), m)
            collection_list = collections.to_s.split('/') rescue []
            target_parent = item.parent
            collection_list.each do |collection|
              sub_parent = target_parent.items.find_by(type: Teneo::Ingester::Collection.name, name: collection)
              unless sub_parent
                sub_parent = Teneo::Ingester::Collection.new
                sub_parent.name = collection
                sub_parent.navigate = parameter(:navigate)
                sub_parent.publish = parameter(:publish)
                target_parent.add_item(sub_parent)
                sub_parent.save!
                debug 'Created new Collection item: %s', sub_parent, collection
                set_item_status(status: :done, item: sub_parent)
              end
              target_parent = sub_parent
            end
            if target_parent != item.parent
              debug 'Adding to collection %s', item, target_parent.name
              target_parent.with_lock do
                item = target_parent.move_item(item)
                item.save!
              end
            end
          end
          item
        end

      end

    end
  end
end
