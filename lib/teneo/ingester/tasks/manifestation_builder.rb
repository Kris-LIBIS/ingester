# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class ManifestationBuilder < Teneo::Ingester::Tasks::Base::Task
        include Base::Format

        taskgroup :pre_ingest

        parameter on_convert_error: 'FAIL', type: :string, constraint: %w'FAIL DROP COPY',
                  description: 'Action to take when a file conversion fails.',
                  help: <<~STR
                    Valid values are:

                    FAIL
                    : report this as an error and stop processing the item

                    DROP
                    : report this as an error and continue without the file

                    COPY
                    : report the error and copy the source file instead

                     Note that dropping the file may cause errors later, e.g. with empty representations.
        STR

        recursive true
        item_types Teneo::Ingester::IntellectualEntity

        attr_reader :conversion_runners

        def initialize(cfg = {})
          @conversion_runners = {}
          super
        end

        protected

        def process(item, *_args)

          status_progress(item: item, progress: 0, max: item.ingest_model.representations.count)

          # Build all manifestations
          item.ingest_model.representations.each do |representation|
            debug 'Building representation %s', item, representation.representation_info.name
            # Check if representation exists
            rep = item.representation(representation.name)
            unless rep
              # create new representation
              rep = Teneo::Ingester::Representation.new
              rep.representation_info = representation.representation_info
              rep.access_right = representation.access_right
              rep.name = representation.name
              #rep.label = representation.label
              rep.parent = item
              rep.save!
            end
            set_item_status(status: :started, item: rep)
            build_representation(rep, representation)
            if rep.items.size == 0
              if representation.optional
                warn "Manifestation %s '%s' is marked optional and no items were found. Representation will not be created.",
                     item, representation.name, representation.label
                set_item_status(status: :done, item: rep)
                rep.destroy!
              else
                error "Representation %s is empty.", item, rep.name
                set_item_status(item: rep, status: :failed)
                raise Teneo::Ingester::WorkflowError, 'Could not find content for representation %s.' % [rep.name]
              end
            else
              merge_items(rep)
              set_item_status(item: rep, status: :done)
            end
            status_progress(item: rep)
          end

          stop_recursion

        end

        private

        # noinspection RubyResolve
        # @param [Teneo::Ingester::Representation] rep representation that is being created
        # @param [Teneo::DataModel::Representation] rep_def representation definition
        def build_representation(rep, rep_def)

          # Get the source files either from the given representation or the originals
          from_rep_def = rep_def.from
          source_rep = from_rep_def &&
              rep.parent.representation(from_rep_def.name)
          source_items = source_rep&.items || rep.parent.originals

          # Perform each conversion workflow
          rep_def.conversion_workflows.each do |workflow|

            # Get/build the task group that will execute the conversion workflow
            conversion = conversion_runners[workflow.id] ||
                begin
                  tasks_info = workflow.tasks_info
                  runner = Teneo::Ingester::ConversionRunner.new(
                      name: workflow.name,
                      parameters: {
                          formats: workflow.input_formats,
                          filename: workflow.input_filename_regex,
                          keep_structure: workflow.copy_structure,
                          copy: workflow.copy_files,
                          on_convert_error: parameter(:on_convert_error)
                      }
                  )
                  runner.parent = self
                  runner.configure_tasks(tasks_info)
                  conversion_runners[workflow.id] = runner
                  runner
                end

            group = rep.items.where(name: workflow.name)
                        .where('options @> ?', { conversion_id: workflow.id }.to_json).first

            if group
              if group.last_status(conversion) == :done
                debug 'Conversion workflow %s allready done. Skipping.', group, workflow.name
                next
              end
              debug 'Retrying workflow %s. Cleaning up previous partial results.', group, workflow.name

              group.items.find_each(batch_size: 100) { |i| i.destroy! }
              group.save!
            else
              group = Teneo::Ingester::ItemGroup.new(name: workflow.name)
              rep << group
              group.options[:conversion_id] = workflow.id
              group.save!
              debug 'Created new group for conversion workflow %s.', group, workflow.name
            end

            debug 'Processing conversion workflow %s', rep, workflow.name

            conversion.execute(group, source_items: source_items)

            register_files(group)

          end
        end

        def merge_items(target, source = nil)
          return target.groups.each do |group|
            merge_items(target, group)
            group.destroy!
          end unless source
          source.files.each { |file| target.move_item(file) }
          source.dirs.each do |dir|
            (d = target.dirs.find_by(name: dir.name)) ? merge_items(d, dir) : target.move_item(dir)
          end
        end

        def register_files(item)
          if item.is_a?(Teneo::Ingester::FileItem)
            item.properties[:group_id] = add_file_to_registry(item.label)
            item.save!
          else
            item.items.find_each(batch_size: 100) { |file| register_files(file) }
          end
        end

        private

        def add_file_to_registry(name)
          @file_registry ||= {}
          return @file_registry[name] if @file_registry.has_key?(name)
          @file_registry[name] = @file_registry.count + 1
        end

      end

    end
  end
end
