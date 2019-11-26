# frozen_string_literal: true

require 'libis/exceptions'

module Teneo
  module Ingester

    module Error
      def initialize(*args, code: nil)
        message = code ? Libis::Workflow::MessageRegistry.get_message(code) : args.shift
        message ||= ''
        begin
          message = message % args if args.size > 0
        rescue ArgumentError
          message = "#{message} (#{args})"
        end
        super(message)
      end
      #def backtrace
      #  [super.select {|x| x =~ /^#{Teneo::Ingester::ROOT_DIR}/}]
      #end
    end

    class WorkflowError < Libis::WorkflowError
      include Error
    end

    class WorkflowAbort < Libis::WorkflowAbort
      include Error
    end

    class NotFoundError < StandardError
      include Error
    end

  end
end
