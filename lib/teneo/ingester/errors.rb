# frozen_string_literal: true
module Teneo
  module Ingester

    class Error < StandardError;
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
    end

    class WorkflowError < Error; end
    class WorkflowAbort < Error; end

    class NotFoundError < Error; end

  end
end
