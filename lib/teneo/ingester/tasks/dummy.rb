# frozen_string_literal: true
require 'dynflow/action'

module Teneo
  module Ingester
    module Tasks

      class Dummy < Dynflow::Action

        def plan(arg)
          puts "schema: #{arg}"
          case arg
          when Integer
            plan_self(timeout: arg)
          when Array
            x = arg.shift
            unless [:c, :s].include?(x)
              arg.unshift x
              x = :s
            end
            case x
            when :s
              sequence do
                arg.each do |a|
                  plan_action Teneo::Ingester::Tasks::Dummy, a
                end
              end
            when :c
              concurrence do
                arg.each do |a|
                  plan_action Teneo::Ingester::Tasks::Dummy, a
                end
              end
            else
              # nothing
            end
          else
            nil
          end
        end

        def run
          count = input.fetch(:timeout)
          puts "#{object_id} - busy for #{count} seconds"
          sleep count
          puts "#{object_id} - ready after #{count} seconds"
        end

        def finalize
          puts "#{object_id} - is done"
        end

      end

    end
  end
end