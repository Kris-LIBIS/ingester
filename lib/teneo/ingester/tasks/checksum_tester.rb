# frozen_string_literal: true

require 'libis-tools'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks
      class ChecksumTester < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_process

        description 'Check the checksum of FileItem objects.'

        help_text <<~STR
                    This preprocessor task calculates the checksum of a file if the 'checksum_type' parameter is filled in. See the
                    parameter's definition for a list of supported checksum algorithms.

                    By also filling in a value for the 'checksum_file' parameter, you can supply a file with known checksums for 
                    each file. The task will then also verify the calculated checksum with the one in the file and report an error
                    if there is a mismatch.

                    If the 'checksum_file' file cannot be found/read, checksum testing is skipped.
                  STR

        parameter checksum_type: nil,
                  description: 'Checksum type to use.',
                  constraint: ::Libis::Tools::Checksum::CHECKSUM_TYPES.map { |x| x.to_s }
        parameter checksum_file: nil,
                  description: 'File with pairs of file names and checksums.'

        recursive true
        item_types Teneo::DataModel::FileItem

        protected

        def process(item, *_args)
          check_exists item
          check_checksum item
        end

        private

        def check_exists(item)
          raise Teneo::WorkflowError, "File '#{item.fullpath}' does not exist." unless File.exists? item.fullpath
        end

        def check_checksum(item)
          checksum_type = parameter(:checksum_type)

          if checksum_type.nil?
            self.class.parameters[:checksum_type].constraint.each do |x|
              test_checksum(item, x) if item.checksum(x)
            end
          else
            checksumfile_path = parameter(:checksum_file)
            if checksumfile_path
              unless File.exist?(checksumfile_path)
                checksumfile_path = File.join(File.dirname(item.fullpath), checksumfile_path)
                unless File.exist?(checksumfile_path)
                  warn "Checksum file '#{checksumfile_path}' not found. Skipping check.", item
                  return
                end
              end
              lines = %x(grep #{item.name} #{checksumfile_path})
              if lines.empty?
                warn "File '#{item.name}' not found in checksum file ('#{checksumfile_path}'. Skipping check.", item
                return
              end
              file_checksum = ::Libis::Tools::Checksum.hexdigest(item.fullpath, checksum_type.to_sym)
              test_checksum(item, checksum_type) if item.checksum(checksum_type)
              item.set_checksum(checksum_type, file_checksum)
              # we try to match any line as there may be multiple lines containing the file name. We also check any field
              # on a line as the checksum file format may differ (e.g. Linux vs Windows).
              lines.split.each do |expected|
                begin
                  test_checksum item, checksum_type, expected
                  debug 'Checksum matched.', item
                  return # match found. File is OK.
                rescue
                  next
                end
              end
              set_item_status(status: :failed, item: item)
              raise Teneo::WorkflowError, "#{checksum_type} checksum file test failed for #{item.filepath}."
            else
              test_checksum(item, checksum_type)
            end
          end
        end

        def test_checksum(item, checksum_type, expected = nil)
          expected ||= item.checksum(checksum_type)
          checksum = ::Libis::Tools::Checksum.hexdigest(item.fullpath, checksum_type.to_sym)
          expected ||= item.set_checksum(checksum_type, checksum)
          item.save!
          return if expected == checksum
          set_item_status(status: :failed, item: item)
          raise Teneo::WorkflowError, "Calculated #{checksum_type} checksum does not match expected checksum."
        end
      end
    end
  end
end
