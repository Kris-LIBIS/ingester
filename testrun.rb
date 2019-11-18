require 'teneo-ingester'

Teneo::Ingester::Initializer.init

Teneo::Ingester.configure do |cfg|
  cfg.logger.appenders =
  #     ::Logging::Appenders.string_io('StringIO', layout: ::Teneo::Ingester::Config.get_log_formatter, level: log_level)
  # cfg.logger.add_appenders(
      ::Logging::Appenders.stdout('StdOut', layout: ::Teneo::Ingester::Config.get_log_formatter, level: :DEBUG)
  # )
end

package = Teneo::DataModel::Package.find_by(name: 'KL_878')

#package.runs.each { |run| run.destroy }
#package.items.each { |item| item.destroy }

run = package.execute

# puts run.status_log.map(&:to_hash)
