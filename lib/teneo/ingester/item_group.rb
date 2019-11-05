# frozen_string_literal: true

module Teneo
  module Ingester
    class ItemGroup < Teneo::Ingester::WorkItem

      include Teneo::Ingester::Container

      def work_dir
        ''
      end

    end
  end
end
