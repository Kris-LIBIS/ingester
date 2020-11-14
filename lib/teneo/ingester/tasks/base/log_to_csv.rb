# frozen_string_literal: true

require 'csv'

module Teneo
  module Ingester
    module Tasks
      module Base

        module Log2Csv

          CSV_HEADER = %w'Code Date Time Pid Status Task Item Message'

          def log2csv(run, csv_file = nil, options = {})
            log_file = run.log_filename
            log_in = IO === log_file ? log_file : File.open(log_file, 'r')
            csv_out = csv_file ? File.open(csv_file, 'w') : StringIO.new
            log2csv_io(log_in, csv_out, options)
            log_in.close
            return csv_out if StringIO === csv_out
            csv_out.close
          end

          # @param [IO] log_in
          # @param [IO] csv_out
          # @param [Hash] options
          def log2csv_io(log_in, csv_out = nil, options = {})
            csv_out ||= StringIO.new
            line_regex = /^(.), \[([\d-]+)T([\d:.]+) #([\d.]+)\]\s+(\S+)\s+-- (.*?) - (.*?) : (.*)/
            buffer = CSV_HEADER
            log_in.each_line do |line|
              if line =~ line_regex
                write_buffer_to_csv(buffer, csv_out, options)
                buffer = [$1, $2, $3, $4, $5, $6, $7, $8]
              elsif options[:trace]
                buffer[7] += "\n#{line}"
              end
            end
          ensure
            write_buffer_to_csv(buffer, csv_out, options)
            csv_out.rewind
            csv_out
          end

          protected

          def write_buffer_to_csv(buffer, csv_out, options)
            return if buffer.empty? || buffer.all? { |x| x.strip.empty? }
            return if buffer != CSV_HEADER && options[:filter] && !options[:filter].upcase.include?(buffer[0])
            csv_out.puts(
                CSV.generate_line(
                    (options[:skip_date] ?
                         [buffer[4], buffer[5], buffer[6], buffer[7]] :
                         [buffer[4], buffer[1], buffer[2], buffer[5], buffer[6], buffer[7]]
                    ),
                    col_sep: ';', quote_char: '"'
                )
            )
          end

        end

      end
    end
  end
end
