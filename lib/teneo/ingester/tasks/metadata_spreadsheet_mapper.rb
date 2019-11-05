require 'libis/metadata/dublin_core_record'

require_relative 'base/mapping'
require_relative 'base/metadata_collector'

module Libis
  module Ingester

    class MetadataSpreadsheetMapper < Teneo::Ingester::Tasks::Base::MetadataCollector

      include Teneo::Ingester::Tasks::Base::Mapping

      parameter mapping_headers: %w(objectname filename label)
      parameter mapping_key: 'filename'
      parameter mapping_value: nil
      parameter filter_keys: []

      parameter term: nil,
                description: 'The item property to be used for the lookup.',
                help: <<~STR
                    If no term is given, the item name will be used.

                    Use pattern and value to create a term dynamically. This 'term' parameter will then be interpolated
                    with the result of the pattern matching. The pattern groups can be referenced with m1, m2, ... .
                STR

      parameter pattern: nil,
                description: 'Optional regular expression for matching; nothing happens if nil.',
                help: <<~STR
                    The results of the match can be used in the 'term' parameter.
                    If nil, no Regexp matching is performed.
                STR

      parameter value: 'name',
                description: 'The item property to be used for the matching.',
                help: <<~STR
                    Available properties are:

                    - name: name of the object
                    - label: label of the object
                    - filename: file name of the object
                    - filepath: relative path of the object
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
        data.each do |key,value|
          next unless key =~ /^<(dc(terms)?:[^>]+)>.*$/
          record.add_node $1, value
        end

        record
      end

      def get_term(item)
        pattern = parameter(:pattern)
        if pattern && !pattern.blank?
          value = item.evaluate(parameter(:value))
          m = Regexp.new(pattern).match(value)
          return if m.nil?
          m = match_to_hash(m)
          return item.interpolate(parameter(:term), m)
        end
        parameter(:term).blank? ? item.name : item.evaluate(parameter(:term))
      end

    end

  end
end
