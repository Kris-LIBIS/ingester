$:.unshift File.join(__dir__, '..', 'lib')
require 'teneo-ingester'

::Teneo::Ingester::Initializer.init
