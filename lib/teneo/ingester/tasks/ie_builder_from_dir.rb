# frozen_string_literal: true

require_relative "base/task"

module Teneo
  module Ingester
    module Tasks
      class IeBuilderFromDir < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_ingest

        description "Generate IEs from directories."

        help_text <<~STR
                    Any item groups found will be converted into IntellectualEntity items. Item groups that are themselves
                    contained in an IntellectualEntity will be left alone.
                  STR

        parameter dir_mode: "root", constraint: %w'root leaf',
                  description: "How the directory tree will be parsed and which directories will be selected.",
                  help: "root will select the top-level directories and leaf will select the lowest level ones."

        recursive true
        item_types Teneo::DataModel::DirItem

        protected

        def pre_process(item, *_args)
          if check_item_type(item, Teneo::DataModel::IntellectualEntity, raise_on_error: false)
            stop_recursion
            return false
          end
          super
        end

        def process(item, *_args)
          case parameter(:dir_mode)
          when "top"
            stop_recursion
          when "leaf"
            return item if item.dirs.size > 0
            stop_recursion
          else
            return item
          end
          debug "Converting DirItem into an IE", item
          # ItemGroup objects are replaced with the IE
          item.becomes!(Teneo::DataModel::IntellectualEntity)
        end
      end
    end
  end
end
