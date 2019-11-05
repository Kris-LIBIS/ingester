# frozen_string_literal: true

require 'libis-format'

require 'teneo/ingester/tasks/base/task'

module Teneo
  module Ingester
    module Converters
      module Base

        class Converter < Teneo::Ingester::Tasks::Base::Task

          taskgroup :converter
          recursive true
          item_types Teneo::Ingester::FileItem

          parameter format: nil, datatype: :string, description: 'Target format type'

          def action
            parent.action
          end

          def action=(value)
            parent.action = value
          end

          def self.converter_class(klass = nil)
            @converter_class = klass if klass
            @converter_class
          end

          def self.input_formats(*formats)
            @input_formats = formats unless formats.empty?
            @input_formats || converter_class&.input_types&.map(&:to_s) || []
          end

          def self.output_formats(*formats)
            @output_formats = formats unless formats.empty?
            @output_formats || converter_class&.output_types&.map(&:to_s) || []
          end

          protected

          def extract_options(args)
            options = args.last
            options.is_a?(Hash) ? options.dup : {}
          end

          def pre_process(item, *_args)
            return false unless check_item_type(item, raise_on_error: false)
            super
          end

          def post_process(item, *_args)
            item.save!
            item.reload
          end

          def process(item, *_args)
            unless (format = parameter(:format))
              error 'Converter target format not specified', item
              raise WorkflowError, 'Converter target format not specified'
            end
            target = target_name(item, format)
            Libis::Format::Converter::Base.using_temp(target) do |target_temp|
              convert(item.fullpath, target_temp, format)
              item.delete_file
              true
            end
            item.filename = target
            item.own_file(true)
            item
          end

          def target_name(item, format)
            ie = item.find_parent(Teneo::Ingester::IntellectualEntity)
            rep = item.find_parent(Teneo::Ingester::Representation)
            filename = [item.name, rep.name, extname(format)].join('.')
            File.join(work_dir, ie.name, filename)
          end

          def tempname(source_file, target_format)
            Dir::Tmpname.create(
                [File.basename(source_file, '.*'), ".#{extname(target_format)}"],
                Teneo::Ingester::Config.tempdir
            ) {}
          end

          def extname(format)
            Libis::Format::Library.get_field(format, :extensions).first
          end

        end
      end
    end
  end
end
