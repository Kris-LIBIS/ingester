# frozen_string_literal: true

module Teneo
  module Ingester
    class ItemGroup < Teneo::Ingester::WorkItem

      include Teneo::Ingester::Container

      def namepath
        parent.namepath
      end

    end
  end
end
