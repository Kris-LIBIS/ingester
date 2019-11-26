require 'csv'
require 'teneo/ingester'
require 'time_difference'

module Teneo
  module Ingester
    module Tasks
      module Base

        module Status2Csv

          # @param [Libis::Ingester::WorkItem] item
          # @param [String] csv_file
          def status2csv(item, csv_file = nil)
            csv_out = csv_file ? File.open(csv_file, 'w') : StringIO.new
            status2csv_io(item, csv_out)
            return csv_out if StringIO === csv_out
            csv_out.close
          end

          # @param [Libis::Ingester::WorkItem] item
          # @param [IO] csv_out
          def status2csv_io(item, csv_out = nil)
            csv_out ||= StringIO.new

            csv_out.puts CSV.generate_line(%w'Task Progress Status Started Ended Elapsed',
                                           col_sep: ';', quote_char: '"'
            )

            item.status_log.map do |status|
              task = status[:task]
              tasktree = task.gsub(/\/[^\/]+(?=\/)/, '|---').gsub(/\//, '')
              data = {
                  task: tasktree,
                  status: status[:status].to_s.capitalize,
                  start: status[:created_at].localtime,
                  end: status[:updated_at].localtime,
              }
              if data[:status] == 'Done' && status[:progress] == 0
                data[:progress] = '1 of 1' if status[:max] == 0
              else
                data[:progress] = status[:progress].to_s
                data[:progress] += ' of ' + status[:max].to_s if status[:max]
              end
              time_spent = TimeDifference.between(data[:start], data[:end]).in_seconds
              data[:time_spent] = time_spent
              data
            end.map do |data|
              [
                  data[:task],
                  data[:progress].to_s,
                  data[:status],
                  data[:start].strftime('%d/%m/%Y %T'),
                  data[:end].strftime('%d/%m/%Y %T'),
                  '%{prefix}%{time}' % {
                      prefix: data[:task][/^(\|---)*/],
                      time: time_diff_in_hours(Time.at(0), Time.at(data[:time_spent]))
                  }
              ]
            end.each do |data|
              csv_out.puts CSV.generate_line(data, col_sep: ';', quote_char: '"')
            end

            csv_out.rewind
            csv_out
          end

          protected

          def time_diff_in_hours(start_time, end_time)
            diff = (end_time.to_time.to_f - start_time.to_time.to_f).abs
            data = { hours: (diff / 1.hours).floor }
            diff -= data[:hours].hours
            data[:minutes] = (diff / 1.minutes).floor
            diff -= data[:minutes].minutes
            diff = diff.seconds
            data[:seconds] = diff.floor
            data[:milliseconds] = (diff.remainder(1) * 1000).round
            '%02<hours>d:%02<minutes>d:%02<seconds>d.%03<milliseconds>d' % data
          end

        end
      end
    end
  end
end
