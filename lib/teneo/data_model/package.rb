# frozen_string_literal: true

require_relative "base"
require_relative "serializers/hash_serializer"
require_relative "storage_resolver"

module Teneo::DataModel

  # noinspection RailsParamDefResolve,RubyYardReturnMatch
  class Package < Base
    include Teneo::Workflow::Job

    self.table_name = "packages"

    belongs_to :ingest_workflow

    has_many :items, -> { rank(:position) }, as: :parent, class_name: "Teneo::DataModel::Item", dependent: :destroy
    has_many :runs, -> { order(id: :asc) }, inverse_of: :package, dependent: :destroy

    has_many :parameter_values, as: :with_values, class_name: "Teneo::DataModel::ParameterValue", dependent: :destroy

    validate :safe_name

    serialize :options, Serializers::HashSerializer

    include StorageResolver

    def organization
      ingest_workflow&.organization
    end

    include WithParameters

    def parameter_children
      [ingest_workflow]
    end

    before_destroy :delete_work_dir

    def delete_work_dir
      #noinspection RubyArgCount
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(ingest_workflow.work_dir, name)
    end

    def ingest_dir
      File.join(ingest_workflow.ingest_dir, name)
    end

    def log_dir
      File.join(ingest_workflow.log_dir, name)
    end

    def parents
      []
    end

    def filelist
      []
    end

    def tasks
      ingest_workflow.tasks_info(parameters_list)
    end

    def make_run(opts = {})
      run = Teneo::DataModel::Run.create(name: run_name, package: self, options: opts)
      runs << run
      run.save!
      run
    end

    def last_run
      runs.order_by(id: :desc).first
    end

    def <<(item)
      item.parent = self
      item.insert_at :last
    end

    alias add_item <<

    def each(&block)
      items.each(&block)
    end

    def size
      items.size
    end

    alias count size

    def item_list
      items.reload
      items.to_a
    end

    def producer
      ingest_workflow.ingest_agreement.producer
    end

    def material_flow
      ingest_workflow.ingest_agreement.material_flow
    end

    def self.from_hash(hash, id_tags = [:ingest_workflow_id, :name])
      ingest_workflow_name = hash.delete(:ingest_workflow)
      query = ingest_workflow_name ? { name: ingest_workflow_name } : { id: hash[:ingest_workflow_id] }
      ingest_workflow = record_finder Teneo::DataModel::IngestWorkflow, query
      hash[:ingest_workflow_id] = ingest_workflow.id

      params = params_from_values(ingest_workflow.name, hash.delete(:values))

      super(hash, id_tags).params_from_hash(params)
    end
  end
end
