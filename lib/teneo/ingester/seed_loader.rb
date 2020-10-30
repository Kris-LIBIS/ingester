# frozen_string_literal: true

require 'libis/tools/extend/hash'
require 'teneo/data_model/seed_loader'
require 'teneo/ingester/config'

require 'awesome_print'

module Teneo
  module Ingester
    class TaskLoader < Teneo::DataModel::SeedLoader

      def load_tasks
        load_classes class_list: Teneo::Ingester::Tasks::Base::Task.task_classes -
            [Teneo::Ingester::Converters::Base::Task] - Teneo::Ingester::Converters::Base::Task.task_classes,
                     to_class: :task, from_class: :task do |task_class|
          info = { name: task_class.taskname }
          # spinner.update(name: "object '#{info[:name]}'")
          info[:stage] = task_class.taskgroup.to_s.camelize
          info[:class_name] = task_class.name
          info[:description] = task_class.description
          info[:help] = task_class.help_text
          info[:parameters] = task_class.parameter_defs.each_with_object({}) do |(param_name, param_def), result|
            next if param_def.frozen
            param_info = { name: param_def.name }
            param_info[:export] = true
            param_info[:default] = param_def.default
            param_info[:data_type] = param_def.datatype
            param_info[:constraint] = param_def.constraint.to_s
            param_info[:description] = param_def.description
            param_info[:help] = param_def.options[:help]
            result[param_name] = param_info.cleanup
          end
          info
        end
      end

      def load_converters
        load_classes class_list: Teneo::Ingester::Converters::Base::Task.task_classes.reject {|x|x.name =~ /::Base::/},
                     to_class: :converter, from_class: :converter do |task_class|
          info = { name: task_class.taskname }
          # spinner.update(name: "object '#{info[:name]}'")
          info[:category] = task_class.taskgroup.to_s
          info[:class_name] = task_class.name
          info[:description] = task_class.description
          info[:help] = task_class.help_text
          info[:input_formats] = task_class.input_formats
          info[:output_formats] = task_class.output_formats
          info[:parameters] = task_class.parameter_defs.each_with_object({}) do |(param_name, param_def), result|
            next if param_def.frozen
            param_info = { name: param_def.name }
            param_info[:export] = param_def.to_h.fetch(:export, true)
            param_info[:default] = param_def.default
            param_info[:data_type] = param_def.datatype
            param_info[:constraint] = param_def.constraint.to_s
            param_info[:description] = param_def.description
            param_info[:help] = param_def.options[:help]
            result[param_name] = param_info.cleanup
          end
          info
        end
      end

      protected

      def string_to_class(klass_name)
        "Teneo::Ingester::#{klass_name.to_s.classify}".constantize
      rescue NameError
        super
      end

    end
  end
end