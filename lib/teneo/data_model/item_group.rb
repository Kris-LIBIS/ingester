# frozen_string_literal: true

module Teneo::DataModel
  class ItemGroup < Teneo::DataModel::Item

    include Teneo::DataModel::Container

    def namepath
      parent.namepath
    end

  end
end
