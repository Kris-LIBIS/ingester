# frozen_string_literal: true

require 'method_source'
require 'libis/tools/extend/hash'
require 'libis/tools/extend/array'

module Teneo
  module DataModel
    class SeedLoader
      attr_reader :prompt, :tty, :quiet

      def initialize(tty: true, quiet: false)
        @tty = tty
        @quiet = quiet
        @prompt = NoPrompt.new if quiet
        require 'tty-prompt' rescue nil
        @prompt ||= TTY::Prompt.new if tty && defined?(TTY::Prompt)
        @prompt ||= StdoutPrompt.new('')
      end

      def load_dir(dir)
        load_storage_types
        load_files dir: dir, klass_name: :format
        load_files dir: dir, klass_name: :access_right
        load_files dir: dir, klass_name: :retention_policy
        load_files dir: dir, klass_name: :representation_info
        load_files dir: dir, klass_name: :producer
        load_files dir: dir, klass_name: :material_flow
        load_files dir: dir, klass_name: :converter
        load_files dir: dir, klass_name: :organization
        load_files dir: dir, klass_name: :user
        load_files dir: dir, klass_name: :membership
        load_files dir: dir, klass_name: :ingest_agreement
        load_files dir: dir, klass_name: :task
        load_files dir: dir, klass_name: :stage_workflow
        load_files dir: dir, klass_name: :ingest_workflow
        load_files dir: dir, klass_name: :ingest_model
        load_files dir: dir, klass_name: :package
      end

      def load_storage_types
        load_classes class_list: Teneo::DataModel::StorageDriver::Base.drivers,
                     to_class: :storage_type, from_class: :storage_driver do |driver|
          info = {
            protocol: driver.protocol,
            driver_class: driver.name,
            description: driver.description,
          }
          initializer = driver.instance_method(:initialize)
          defaults = initializer.source.match(/^\s*def\s+initialize\s*\(\s*(.*)\s*\)/)[1].gsub("\n", '')
          defaults = JSON.parse Hash[defaults.scan(/\s*(\w+):\s*([^,]+)(?:,|$)/)].to_s.
                                  gsub('=>', ' : ').gsub(/\\"|'/, '')
          r = /^\s*#\s*@param\s+\[([^\]]*)\]\s+(\w+)\s+(.*)$/
          info[:parameters] = initializer.comment.scan(r).map do |datatype, name, description|
            {
              name: name,
              data_type: datatype,
              default: defaults[name],
              description: description,
            }
          end.each_with_object({}) do |param, hash|
            hash[param.delete(:name)] = param
          end
          info
        end
      end

      protected

      class NoPrompt
        def initialize(*args)
        end

        def method_missing(name, *args)
        end
      end

      class StdoutPrompt < NoPrompt
        def initialize(mask, *args)
          @mask = mask
        end

        def update(opts = {})
          puts @mask + opts.values.join(' ')
        end

        def error(msg)
          puts "ERROR: #{msg}"
        end
      end

      def create_spinner(klass_name)
        if quiet
          NoPrompt.new
        elsif tty
          require 'tty-spinner'
          TTY::Spinner::new("[:spinner] Loading #{klass_name}(s) :file :name", interval: 4)
        else
          StdoutPrompt.new("Loading #{klass_name}(s) ")
        end
      end

      def string_to_class(klass_name)
        "Teneo::DataModel::#{klass_name.to_s.classify}".constantize
      end

      def load_files(dir:, klass_name:)
        klass = string_to_class(klass_name)
        begin
          file_list = Dir.children(dir).select { |f| f =~ /\.#{klass_name}\.yml$/ }.sort
        rescue Errno::ENOENT
          return
        rescue StandardError => e
          puts "WARNING: #{e.class.name} - #{e.message}"
          return
        end
        return unless file_list.size > 0
        spinner = create_spinner(klass_name)
        spinner.auto_spin
        spinner.update(file: '...', name: '')
        spinner.start
        file_list.each do |filename|
          spinner.update(file: "from '#{filename}'", name: '')
          path = File.join(dir, filename)
          data = YAML.load_file(path)
          case data
          when Array
            data.each do |x|
              x.deep_symbolize_keys!
              (n = x[:name] || x[x.keys.first]) && spinner.update(name: "object '#{n}'")
              klass.from_hash(x)
            end
          when Hash
            x = data.deep_symbolize_keys
            (n = x[:name] || x[x.keys.first]) && spinner.update(name: "object '#{n}'")
            klass.from_hash(x)
          else
            prompt.error 'Illegal file content: \'path\' - either Array or Hash expected.'
          end
        end
        spinner.update(file: '- Done', name: '!')
        spinner.success
      end

      def load_classes(class_list:, to_class:, from_class: nil)
        return unless class_list.size > 0
        spinner = create_spinner(to_class)
        spinner.auto_spin
        spinner.update(file: '...', name: '')
        spinner.start
        spinner.start
        spinner.update(file: "from #{from_class || to_class} classes", name: '')
        klass = string_to_class(to_class)
        class_list.map do |class_item|
          spinner.update(name: "object '#{class_item.name}'")
          info = yield(class_item).recursive_cleanup
          klass.from_hash(info)
        end
        spinner.update(file: '- Done', name: '!')
        spinner.success
      end
    end
  end
end
