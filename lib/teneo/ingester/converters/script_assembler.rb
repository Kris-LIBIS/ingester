# frozen_string_literal: true

require "libis/tools/command"
require "libis/tools/extend/hash"

require_relative "base/assembler"

module Teneo
  module Ingester
    module Converters
      class ScriptAssembler < Teneo::Ingester::Converters::Base::Assembler
        description "Execute a script to assemble a file"
        help_text <<~STR
                    The given script will be executed and given at least 3 arguments:

                    - $1
                      : a filewith source file absolute paths, 1 file per line
                    - $2
                      : the target file as absolute path
                    - $3
                      : the target format as given by the format parameter

                    The target file path will be a temporary file name and will be moved to a more appropriate file name after
                    successful conversion. If the options parameter contains a Hash, its content will be supplied as extra 
                    arguments as follows:

                        script_name source_list_file target_file format -key1 value1 -key2 -key3 value3 

                    With options = {key1: value1, key2: nil, key3: value3}. Note that an empty value in the Hash will suppress its
                    value output, but not its key output on the command-line. This is how you can pass flags to your script.

                    The script should return 0 for success, any other value for failure. Messages printed on stderr will be logged
                    as warnings, messages on stdout as info logs. The script is expected to create a new file for the given
                    target file path as the source files will be deleted after the successful assembly and the target file may
                    be deleted later because of furher conversions or migrations.
                  STR

        parameter script_name: nil, description: "name of the script to execute"
        parameter options: nil, datatype: "hash", description: "options to be passed on to the script"
        parameter timeout: nil, datatype: "int", description: "How long to wait for the script to return in seconds",
                  help: <<~STR
                    The ingester will wait for the given amount of seconds and send a SIGTERM signal when the timeout
                    has passed and no answer has yet been received.
                  STR
        parameter kill_after: nil, datatype: "int", description: "How long to wait until the script is killed",
                  help: <<~STR
                    The ingester will wait for the given amount of seconds after the timeout and send a SIGKILL signal
                    when the time has passed and still the script did not stop. The kill_after is a grace-period in
                    which we allow the script to termninate befor we brute-force kill it.
                  STR

        protected

        def assemble(source_paths, target_path, format)
          script_name = parameter(:script_name)
          unless script_name && File.exists?(script_name)
            error "Script file '#{script_name}' not found", item
            raise Teneo::WorkflowAbort, "Fatal error processing convert script"
          end
          source_list = Dir::Tmpname.create(
            %w(source .txt),
            Teneo::DataModel::Config.tempdir
          ) { }
          source_list.open("w") do |f|
            source_paths.each do |p|
              f.write "#{p}\n"
            end
          end
          cmd = [script_name, source_list, target_path, format]
          (parameter(:options) || {}).each do |k, v|
            cmd << "-#{k}"
            cmd << v.to_s unless v.nil? || (v.respond_to?(:empty?) && v.empty?) || (v.respond_to?(:blank?) && v.blank?)
          end
          options = {
            timeout: parameter(:timeout),
            kill_after: parameter(:kill_after),
          }.compact
          result = Libis::Tools::Command.run(*cmd, options)
          if result[:timeout]
            error "The script file '%s' ran more than %d seconds and was stopped by the ingester.", item,
                  script_name, parameter(:timeout)
            raise Teneo::WorkflowError, "Error processing convert script"
          end
          if result[:status] != 0
            error "The script '%s' failed to process the item.", item, script_name
          end
          result[:err].each { |m| error m, item }
          result[:out].each { |m| info m, item }
        end
      end
    end
  end
end
