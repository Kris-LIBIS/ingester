# frozen_string_literal: true

module Teneo
  module Ingester

    class FileLabeler < Teneo::Ingester::Task

      taskgroup :preingester

      description 'Groups files into an IE.'

      help <<-STR.align_left
        Rename the File item object based on a regular expression.

        By default the File item filename is used to label files, but this can be changed with the 'value' parameter.

        First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
        should define groups that will be used to extract the common and unique pieces of the file property. Based on
        the result of the regex matching and using references to the regex groups (m[x]), a new label will be generated
        by interpolating the given string in the 'label' parameter. Optionally a different string for the File item's
        name can be added in 'name'.
      STR

      parameter pattern: nil,
                description: 'Regular expression for matching; nothing happens if nil.'
      parameter value: 'filename',
                description: 'The item property to be used for the matching.'
      parameter label: nil,
                description: 'String with interpolation placeholders for new value of item label property.'
      parameter name: nil,
                description: 'String with interpolation placeholders for new value of item name property.'

      parameter recursive: true
      parameter item_types: [Teneo::Ingester::FileItem], frozen: true

      protected

      def process(item, *_args)
        pattern = parameter(:pattern)
        if pattern && !pattern.blank?
          value = item.evaluate(parameter(:value))
          m = Regexp.new(pattern).match(value)
          return if m.nil?
          if parameter(:label)
            file_label = item.evaluate(parameter(:label), m)
            debug 'Assigning label %s', item, file_label
            item.label = file_label
          end
          if parameter(:name)
            file_name = item.evaluate(parameter(:name), m)
            debug 'Renaming to %s', item, file_name
            item.name = file_name
          end
          item.save!
        end
        item
      end

    end

  end
end
