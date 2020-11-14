# frozen_string_literal: true

require 'teneo/ingester'

require_relative 'metadata_collector'

module Teneo
  module Ingester
    module Tasks
      module Base

        class MetadataSearchCollector < Teneo::Ingester::Tasks::Base::MetadataCollector

          parameter field: nil,
                    description: 'Field to search on.',
                    help: <<~STR
                      If nil (default) no search will be performed, but a simple id lookup will happen instead.'
                    STR

          parameter term: nil,
                    description: 'Item property that contains the search term to be used in the metadata lookup.',
                    help: <<~STR
                      If no term is given, the item name will be used. Available data are:

                      filename
                      : file name of the object

                      filepath
                      : relative path of the object

                      fullpath
                      : full path of the object

                      name
                      : name of the object

                      Use pattern and value to create a term dynamically. In that case the value of this parameter
                      will be interpolated and pattern groups (m1, m2, ...) can be referenced too.
                    STR

          parameter pattern: nil,
                    description: 'Regular expression for matching; nothing happens if nil.'

          parameter value: '%{name}',
                    description: 'The item property to be used for the matching.'

          protected

          def get_record(item)
            term = get_search_term(item)
            debug "search term: '#{term}'", item
            return nil if term.blank?

            item.properties['metadata_search_term'] = term
            item.save!

            get_metadata(item, term)
          end

          def get_metadata(item, term)
            @metadata_cache ||= {}

            @metadata_cache[term] ||= search(term, item)
            debug 'Metadata for item \'%s\' not found.', item, item.namepath unless @metadata_cache[term]

            @metadata_cache[term]
          end

          def get_search_term(item)
            pattern = parameter(:pattern)
            if pattern && !pattern.blank?
              debug "pattern '%s' found. Evaluating '%s'",item,
                    parameter(:pattern), parameter(:value)
              value = item.interpolate(parameter(:value))
              debug "Match term is now '#{value}'", item
              m = Regexp.new(pattern).match(value)
              return if m.nil?
              m = match_to_hash(m)
              debug "Value matches pattern", item
              return item.interpolate(parameter(:term), m)
            end
            parameter(:term).blank? ? item.name : item.interpolate(parameter(:term))
          end

          def search(_term, _item)
            nil
          end

        end

      end
    end
  end
end
