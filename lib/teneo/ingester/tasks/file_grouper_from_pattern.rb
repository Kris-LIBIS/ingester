require 'teneo/ingester'

module Teneo
  module Ingester
    module Tasks

      class FileGrouperFromPattern < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_ingest

        description 'Groups files into object based on file name pattern.'

        help_text <<~STR
          Files that have part of their filename in common can be grouped into a single IE with this task.

          By default the File item's filename is used to group files, but this can be changed with the 'value' parameter.

          First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
          should define groups that will be used to extract the common and unique pieces of the file property. Based on
          the result of the regex matching and using references to the regex groups(m[x]), groups will be generated.

          The 'name' parameter needs to contain a string with interpolation placeholders and used to generate the name of
          the group. If the value is not present, no grouping of files will be performed. Likewise the 'label'
          parameter will be used for the label of the new group.
        STR

        parameter pattern: nil,
                  description: 'Regular expression for matching; nothing happens if nil.'
        parameter value: 'filename',
                  description: 'The item property to be used for the matching.'
        parameter name: nil,
                  description: 'String with interpolation placeholders for the name of the new group.'
        parameter label: nil,
                  description: 'String with interpolation placeholders for the name of the new IEs.'

        recursive true
        item_types Teneo::Ingester::FileItem

        protected

        def pre_process(item, *_args)

        end

        def process(item, *_args)
          grouping = parameter(:pattern)
          if grouping && Kernel.eval(parameter(:value)) =~ Regexp.new(grouping)
            target_parent = item.parent
            group = nil
            if parameter(:label) || parameter(:name)
              group_name = Kernel.eval(parameter(:name)) if parameter(:name)
              group_label = Kernel.eval(parameter(:label)) if parameter(:label)
              # noinspection RubyScope
              group_name ||= group_label
              group_label ||= group_name
              group = target_parent.items.where(name: group_name, type: Teneo::Ingester::ItemGroup.name).first
              unless group
                group = Teneo::Ingester::ItemGroup.new
                group.name = group_name
                group.label = group_label
                target_parent.add_item(group)
                debug 'Created new group item for group: %s', group, group_label
              end
            end
            if group
              debug 'Adding to group %s', item, group.name
              item = group.move_item(item)
            end
            item.save!
          end
          item
        end

      end

    end
  end
end
