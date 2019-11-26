# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class CollectionBuilderFromTree < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_ingest

        description 'Create collections from a tree of directories.'

        help_text <<~STR
          This task will transform the directory hierarchy into a collection hierarchy.

          The directories will be traversed from the top down and each directory encountered will be replaced with a
          collection.

          You can limit the depth of the transversal by setting the 'depth_limit' parameter. The value is a measure for
          the depth of the collection path. '1' will create only top-level collections, '2' will generate only 
          subcollections for top-level collection, etc. Setting the value to '0' or negative will not restrict the depth
          at all.

          The value of the parameters 'navigate' and 'publish' set the respective properties of the newly created 
          collections.
        STR

        parameter depth_limit: 0,
                  description: 'Restrict the depth level of the collection hierarchy.'
        parameter navigate: true,
                  description: 'Allow navigation through the collections.'
        parameter publish: true,
                  description: 'Publish the collections.'

        recursive true
        item_types Teneo::Ingester::DirItem

        protected

        def process(item, *_args)
          if parameter(:depth_limit) > 0 && item.namepath.size > parameter(:depth_limit)
            stop_recursion
            return
          end
          item = item.becomes!(Teneo::Ingester::Collection)
          item.navigate = parameter(:navigate)
          item.publish = parameter(:publish)
          debug 'Created Collection from Dir item', item
          item
        end

      end

    end
  end
end
