# frozen_string_literal: true

require_relative "base/task"

module Teneo
  module Ingester
    module Tasks
      class FileLabelerFromPattern < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_ingest

        description "Generate file item labels based on file name pattern."

        help_text <<~STR
                    Rename the File item object based on a regular expression.

                    By default the File item filename is used to label files, but this can be changed with the 'value' parameter.

                    First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
                    should define groups that will be used to extract the common and unique pieces of the file property. Based on
                    the result of the regex matching and using references to the regex groups , a new label will be generated.
                    Optionally a different string for the File item's name can be added in 'name'.

                    The value, label and name parameter values are generated by interpolating the given string using the 
                    [Kernel#sprintf](https://ruby-doc.org/core/Kernel.html#method-i-sprintf) syntax. The pattern groups can be 
                    referenced with m1, m2, ... and the item's properties by their respective names.

                    Note: for the value parameter only the item properties are available.
                  STR

        parameter pattern: nil,
                  description: "Regular expression for matching; nothing happens if nil."
        parameter value: "filename",
                  description: "The item property to be used for the matching."
        parameter label: nil,
                  description: "String with interpolation placeholders for new value of item label property."
        parameter name: nil,
                  description: "String with interpolation placeholders for new value of item name property."

        recursive true
        item_types Teneo::DataModel::FileItem

        protected

        def process(item, *_args)
          pattern = parameter(:pattern)
          if pattern && !pattern.blank?
            value = item.interpolate(parameter(:value))
            m = Regexp.new(pattern).match(value)
            return if m.nil?
            m = match_to_hash(m)

            if parameter(:label)
              file_label = item.interpolate(parameter(:label), m)
              debug "Assigning label %s", item, file_label
              item.label = file_label
            end

            if parameter(:name)
              file_name = item.interpolate(parameter(:name), m)
              debug "Renaming to %s", item, file_name
              item.name = file_name
            end
            item.save!
          end
          item
        end
      end
    end
  end
end
