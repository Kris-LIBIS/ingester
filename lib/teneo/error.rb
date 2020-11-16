# frozen_string_literal: true

module Teneo
  module Error
    def initialize(*args, code: nil)
      message = code ? Teneo::Workflow::MessageRegistry.get_message(code) : args.shift
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

  class WorkflowError < ::RuntimeError
    include Error
  end

  class WorkflowAbort < ::RuntimeError
    include Error
  end

  class NotFoundError < ::RuntimeError
    include Error
  end
end
