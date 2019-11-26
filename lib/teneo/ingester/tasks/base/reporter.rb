# frozen_string_literal: true

require 'fileutils'

require_relative 'mailer'
require_relative 'task'
require_relative 'message_log_to_csv'
require_relative 'csv_to_html'
require_relative 'status_to_csv'

module Teneo
  module Ingester
    module Tasks
      module Base

        class Reporter < Teneo::Ingester::Tasks::Base::Task

          include Base::Mailer
          include Base::MessageLog2Csv
          include Base::Csv2Html
          include Base::Status2Csv

          taskgroup :report

          description 'Generates a status report and sends it via email.'

          help_text <<~STR
          STR

          parameter mail_to: '',
                    description: 'E-mail address (or comma-separated list of addresses) to send report to.'

          recursive true
          item_types Teneo::DataModel::Package
          run_always true

          def process(item, *_args)
            send_report(item)
            stop_recursion
          end

          protected

          def send_report(item)
            dir = File.dirname(run.log_filename)
            name = File.basename(run.log_filename, '.*')
            csv_file = File.join(dir, "#{name}.csv")
            html_file = File.join(dir, "#{name}.html")
            run.runner.item_status(item) == :done ?
                send_success_log(item, csv_file, html_file) :
                send_error_log(item, csv_file, html_file)
          end

          def send_error_log(item, csv_file, html_file)
            return unless run.submitter
            log2csv(run, csv_file, skip_date: true, trace: true)
            csv2html(csv_file, html_file)
            log2csv(run, csv_file, skip_date: false, trace: true)
            status_log = csv2html_io(status2csv_io(item))
            send_email(csv_file, html_file) do |mail|
              mail.to = run.submitter
              mail.subject = "Ingest failed: #{run.name}"
              mail.body = "Unfortunately the ingest '#{run.name}' failed. Please find the ingest log in attachment."
              mail.html_part = [
                  "Unfortunately the ingest '#{run.name}' failed. Please find the ingest log in attachment.",
                  "Status overview:",
                  status_log.string
              ].join("\n")
            end
            FileUtils.remove csv_file, force: true
            FileUtils.remove html_file, force: true
          end

          def send_success_log(item, csv_file, html_file)
            return unless run.submitter
            log2csv(run, csv_file, skip_date: true, filter: 'IWEF')
            csv2html(csv_file, html_file)
            log2csv(run, csv_file, skip_date: false, trace: true)
            status_log = csv2html_io(status2csv_io(item))
            send_email(csv_file, html_file) do |mail|
              mail.to = run.submitter
              mail.subject = "Ingest complete: #{run.name}"
              mail.body = "The ingest '#{run.name}' finished successfully. Please find the ingest log in attachment."
              mail.html_part = [
                  "The ingest '#{run.name}' finished successfully. Please find the ingest log in attachment.",
                  "Status overview:",
                  status_log.string
              ].join("\n")
            end
            FileUtils.remove csv_file, force: true
            FileUtils.remove html_file, force: true
          end

        end
      end
    end
  end
end
