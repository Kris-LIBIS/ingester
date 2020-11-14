# frozen_string_literal: true

require_relative 'base'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class IngestModel < Base
    self.table_name = 'ingest_models'

    belongs_to :ingest_agreement, inverse_of: :ingest_models

    has_many :representation_defs, -> { rank(:position) }, dependent: :destroy

    # self-reference #template
    has_many :derivatives, class_name: Teneo::DataModel::IngestModel.name, dependent: :destroy,
                           inverse_of: :template,
                           foreign_key: :template_id
    belongs_to :template, class_name: Teneo::DataModel::IngestModel.name,
                          inverse_of: :derivatives, optional: true

    # code tables
    belongs_to :retention_policy
    belongs_to :access_right

    validates :name, uniqueness: { scope: :ingest_agreement_id }
    validates :access_right_id, :retention_policy_id, presence: true
    validate :template_reference

    def organization
      ingest_agreement&.organization
    end

    def template_reference
      return if template.nil?
      errors.add(:template_id, 'should be a template') unless template.ingest_agreement.nil?
    end

    def self.from_hash(hash, id_tags = [:ingest_agreement_id, :name])
      agreement_name = hash.delete(:ingest_agreement)
      query = agreement_name ? { name: agreement_name } : { id: hash[:ingest_agreement_id] }
      ingest_agreement = record_finder Teneo::DataModel::IngestAgreement, query
      hash[:ingest_agreement_id] = ingest_agreement.id

      representation_defs = hash.delete(:representations)

      super(hash, id_tags) do |item, h|
        item.access_right = record_finder Teneo::DataModel::AccessRight, name: h.delete(:access_right)
        item.retention_policy = record_finder Teneo::DataModel::RetentionPolicy, name: h.delete(:retention_policy)
      end.tap do |item|
        if representation_defs
          old = item.representation_defs.map(&:id)
          representation_defs.each_with_index do |representation_def, i|
            representation_def[:ingest_model_id] = item.id
            # representation[:position_position] = i + 1
            Teneo::DataModel::RepresentationDef.from_hash(representation_def)
          end
          (old - item.representation_defs.map(&:id)).each { |id| item.representation_defs.find(id)&.destroy! }
          item.save!
        end
      end
    end
  end
end
