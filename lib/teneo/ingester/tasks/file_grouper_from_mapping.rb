require 'teneo/ingester'

require_relative 'base/mapping'

module Teneo
  module Ingester
    module Tasks

      class FileGrouperFromMapping < Teneo::Ingester::Tasks::Base::Task

        include Base::Mapping

        taskgroup :pre_ingest

        description 'Groups files into object based on mapping file.'

        help_text <<~STR
          Files can be grouped together with this task by using a mapping file (e.g. CSV).

          The mapping file should contain the file name, the name of the group it belongs to. Optionally it can also have
          a label for the group.
        STR

        parameter group_field: nil,
                  description: 'The name of the column in the mapping table that contains the name of the group.',
                  help: 'Optional. If omitted, the files will not be grouped.'
        parameter label_field: nil,
                  description: 'The name of the column in the mapping table that contains the label of the group.',
                  help: 'Optional. If omitted, the group label will not be set and defaults to the group name.'

        recursive true
        item_types Teneo::Ingester::FileItem

        def configure(opts)
          super
          required = Set.new(parameter(:required_fields))
          required << parameter(:group_field) if parameter(:group_field)
          required << parameter(:label_field) if parameter(:label_field)
          set = Set.new(parameter(:mapping_headers))
          set += required
          required = [parameter(:mapping_key)] + required.to_a
          parameter(:mapping_headers, set.to_a)
          parameter(:required_fields, required)
        end

        protected

        def process(item, *_args)
          target_parent = item.parent
          if (group_field = parameter(:group_field))
            if (group_name = lookup(item.filename, group_field))
              group = target_parent.items.where(name: group_name, type: Teneo::Ingester::ItemGroup.name).first
              unless group
                group = Teneo::Ingester::ItemGroup.new
                group.name = group_name
                group.label = lookup(item.filename, parameter(:label_field)) if parameter(:label_field)
                group.label ||= group_name
                target_parent.add_item(group)
                debug 'Created new item group: %s', group, group_name
                group.save!
                set_item_status(status: :done, item: group)
              end
              target_parent = group
            end
          end
          unless target_parent == item.parent
            debug 'Moving item to %s', item, target_parent.name
            item = target_parent.move_item(item)
          end
          item.save!
          item
        end

      end

    end
  end
end
