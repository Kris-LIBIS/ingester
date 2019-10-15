# frozen_string_literal: true

require 'libis/exceptions'

class CollectFiles < Teneo::Ingester::Task

  parameter location: '.',
            description: 'Dir location to start scanning for files.'
  parameter subdirs: false,
            description: 'Look for files in subdirs too.'
  parameter selection: nil,
            description: 'Only select files that match the given regular expression. Ignored if empty.'

  def process(item)
    if item.is_a? Teneo::DataModel::Package
      collect_files(item, parameter(:location))
    elsif item.is_a? Teneo::Ingester::DirItem
      collect_files(item, item.fullpath)
    end
  end

  def collect_files(item, dir)
    glob_string = dir
    glob_string = File.join(glob_string, '**') if parameter(:subdirs)
    glob_string = File.join(glob_string, '*')

    selection = Dir.glob(glob_string).select do |x|
      parameter(:selection) && !parameter(:selection).empty? ? x =~ Regexp.new(parameter(:selection)) : true
    end

    selection.sort.each do |file|
      next if %w[. ..].include? file

      add_item(item, file)
    end
  end

  def add_item(item, file)
    child = if File.file?(file)
              Teneo::Ingester::FileItem.new
            elsif File.directory?(file)
              Teneo::DataModel::DirItem.new
            else
              Teneo::DataModel::WorkItem.new
            end
    child.filename = file
    child.add_checksum('SHA256')
    item << child
  end

end
