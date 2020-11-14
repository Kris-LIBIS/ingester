# frozen_string_literal: true

$:.unshift File.join(__dir__, 'lib')

require 'bundler/setup'
require 'teneo/ingester'

::Teneo::Ingester::Initializer.init