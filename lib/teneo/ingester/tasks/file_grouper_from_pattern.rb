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

        def process(item, *_args)
          pattern = parameter(:pattern)
          if pattern && !pattern.blank?
            value = item.evaluate(parameter(:value))
            m = Regexp.new(pattern).match(value)
            return item if m.nil?
            m = match_to_hash(m)
            group_name = item.interpolate(parameter(:name), m) if parameter(:name)
            group_label = item.interpolate(parameter(:label), m) if parameter(:label)
            target_parent = item.parent
            group_name ||= group_label
            group_label ||= group_name
            group = target_parent.items.where(name: group_name, type: Teneo::Ingester::ItemGroup.name).first
            unless group
              group = Teneo::Ingester::ItemGroup.new
              group.name = group_name
              group.label = group_label
              target_parent.add_item(group)
              debug 'Created new group item with label: %s', group, group_label
            end
            return item unless group
            debug 'Adding to group %s', item, group.name
            item = group.move_item(item)
            item.save!
          end
          item
        end

      end

    end
  end
end
