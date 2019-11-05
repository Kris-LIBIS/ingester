# frozen_string_literal: true
require 'libis/workflow/task'
require 'teneo/ingester'

require 'kramdown'

module Teneo
  module Ingester
    module Tasks
      module Base

        class Task < ::Libis::Workflow::Task

          def self.taskname(name = nil)
            @taskname = name if name
            @taskname || self.name.split('::').last
          end

          def self.taskgroup(name = nil)
            @taskgroup = name if name
            @taskgroup || superclass.taskgroup rescue nil
          end

          def self.description(text = nil)
            @description = text if text
            @description
          end

          def self.help_text(text = nil)
            @helptext = text if text
            @helptext
          end

          def self.help_html
            Kramdown::Document.new(help_text).to_html
          end

          def self.item_types(*array)
            @itemtypes = array unless array.empty?
            @itemtypes || superclass.item_types rescue [Teneo::DataModel::Package, Teneo::Ingester::WorkItem]
          end

          def allowed_item_types
            self.class.item_types
          end

          def execute(item, *args)
            item = super
            item&.reload
            item
          end

          protected

          def pre_process(item, *_args)
            return false unless check_item_type(item, raise_on_error: false)
            item.reload
            super
          end

          def post_process(item, *_args)
            item.save!
            item.reload
          end

          def match_to_hash(m)
            return {} unless m
            Hash[(0...m.size).map {|i| "m#{i}".to_sym}.zip(m.to_a)]
          end

        end
      end
    end
  end
end
