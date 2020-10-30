# frozen_string_literal: true
require 'active_record'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/with_options'
require 'global_id'
require 'symbolized'

module Teneo
  module DataModel
    class Base < ActiveRecord::Base
      include GlobalID::Identification

      self.abstract_class = true

      def self.name_method
        :name
      end

      # Creates a virtual attribute <name>_list that converts between internal array storage and a ',' joined string
      def self.array_field(name)
        # reader as <name>_list
        self.define_method "#{name}_list" do
          self.send(name).blank? ? '' : self.send(name).join(',')
        end
        # writer as <name>_list=
        self.define_method "#{name}_list=" do |values|
          self.send("#{name}=", [])
          self.send("#{name}=", values.split(',')) unless values.blank?
        end
      end

      def self.update_or_create(args, attributes)
        obj = self.find_or_create_by(args)
        obj.update(attributes)
        obj.save!
        obj
      end

      def self.from_hash(hash, id_tags = [:name], &block)
        self.create_from_hash(hash, id_tags, &block)
      end

      def self.create_from_hash(hash, id_tags, &block)
        id_tags = id_tags.map(&:to_sym)
        unless id_tags.empty? || id_tags.any? { |k| hash.include?(k) }
          raise ArgumentError, "Could not create '#{self.name}' object from Hash since none of the id tags '#{id_tags.join(',')}' are present"
        end
        tags = id_tags.inject({}) do |h, k|
          v = hash.delete(k)
          h[k] = v if v
          h
        end
        item = tags.empty? ? self.new : self.find_or_initialize_by(tags)
        item.attributes.clear
        block.call(item, hash) if block unless hash.empty?
        item.assign_attributes(tags.merge(hash))
        item.save!
        item
      end

      def to_hash
        result = self.attributes.reject { |k, v| v.blank? || volatile_attributes.include?(k) }
        result = result.to_yaml
        YAML.safe_load(result, symbolize_names: true, permitted_classes: [Time, Symbolized::SymbolizedHash, Symbol])
      end

      def to_s
        (self.name rescue nil) || "#{self.class.name}_#{self.id}"
      end

      def safe_name
        positions = self.name.gsub(/[^\w.-]/).map { Regexp.last_match.begin(0) + 1 }
        errors.add(:name, "'#{self.name}' contains illegal character(s) at #{positions}") unless positions.empty?
      end

      protected

      def volatile_attributes
        %w'id created_at updated_at lock_version'
      end

      def copy_attributes(other)
        self.set(
            other.attributes.reject do |k, _|
              volatile_attributes.include? k.to_s
            end.each_with_object({}) do |(k, v), h|
              h[k] = v.duplicable? ? v.dup : v
            end
        )
        self
      end

      def self.record_finder(model, query)
        return model.where(query).take!
      rescue ActiveRecord::RecordNotFound => e
        e.message.gsub!(/with .*$/, "with #{query}")
        raise e
      end

    end

  end
end