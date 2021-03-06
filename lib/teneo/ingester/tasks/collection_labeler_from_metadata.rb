# frozen_string_literal: true

require 'libis/tools/extend/hash'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks
      class CollectionLabelerFromMetadata < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_ingest

        description 'Generate collection labels and names based on a pattern and metadata fields.'

        help_text <<~STR
                     Rename the Collection object based on a regular expression.

                     By default the Collection item name is used to label files, but this can be changed with the 'value' parameter.

                     First of all the value is matched against a regular expression defined in the 'pattern' parameter. This regex
                     should define groups that will be used to extract the common and unique pieces of the file property. Based on
                     the result of the regex matching and using references to the regex groups, a new label will be calculated.
                     Likewise a different string for the item's name can be added in 'name'.

                     The value, label and name parameter values are generated by interpolating the given string using the 
                     [Kernel#sprintf](https://ruby-doc.org/core/Kernel.html#method-i-sprintf) syntax. The pattern groups can be 
                     referenced with m1, m2, ... and the item's properties by their respective names. The metadata fields
                     title(s), creator(s), subject(s), date(s), identifier(s) and source(s) are available for the interpolation as
                    'title', 'titles', 'creator', 'creators', etc.

                     Note: for the value parameter only the item properties are available.
                  STR

        parameter pattern: nil,
                  description: 'Regular expression for matching; nothing happens if nil.'
        parameter value: '%{name}',
                  description: 'The item property to be used for the matching.'
        parameter label: nil,
                  description: 'String with interpolation placeholders for new value of item label property.'
        parameter name: nil,
                  description: 'String with interpolation placeholders for new value of item name property.'

        recursive true
        item_types Teneo::DataModel::Collection

        protected

        def process(item, *_args)
          unless item.metadata_record
            debug 'Skipping item because it does not have a metadata record', item
            return
          end
          pattern = parameter(:pattern)
          if pattern && !pattern.blank?
            value = item.interpolate(parameter(:value))
            m = Regexp.new(pattern).match(value)
            return if m.nil?
            vars = get_metadata_fields(item).merge(match_to_hash(m))
            if parameter(:label)
              file_label = item.interpolate(parameter(:label), vars)
              debug 'Assigning label %s', item, file_label
              item.label = file_label
            end
            if parameter(:name)
              file_name = item.interpolate(parameter(:name), vars)
              debug 'Renaming to %s', item, file_name
              item.name = file_name
            end
            item.save!
          end
          item
        end

        def get_metadata_fields(item)
          metadata = item.metadata_record
          xml = Libis::Metadata::DublinCoreRecord.new(metadata.data)
          {
            title: xml.title.content,
            titles: xml.xpath('//title').map(&:content).join(', '),
            creator: xml.creator.content,
            creators: xml.xpath('//creator').map(&:content).join(', '),
            subject: xml.subject.content,
            subjects: xml.xpath('//subject').map(&:content).join(', '),
            date: xml.date.content,
            dates: xml.xpath('//date').map(&:content).join(', '),
            identifier: xml.identifier.content,
            identifiers: xml.xpath('//identifier').map(&:content).join(', '),
            source: xml.source.content,
            sources: xml.xpath('//source').map(&:content).join(', '),
          }.cleanup
        end
      end
    end
  end
end
