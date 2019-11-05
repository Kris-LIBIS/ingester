# frozen_string_literal: true

require 'libis/exceptions'
require 'teneo/ingester/tasks/base/task'

class CollectFiles < Teneo::Ingester::Tasks::Base::Task

  parameter location: '.',
            description: 'Dir location to start scanning for files.'
  parameter subdirs: false,
            description: 'Look for files in subdirs too.'
  parameter selection: nil,
            description: 'Only select files that match the given regular expression. Ignored if empty.'

  recursive false
  item_types Teneo::DataModel::Package

  def process(item, *_args)
    collect_files(item, parameter(:location))
    item
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

      child = add_item(item, file)
      collect_files(child, child.fullpath) if child.is_a?(Teneo::Ingester::DirItem)
    end
  end

  def add_item(item, file)
    child = if File.file?(file)
              Teneo::Ingester::FileItem.new
            elsif File.directory?(file)
              Teneo::Ingester::DirItem.new
            else
              Teneo::Ingester::WorkItem.new
            end
    child.filename = file
    child.add_checksum(:SHA256)
    item << child
    child.save!
    child
  end

end
