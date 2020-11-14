# frozen_string_literal: true

require 'mail'
require 'zip'

module Teneo
  module Ingester
    module Tasks
      module Base

        module Mailer

          # noinspection RubyScope
          def send_email(*attachments, &block)
            mail = Mail.new do
              from 'teneo.libis@gmail.com'
            end
            block.call(mail)
            attachments.each do |file|
              mail.add_file file
            end
            mail.deliver!
            message = "Message '#{mail.subject}'"
            mail_to = "to #{mail.to}#{mail.cc ? " and #{mail.cc}" : ''}"
            debug "#{message} sent #{mail_to}", run.job
            true

          rescue Exception => e

            if e.message =~ /message file too big/ && !attachments.empty?

              if attachments.all?(/\.zip$/)

                warn "Email '#{message}' is too big. Sending without attachments.", run.job

                mail.body = mail.body.to_s + "\n\nWarning: The attachments were too big. Attachments can be found at:"
                attachments.each do |file|
                  mail.body = mail.body.to_s + "\n - #{file}"
                end

                attachments = []

              else

                warn "Email '#{message}' is too big. Retrying with zip compression.", run.job

                Zip.default_compression = Zlib::BEST_COMPRESSION

                attachments.map! do |file|
                  zip_file = File.join('/tmp', "#{File.basename(file)}.zip")
                  Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
                    zip.add(File.basename(file), file)
                  end
                  zip_file
                end

              end

              send_email attachments, &block

            else

              error "#{message}' could not be sent #{mail_to}: #{e.message}", run.job # if self.respond_to?(:error)

              attachments.each do |file|
                warn "Attachment can be found here: #{file}", run.job
              end

              false

            end

            #def error(msg, *_args)
            #  $stderr.puts "ERROR: #{msg}"
            #end unless method_defined? :error
            #
            #def warn(msg, *_args)
            #  $stderr.puts "WARNING: #{msg}"
            #end unless method_defined? :warn
            #
            #def info(msg, *_args)
            #  $stderr.puts "INFO: #{msg}"
            #end unless method_defined? :info
            #
            #def debug(msg, *_args)
            #  $stderr.puts "DEBUG: #{msg}"
            #end unless method_defined? :debug

          end

        end

      end
    end
  end
end
