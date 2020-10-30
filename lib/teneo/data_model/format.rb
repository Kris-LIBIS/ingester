# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  class Format < Base
    self.table_name = 'formats'

    CATEGORY_LIST = %w'ARCHIVE AUDIO EMAIL IMAGE PRESENTATION TABULAR TEXT VIDEO OTHER'

    def self.all_tags
      result = []
      CATEGORY_LIST.each do |category|
        result << category
        result += self.where(category: category).pluck(:name)
      end
      result
    end

    validates :name, :category, :mimetypes, :extensions, presence: true
    validates :name, uniqueness: true
    validates :category, inclusion: {in: CATEGORY_LIST}

    array_field :extensions
    array_field :mimetypes
    array_field :puids

  end

end
