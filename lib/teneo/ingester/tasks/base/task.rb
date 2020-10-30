# frozen_string_literal: true
require "teneo/workflow/task"
require "teneo/ingester"

require "kramdown"
require "active_support/core_ext/string/inflections"

module Teneo
  module Ingester
    module Tasks
      module Base
        class Task < ::Teneo::Workflow::Task
          def self.taskname(name = nil)
            @taskname = name if name
            @taskname || self.name.split("::").last
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
            @itemtypes || superclass.item_types rescue [Teneo::DataModel::Package, Teneo::DataModel::Item]
          end

          def allowed_item_types
            self.class.item_types
          end

          def execute(item, *args)
            item = super
            item&.reload
            item
          end

          def self.task_classes
            #noinspection RubyArgCount
            ObjectSpace.each_object(::Class).select do |klass|
              klass < self && klass.name.deconstantize != "Teneo::Ingester::Tasks::Base"
            end
          end

          def short_name
            name.gsub(/[^\w\s._-]/, "").underscore.split(/[\s._-]+/).map(&:capitalize).join
          end

          protected

          def pre_process(item, *_args)
            return false unless check_item_type(item, raise_on_error: false)
            item.reload
            super
          end

          def post_process(item, *_args)
            item.save!
            # item.reload
          end

          def match_to_hash(m)
            return {} unless m
            Hash[(0...m.size).map { |i| "m#{i}".to_sym }.zip(m.to_a)]
          end

          def add_log_entry(severity, item, msg, *args)
            message = (msg % args rescue "#{msg}#{args.empty? ? "" : " - #{args}"}")
            message, *stack_trace = message.split("\n")
            Teneo::DataModel::MessageLog.create(
              severity: severity,
              item: item.is_a?(Teneo::DataModel::WorkItem) ? item : nil,
              run: self.run,
              task: namepath,
              message: message,
              data: {
                item_name: (item || run.job).namepath,
                stack_trace: stack_trace.empty? ? nil : stack_trace,
              }.compact,
            )
          end
        end
      end
    end
  end
end
