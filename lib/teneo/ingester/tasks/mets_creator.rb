# encoding: utf-8

require "fileutils"
require "i18n"

require "teneo/ingester"
require "libis/metadata/dublin_core_record"
require "libis/tools/mets_file"
require "libis/tools/checksum"

module Teneo
  module Ingester
    module Tasks
      class MetsCreator < Teneo::Ingester::Tasks::Base::Task
        taskgroup :ingest
        recursive true
        item_types Teneo::DataModel::IntellectualEntity

        description "Creates a METS file for each IntellectualEntity item."

        help_text <<~STR
                    For each IntellectualEntity item in the ingest a METS file will be created in the ingest directory along
                    with the file streams in a format that is ready to be submitted to Rosetta. This is a single step operation,
                    so, all the information that is needed is expected to be present in the ingest objects to create the METS
                    file. Particularly, the representations and their files should be available, the descriptive metadata and
                    any access rights and retention policies that need to be set and all collections should be created.

                    Some settings will be fetched from the selected IngestModel:
                    
                    identifier
                    : will be injected as dc:identifier in the descriptive metadata

                    entity_type
                    : The IE's entity type in the repository

                    status
                    : the IE status in the repository, default is 'ACTIVE'

                    user_a, user_b, user_c
                    : extra metadata fields on the IE level

                    Each of these field values can be overruled by a property setting on the IE itself.

                    By default, the source and derived files will not be copied into the streams, but soft-linked instead. If
                    the Rosetta application may not be able to access the files through the soft-links, files cn be copied
                    instead. For this, set the 'copy_files' parameter value to true.
                  STR

        parameter collection: nil,
                  description: "Collection to add the IE tree to.",
                  help: <<~STR
                    This collection is expected to include missing collection path from the top to the root of this
                    ingest. The collections built from the source files will be added to form the full absolute path
                    of the collections that the IE will be added to.

                    For example: if this collection parameter is 'A/B' and in the ingest the IE has parent collection
                    path 'C/D', the IE is expected to belong to the collection 'A/B/C/D'.
                  STR

        parameter copy_files: false,
                  description: "Copy file info ingest dir instead of creating a symbolic link"

        protected

        def process(item, *_args)
          unless @ingest_dir
            @ingest_dir = run.ingest_dir

            debug "Preparing ingest in #{@ingest_dir}.", item
            FileUtils.rmtree @ingest_dir
            FileUtils.mkpath @ingest_dir
            #noinspection RubyArgCount
            FileUtils.chmod "a+rwX", @ingest_dir
          end
          create_ie(item)
          stop_recursion
        end

        def create_ie(item)
          item.properties[:ingest_dir] = File.join(@ingest_dir, item.name)
          item.save!

          mets = Libis::Tools::MetsFile.new

          dc_record = Libis::Metadata::DublinCoreRecord.new(item.metadata_record&.data)

          collection_list = item.parents.filter { |i| i.is_a? Teneo::DataModel::Collection }.map(&:label)
          collection_list.unshift(parameter(:collection)) if parameter(:collection)

          # noinspection RubyResolve
          dc_record.isPartOf = collection_list.join("/") unless collection_list.empty?

          ingest_model = item.ingest_model

          identifier = item.properties[:identifier] || ingest_model.identifier
          # noinspection RubyResolve
          dc_record.identifier! identifier if identifier

          mets.dc_record = dc_record.root.to_xml

          amd = {
            status: item.properties[:status] || ingest_model.status || "ACTIVE",
            entity_type: item.properties[:entity_type] || ingest_model.entity_type,
            user_a: item.properties[:user_a] || ingest_model.user_a,
            user_b: item.properties[:user_b] || ingest_model.user_b,
            user_c: item.properties[:user_c] || ingest_model.user_c,
          }

          access_right = item.access_right
          amd[:access_right] = access_right.ext_id if access_right

          retention_policy = item.retention_policy
          amd[:retention_period] = retention_policy.ext_id if retention_policy

          amd[:collection_id] = item.parent.properties[:collection_id] if item.parent.is_a?(Teneo::DataModel::Collection)

          mets.amd_info = amd

          ie_ingest_dir = item.properties[:ingest_dir]

          item.representations.each { |rep| add_rep(mets, rep, ie_ingest_dir) }

          mets_filename = File.join(ie_ingest_dir, "content", "#{item.id}.xml")
          FileUtils.mkpath(File.dirname(mets_filename))
          mets.xml_doc.save mets_filename

          # ExL Rosetta case #

          sip_dc = Libis::Metadata::DublinCoreRecord.new do |xml|
            xml[:dc].title "#{run.name} - #{item.namepath}"
            xml[:dc].identifier run.name
            xml[:dc].source item.namepath
            xml[:dcterms].alternate item.label
            # xml[:dc].creator current_user.name
          end

          sip_dc.save(File.join(ie_ingest_dir, "content", "dc.xml"))

          FileUtils.chmod_R "a+rwX", ie_ingest_dir

          debug "Created METS file '#{mets_filename}'.", item
        end

        def add_rep(mets, rep_item, ie_ingest_dir)
          rep = mets.representation(rep_item.to_hash)
          rep.label = rep_item.label
          div = mets.div label: rep_item.parent.label
          mets.map(rep, div)

          add_children(mets, rep, div, rep_item, ie_ingest_dir)
        end

        def add_children(mets, rep, div, item, ie_ingest_dir)
          item.dirs.each { |d| div << add_children(mets, rep, mets.div(label: d.name), d, ie_ingest_dir) }
          item.files.each { |f| div << add_file(mets, rep, f, ie_ingest_dir) }
          div
        end

        def add_file(mets, rep, file_item, ie_ingest_dir)
          config = file_item.to_hash
          properties = config.delete(:properties)
          config[:creation_date] = properties[:creation_time]
          config[:modification_date] = properties[:modification_time]
          config[:entity_type] = properties[:entity_type]
          config[:location] = properties[:filename]
          # Workaround: review when Rosetta case #00552865 is fixed (then remove next line and remove transliteration and gsub again
          # config[:original] = File.basename(properties[:original_path] || file_item.filepath)
          config[:target_location] = properties[:original_path] || file_item.filepath
          # End workaround
          config[:mimetype] = properties[:mimetype]
          config[:size] = properties[:size]
          config[:puid] = properties[:puid]
          config[:checksum_MD5] = properties[:checksum_md5]
          config[:checksum_SHA1] = properties[:checksum_sha1]
          config[:checksum_SHA256] = properties[:checksum_sha256]
          config[:checksum_SHA384] = properties[:checksum_sha384]
          config[:checksum_SHA512] = properties[:checksum_sha512]
          config[:group_id] = properties[:group_id]
          config[:label] = file_item.label

          file = mets.file(config)

          file.representation = rep

          # copy file to stream
          stream_dir = File.join(ie_ingest_dir, "content", "streams")
          target_path = File.join(stream_dir, file.target)
          FileUtils.mkpath File.dirname(target_path)
          if File.exists?(target_path)
            unless Libis::Tools::Checksum.hexdigest(target_path, :MD5) == file_item.properties["checksum_md5"]
              raise Teneo::WorkflowError, "Target file (%s) already exists with different content." % [target_path]
            end
            debug "File #{parameter(:copy_files) ? "copy" : "linking"} of #{file_item.fullpath} skipped."
          else
            if parameter(:copy_files)
              FileUtils.copy_entry(file_item.fullpath, target_path)
              debug "Copied file to #{target_path}.", file_item
            else
              FileUtils.symlink(file_item.fullpath, target_path)
              debug "Linked file to #{target_path}.", file_item
            end
          end

          # noinspection RubyResolve
          if file_item.metadata_record && file_item.metadata_record.format == "DC"
            dc = Libis::Metadata::DublinCoreRecord.parse file_item.metadata_record.data
            file.dc_record = dc.root.to_xml
          end

          file
        end
      end
    end
  end
end
