# frozen_string_literal: true

require 'libis-format'

require 'teneo/ingester/tasks/base/task'
require 'teneo/ingester/tasks/base/format'

module Teneo
  module Ingester
    module Converters
      module Base

        class Task < Teneo::Ingester::Tasks::Base::Task

          include Teneo::Ingester::Tasks::Base::Format

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

          def check_format(item)
            return true if self.class.input_formats.include?(item.properties[:format_type].to_s)
            warn "File format %s is not supported", item, item.properties[:format_type]
            false
          end

          def post_process(item, *_args)
            item.save!
            item.reload
          end

          def target_name(item, format)
            rep = item.find_parent(Teneo::Ingester::Representation)
            filename = [File.basename(item.name, '.*'), short_name, extname(format)].join('.')
            File.join(item.work_dir, filename)
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

          def identify(item)
            format_list = Libis::Format::Identifier.get(item.fullpath, tool: :fido)
            process_messages(format_list, item)
            apply_formats(item, format_list[:formats])
          end

        end
      end
    end
  end
end
