# frozen_string_literal: true

require 'libis/metadata/dublin_core_record'

require_relative 'base/mapping'
require_relative 'base/metadata_collector'

module Teneo
  module Ingester
    module Tasks

      class MetadataSpreadsheetMapper < Teneo::Ingester::Tasks::Base::MetadataCollector

        include Teneo::Ingester::Tasks::Base::Mapping

        description 'Add metadata based on a lookup in a spreadsheet or CSV'

        help_text <<~STR
          The structure ot the spreadsheet is defined by the parameters 'mapping_headers', 'mapping_key' and
          'mapping_value'. 

          The 'mapping_headers' parameter selects the columns that are of interest. If no headers are present in
          the spreadsheet, the header list will be forded upon it. In that case empty columns on the left will be
          ignored, but all remaining columns must be named in the 'mapping_headers' parameter.

          The 'mapping_key' parameter selects the column where the lookup values reside. The header value should be
          entered here.
          
          The term parameter value will be used to lookup the corresponding line in the spreadsheet. The parameter can
          reference a property of the item.

          The value and pattern parameters can be used to dynamically create a value for the term parameter. The value
          of the value parameter is first calculated, then matched against the pattern and then the term parameter will
          be calculated. The term parameter can refer to any pattern groups to assemble its value.

          The value and term parameter values are generated by interpolating the given string using the 
          [Kernel#sprintf](https://ruby-doc.org/core/Kernel.html#method-i-sprintf) syntax. The pattern groups can be 
          referenced with m1, m2, ... and the item's properties by their respective names.

          Note: for the value parameter only the item properties are available.
  
          The parameter 'ignore_empty_values' parameter, decides what happens if the term value cannot be found in the
          lookup column of the spreadsheet. It will ignore if 'true' or throw an exception if 'false'.
        STR

        parameter mapping_headers: %w(objectname filename label)
        parameter mapping_key: 'filename'

        parameter term: nil,
                  description: 'The item property to be used for the lookup.',
                  help: <<~STR
                    If no term is given, the item name will be used.

                    Use pattern and value to create a term dynamically. This 'term' parameter will then be interpolated
                    with the result of the pattern matching. The pattern groups can be referenced with m1, m2, ... .
        STR

        parameter pattern: nil,
                  description: 'Optional regular expression for matching; no matching happens if empty.',
                  help: <<~STR
                    The results of the match can be used in the 'term' parameter.
                    If empty, no Regexp matching is performed.
        STR

        parameter value: '%{name}',
                  description: 'The item property to be used for the matching.',
                  help: <<~STR
                    Available properties are:

                    name
                    : name of the object

                    label
                    : label of the object

                    filename
                    : file name of the object

                    filepath
                    : relative path of the object
        STR

        parameter ignore_empty_value: true,
                  description: 'Ignore if no entry is found in the mapping. Will throw an exception if false.'

        protected

        def get_record(item)
          term = get_term(item)
          return nil if term.blank?

          data = lookup(term)
          if data.blank?
            debug "No metadata found for #{term}", item
            return nil
          end

          record = Libis::Metadata::DublinCoreRecord.new
          data.each do |key, value|
            next unless key =~ /^<(dc(terms)?:[^>]+)>.*$/
            record.add_node $1, value
          end

          record
        end

        def get_term(item)
          pattern = parameter(:pattern)
          if pattern && !pattern.blank?
            value = item.interpolate(parameter(:value))
            m = Regexp.new(pattern).match(value)
            return if m.nil?
            m = match_to_hash(m)
            return item.interpolate(parameter(:term), m)
          end
          parameter(:term).blank? ? item.name : item.interpolate(parameter(:term))
        end

      end

    end
  end
end
