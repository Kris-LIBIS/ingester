# frozen_string_literal: true

require 'pathname'

require 'teneo/ingester'
require 'libis/metadata/dublin_core_record'
require 'libis/services/rosetta'
require 'libis/services/rosetta/collection_handler'

module Teneo
  module Ingester
    module Tasks
      class CollectionCreator < Teneo::Ingester::Tasks::Base::Task
        taskgroup :ingest

        description 'Create the collection tree in Rosetta corresponding to the tree of Collection objects in the ingest run.'

        help_text <<~STR
                    For each Collection object in the ingest run tree, a Rosetta collection is created. The collection tree can be
                    created as subtree of an existing Rosetta collection by filling in the path in the 'collection' parameter. The
                    collection path does not have to exist and will be created on the fly if missing. 

                    By default, the Rosetta collections will be created with 'navigate' and 'publish' flags on, but this behaviour
                    can be changed with the parameters with corresponding names. The ingest Collection object's respective 
                    properties have priority over these parameter values. The parameter values will also be used when automatically 
                    creating intermediate collections in the tree.
                  STR

        parameter collection: nil,
                  description: 'Existing collection path to add the documents to.'
        parameter navigate: true,
                  description: 'Allow the user to navigate in the collections.'
        parameter publish: true,
                  description: 'Publish the collections.'

        recursive true
        item_types Teneo::DataModel::Collection

        protected

        def process(item)
          create_collection(item)
          stop_recursion unless item.items.any? do |i|
            check_item_type(i, Teneo::DataModel::Collection, raise_on_error: false)
          end
        end

        private

        attr_accessor :rosetta

        # noinspection RubyResolve
        def create_collection(item, collection_list = nil)
          unless collection_list
            collection_list = item.parents.select { |i| i.is_a? Teneo::DataModel::Collection }.map(&:label)
            collection_list = parameter(:collection).split('/') + collection_list if parameter(:collection)
          end

          unless @collection_service
            producer = item.job.producer
            @collection_service = Libis::Services::Rosetta::CollectionHandler.new(
              Teneo::Ingester::Config.rosetta_url,
              logger: Teneo::Ingester::Config.logger, log_level: :debug, log: false,
            )
            @collection_service.authenticate(producer.agent,
                                             Teneo::Ingester::Initializer.decrypt(producer.password),
                                             producer.inst_code)
            # rosetta = Libis::Services::Rosetta::Service.new(
            #     Teneo::Ingester::Config.base_url, Teneo::Ingester::Config.pds_url,
            #     logger: Teneo::Ingester::Config.logger, log_level: :debug, log: true
            # )
            # # @collection_service.authenticate(producer_info[:agent], producer_info[:password], producer_info[:institution])
            # institution = producer_info[:institution]
            # # Temp fix: adapt institution code to code used in PDS. Need to remove when basic auth is fixed (case #00527632)
            # institution = case institution
            #               when 'KUL'
            #                 'ROSETTA_KULEUVEN'
            #               when 'INS00'
            #                 'ROSETTA'
            #               else
            #                 "ROSETTA_#{institution}"
            #               end
            # handle = rosetta.login(producer_info[:agent], producer_info[:password], institution)
            # raise Teneo::WorkflowAbort, 'Could not log in into Rosetta.' if handle.nil?
            # @collection_service = rosetta.collection_service
          end

          parent_id = item.parent&.properties[:collection_id] if item.parent.is_a?(Teneo::DataModel::WorkItem)
          parent_id ||= create_collection_path(collection_list, item)

          collection_id = find_collection((collection_list + [item.label]).join('/'), item)
          if collection_id
            debug "Found collection '#{item.label}' with id #{collection_id} in Rosetta.", item
          else
            collection_id = create_collection_id(parent_id, collection_list, item.label, item.navigate, item.publish, item)
            debug "Created collection '#{item.label}' with id #{collection_id} in Rosetta.", item
            item.properties[:new] = true
          end
          item.properties[:collection_id] = collection_id
          item.save!
        rescue Libis::Services::ServiceError => e
          raise Teneo::WorkflowError, "Remote call to create collection failed: #{e.message}"
        rescue Exception => e
          raise Teneo::WorkflowError, "Create collection failed: #{e.message} @ #{e.backtrace.first}"
        end

        def create_collection_path(list, item)
          list = list.dup
          return nil if list.blank?
          collection_id = find_collection(list.join('/'))
          return collection_id if collection_id

          collection_name = list.pop
          parent_id = create_collection_path(list, item)
          return nil unless parent_id or list.empty?

          begin
            collection_id = create_collection_id(parent_id, list, collection_name)
            debug "Created collection '#{collection_name}' with id #{collection_id} in Rosetta.", item
            collection_id
          rescue Exception => e
            raise Teneo::WorkflowError, "Could not create collection '#{collection_name}': #{e.message}"
          end
        end

        def create_collection_id(parent_id, collection_list, collection_name, navigate = nil, publish = nil, item = nil)

          # noinspection RubyResolve
          if item&.metadata_record
            # noinspection RubyNilAnalysis
            dc_record = Libis::Metadata::DublinCoreRecord.new item.metadata_record.data
          else
            dc_record = Libis::Metadata::DublinCoreRecord.new
            dc_record.title = collection_name
          end

          # noinspection RubyResolve
          dc_record.isPartOf = collection_list.join('/') unless collection_list.empty?

          collection_data = {}
          collection_data[:name] = collection_name
          collection_data[:description] = 'Created by Ingester'
          collection_data[:parent_id] = parent_id if parent_id
          collection_data[:navigate] = navigate.nil? ? parameter(:navigate) : navigate
          collection_data[:publish] = publish.nil? ? parameter(:publish) : publish
          # noinspection RubyResolve
          collection_data[:external_system] = item&.external_system
          collection_data[:external_id] = item&.external_id
          collection_data[:md_dc] = {
            type: 'descriptive',
            sub_type: 'dc',
            content: dc_record.to_xml,
          }
          # noinspection RubyArgCount
          collection_info = Libis::Services::Rosetta::CollectionInfo.new(collection_data.recursive_cleanup)

          @collection_service.create(collection_info)
        end

        def find_collection(path, item = nil)
          return nil if path.blank?

          collection = @collection_service.find(path)
          return nil unless collection

          if item
            collection.description = item.description
            # noinspection RubyResolve
            collection.navigate = item.navigate unless item.navigate == Libis::Tools::ParameterContainer::NO_VALUE
            # noinspection RubyResolve
            collection.publish = item.publish unless item.publish == Libis::Tools::ParameterContainer::NO_VALUE
            # noinspection RubyResolve
            if item.metadata_record
              dc_record = Libis::Metadata::DublinCoreRecord.new(item.metadata_record.data)
              collection.md_dc.type = 'descriptive'
              collection.md_dc.sub_type = 'dc'
              collection.md_dc.content = dc_record.to_xml
            end

            @collection_service.update(collection)
          end

          collection.id
        rescue Libis::Services::SoapError => e
          unless e.message =~ /no_collection_found_exception/
            raise Teneo::WorkflowError, "Collection lookup failed: #{e.message}"
          end
          nil
        end
      end
    end
  end
end
