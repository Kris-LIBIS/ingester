# frozen_string_literal: true

require 'yaml'
require 'teneo/workflow'
require 'active_record_extended' unless RUBY_PLATFORM == 'java'

module Teneo
  module DataModel
    autoload :AccessRight, 'teneo/data_model/access_right'
    autoload :Collection, 'teneo/data_model/collection'
    autoload :Container, 'teneo/data_model/container'
    autoload :ConversionTask, 'teneo/data_model/conversion_task'
    autoload :ConversionWorkflow, 'teneo/data_model/conversion_workflow'
    autoload :Converter, 'teneo/data_model/converter'
    autoload :DirItem, 'teneo/data_model/dir_item'
    autoload :FileItem, 'teneo/data_model/file_item'
    autoload :Format, 'teneo/data_model/format'
    autoload :IngestAgreement, 'teneo/data_model/ingest_agreement'
    autoload :IngestModel, 'teneo/data_model/ingest_model'
    autoload :IngestStage, 'teneo/data_model/ingest_stage'
    autoload :IngestWorkflow, 'teneo/data_model/ingest_workflow'
    autoload :IntellectualEntity, 'teneo/data_model/intellectual_entity'
    autoload :Item, 'teneo/data_model/item'
    autoload :ItemGroup, 'teneo/data_model/item_group'
    autoload :MaterialFlow, 'teneo/data_model/material_flow'
    autoload :Membership, 'teneo/data_model/membership'
    autoload :MessageLog, 'teneo/data_model/message_log'
    autoload :MetadataRecord, 'teneo/data_model/metadata_record'
    autoload :Organization, 'teneo/data_model/organization'
    autoload :Package, 'teneo/data_model/package'
    autoload :Parameter, 'teneo/data_model/parameter'
    autoload :ParameterReference, 'teneo/data_model/parameter_reference'
    autoload :Producer, 'teneo/data_model/producer'
    autoload :Representation, 'teneo/data_model/representation'
    autoload :RepresentationDef, 'teneo/data_model/representation_def'
    autoload :RepresentationInfo, 'teneo/data_model/representation_info'
    autoload :RetentionPolicy, 'teneo/data_model/retention_policy'
    autoload :Run, 'teneo/data_model/run'
    autoload :SeedLoader, 'teneo/data_model/seed_loader'
    autoload :StageTask, 'teneo/data_model/stage_task'
    autoload :StageWorkflow, 'teneo/data_model/stage_workflow'
    autoload :StatusLog, 'teneo/data_model/status_log'
    autoload :Storage, 'teneo/data_model/storage'
    autoload :StorageResolver, 'teneo/data_model/storage_resolver'
    autoload :StorageType, 'teneo/data_model/storage_type'
    autoload :Task, 'teneo/data_model/task'
    autoload :User, 'teneo/data_model/user'
    autoload :WithParameters, 'teneo/data_model/with_parameters'

    def self.root
      File.expand_path('../..', __dir__)
    end
  end
end

require_relative 'data_model/storage_driver'
