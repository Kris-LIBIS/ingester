# frozen_string_literal: true

module Teneo
  module Ingester

    class FileIeBuilder < Teneo::Ingester::Task

      taskgroup :preingester

      description 'Groups files into an IE.'

      help <<-STR.align_left
        Files that have common properties can be grouped into a single IE with this task.

        By default the File item's filename is used to group files, but this can be changed with the 'value' parameter.

        First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
        should define groups that will be used to extract the common and unique pieces of the file property. Based on
        the result of the regex matching and using references to the regex groups(m[x]), IEs will be generated.

        The 'name' parameter needs to contain a string with interpolation placeholders and used to generate the name of
        the new IE. It the value is not present, no grouping of files into IEs will be performed. Likewise the 'label'
        parameter will be used for the label of the new IEs.

      STR

      parameter pattern: nil,
                description: 'Regular expression for matching; nothing happens if nil.'
      parameter value: 'filename',
                description: 'The item property to be used for the matching.'
      parameter name: nil,
                description: 'String with interpolation placeholders for the label of the new IEs.'
      parameter label: nil,
                description: 'String with interpolation placeholders for the name of the new IEs.'

      parameter recursive: true
      parameter item_types: [Teneo::Ingester::FileItem], frozen: true

      protected

      def pre_process(item, *_args)
        stop_recursion if check_item_type(item, Teneo::Ingester::IntellectualEntity)
        super
      end

      def process(item, *_args)
        grouping = parameter(:pattern)
        if grouping && !grouping.blank?
          value = item.evaluate(parameter(:value))
          m = Regexp.new(grouping).match(value)
          return if m.nil?
          target_parent = item.parent
          if parameter(:name)
            ie_name = item.evaluate(parameter(:name), m)
            ie_label = item.evaluate(parameter(:label), m) if parameter(:label)
            ie_label ||= ie_name
            ie = target_parent.items.find_by(type: Teneo::Ingester::IntellectualEntity.name, name: ie_name)
            unless ie
              ie = Teneo::Ingester::IntellectualEntity.new
              ie.name = ie_name
              ie.label = ie_label
              target_parent.add_item(ie)
              debug 'Created new IE item for group: %s', ie, ie_label
            end
            target_parent = ie if ie
          end
          if target_parent != item.parent
            debug 'Adding File to IE %s', item, ie.name
            item = ie.move_item(item)
          end
          item.save!
        end
        item
      end

    end

  end
end
