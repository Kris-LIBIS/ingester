# frozen_string_literal: true

module Teneo
  module Workflow

    # the guard is against a redefinition warning that happens on Travis
    VERSION = "3.0.beta.2" unless const_defined? :VERSION
  end
end
