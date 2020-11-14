# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks
      class IeBuilderFromPattern < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_ingest

        description 'Groups files into an IE.'

        help_text <<~STR
                    Files that have common properties can be grouped into a single IE with this task.

                    By default the File item's filename is used to group files, but this can be changed with the 'value' parameter.

                    First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
                    should define groups that will be used to extract the common and unique pieces of the file property. Based on
                    the result of the regex matching and using references to the regex groups, IEs will be generated. Likewise the
                    'label' parameter will be used for the label of the new IEs.

                    The value, label and name parameter values are generated by interpolating the given string using the 
                    [Kernel#sprintf](https://ruby-doc.org/core/Kernel.html#method-i-sprintf) syntax. The pattern groups can be 
                    referenced with m1, m2, ... and the item's properties by their respective names.

                    Note: for the value parameter only the item properties are available.
                  STR

        parameter pattern: nil,
                  description: 'Regular expression for matching; nothing happens if nil.'
        parameter value: '%{filename}',
                  description: 'The item property to be used for the matching.'
        parameter name: nil,
                  description: 'String with interpolation placeholders for the label of the new IEs.'
        parameter label: nil,
                  description: 'String with interpolation placeholders for the name of the new IEs.'

        recursive true
        item_types Teneo::DataModel::FileItem

        protected

        def pre_process(item, *_args)
          stop_recursion if check_item_type(item, Teneo::DataModel::IntellectualEntity, raise_on_error: false)
          super
        end

        def process(item, *_args)
          grouping = parameter(:pattern)
          if grouping && !grouping.blank?
            value = item.interpolate(parameter(:value))
            m = Regexp.new(grouping).match(value)
            return if m.nil?
            m = match_to_hash(m)
            target_parent = item.parent
            if parameter(:name)
              ie_name = item.interpolate(parameter(:name), m)
              ie_label = item.interpolate(parameter(:label), m) if parameter(:label)
              ie_label ||= ie_name
              ie = target_parent.items.find_by(type: Teneo::DataModel::IntellectualEntity.name, name: ie_name)
              unless ie
                ie = Teneo::DataModel::IntellectualEntity.new
                ie.name = ie_name
                ie.label = ie_label
                target_parent.add_item(ie)
                ie.save!
                debug 'Created new IE item for group: %s', ie, ie_label
              end
              target_parent = ie if ie
            end
            if target_parent != item.parent
              # noinspection RubyScope
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
end
