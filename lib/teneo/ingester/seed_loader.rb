# frozen_string_literal: true

require 'libis/tools/extend/hash'
require 'teneo/data_model/seed_loader'
require 'teneo/ingester/config'

require 'awesome_print'

module Teneo
  module Ingester
    class SeedLoader < Teneo::DataModel::SeedLoader

      def load
        load_tasks
        load_converters
      end

      def load_tasks
        class_list = Teneo::Ingester::Tasks::Base::Task.task_classes -
            [Teneo::Ingester::Converters::Base::Converter] - Teneo::Ingester::Converters::Base::Converter.task_classes
        return unless class_list.size > 0
        spinner = create_spinner('task')
        spinner.auto_spin
        spinner.update(file: '...', name: '')
        spinner.start
        spinner.update(file: "from task classes", name: '')
        class_list.map do |task_class|
          info = { name: task_class.taskname }
          spinner.update(name: "object '#{info[:name]}'")
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
          info = info.recursive_cleanup
          # ap info
          Teneo::DataModel::Task.from_hash(info)
        end
        spinner.update(file: '- Done', name: '!')
        spinner.success
      end

      def load_converters
        class_list = Teneo::Ingester::Converters::Base::Converter.task_classes.reject {|x|x.name =~ /::Base::/}
        return unless class_list.size > 0
        spinner = create_spinner('converter')
        spinner.auto_spin
        spinner.update(file: '...', name: '')
        spinner.start
        spinner.update(file: "from task classes", name: '')
        class_list.map do |task_class|
          info = { name: task_class.taskname }
          spinner.update(name: "object '#{info[:name]}'")
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
          info = info.recursive_cleanup
          # ap info
          Teneo::DataModel::Converter.from_hash(info)
        end
        spinner.update(file: '- Done', name: '!')
        spinner.success
      end

    end
  end
end