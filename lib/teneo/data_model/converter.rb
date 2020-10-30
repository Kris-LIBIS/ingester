# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection ALL
  class Converter < Base
    self.table_name = 'converters'

    CATEGORY_LIST = %w'selecter converter assembler splitter'

    has_many :conversion_tasks

    include WithParameters

    array_field :input_formats
    array_field :output_formats

    validate :safe_name
    validates :category, inclusion: {in: CATEGORY_LIST}

    def self.from_hash(hash, id_tags = [:name])
      params = hash.delete(:parameters)
      super(hash, id_tags).params_from_hash(params)
    end
  end

end
