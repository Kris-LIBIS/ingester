# frozen_string_literal: true

require_relative 'base/selecter'

module Teneo
  module Ingester
    module Converters

      class ThumbnailSelector < Teneo::Ingester::Converters::Base::Selecter

        description 'Selects the thumbnail source item'

        help_text <<~STR
          The first file item in the list will be selected unless
        STR

        protected

        def select_items(items, group)
          thumbnail = items.where('options @> ?', { use_as_thumbnail: true }.to_json).first
          thumbnail ||= items.first
          thumbnail = thumbnail.dup
          group << thumbnail
          # FileItem is duplicated, but the file itself is not, so the new Item does not own the file
          thumbnail.own_file(false)
          thumbnail.save!
        end

      end
    end
  end
end
