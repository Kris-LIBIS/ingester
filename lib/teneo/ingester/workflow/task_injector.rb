# frozen_string_literal: true

require 'libis/workflow/task'

module Libis::Workflow

  class Task

    def pre_process(item)
      item.reload
    end

    def post_process(item)
      item.save!
      item.reload
    end

  end
end
