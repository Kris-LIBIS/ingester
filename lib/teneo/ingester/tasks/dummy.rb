# frozen_string_literal: true
require 'dynflow/action'

module Teneo
  module Ingester
    module Tasks

      class Dummy < Dynflow::Action

        def plan(arg)
          puts "#{id} - schema: #{arg}"
          case arg
          when Integer
            plan_self(timeout: arg)
          when Array
            x = arg.first
            x = :s unless [:c, :s].include?(x)
            case x
            when :s
              sequence do
                arg.each do |a|
                  sub_plan a
                end
              end
            when :c
              concurrence do
                arg.each do |a|
                  sub_plan a
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
          puts "#{id} - busy for #{count} seconds"
          sleep count
          puts "#{id} - ready after #{count} seconds"
        end

        def finalize
          puts "#{id} - is done"
        end

        protected

        def sub_plan(a)
          return unless a.is_a?(Integer) || a.is_a?(Array)
          plan_action Teneo::Ingester::Tasks::Dummy, a
        end

      end

    end
  end
end