# frozen_string_literal: true
require 'active_support/concern'

module Teneo
  module DataModel
    module WithParameters

      extend ActiveSupport::Concern

      included do
        # noinspection RailsParamDefResolve
        self.has_many :parameters, as: :with_parameters, class_name: 'Teneo::DataModel::Parameter'
      end

      def param_value(name)
        parameters_list[name.to_s]
      end

      # Add a parameter
      # @param [String] name
      # @param [Array<Strings>] targets child parameters to link to as <child_name>#<param_name>
      # @param [Hash] opts hash with any parameter attributes that need to be set
      def add_parameter(name:, targets: [], **opts)
        param = Parameter.find_or_initialize_by(name: name, with_parameters: self)
        param.update(
            opts.slice(
                *(param.attribute_names.map(&:to_sym) -
                    %i'id created_at updated_at lock_version with_parameters_id with_parameters_type'
                )
            )
        )
        param.save!
        child_parameters(export_only: true).each do |p|
          next unless targets.include?(p.reference_name)
          targets.delete(p.reference_name)
          ParameterReference.create(source: param, target: p)
        end
        raise RuntimeError, "Parameter #{name} added, but could not find targets #{targets}." unless targets.empty?
      end

      # Get a list of child objects that parameters can refer to
      # @return [Array<Teneo::DataModel::Base>]
      def parameter_children
        []
      end

      # Get a Hash with the parameter data of all parameters
      # The effect of the recursive parameter:
      #  - false (default) : only the information for the parameters of the current item is exported
      #  - not false : missing parameters information (e.g. data type) will be collected from referenced parameters
      #                and unmapped child parameters' info will be added as the referenced name entry
      #  - :collapse : deeply nested references will be added to the :references array with their reference name
      #  - :tree : child parameter references will be added to the :targets array as a recursive hash
      # @param [FalseClass, Symbol] recursive option that will be passed to Parameter#to_hash
      def parameters_hash(recursive = false)
        result = parameters.each_with_object({}) do |param, result|
          result[param.name] = param.to_hash(recursive)
        end
        child_parameters(mapped: false, recursive: true).each do |param|
          result[param.reference_name] = param.to_hash(recursive)
        end if recursive
        result
      end

      def parameters_hash_for(reference, recursive: :collapse)
        regex = Parameter.reference_search(reference)
        parameters_hash(recursive).values.each_with_object({}) do |v, result|
          if v[:references]&.any? { |x| x =~ regex }
            result[$1] = v
          end
        end
      rescue RuntimeError
        {}
      end

      def parameters_list
        parameters_hash(:collapse).values.each_with_object({}) do |h, result|
          h[:references].each { |ref| result[ref] = h[:default] }
        end
      end

      def child_parameters(export_only: false, unmapped: true, mapped: true, recursive: false)
        result = parameter_children.map(&:parameters).map(&:all).flatten.reject do |p|
          (export_only && !p.export) ||
              (!unmapped && !mapped) ||
              (!unmapped && p.unmapped(self)) ||
              (!mapped && p.mapped(self))
        end
        result += parameter_children.map do |child|
          child.child_parameters(export_only: export_only, unmapped: unmapped, mapped: mapped, recursive: recursive)
        end.flatten if recursive
        result
      end

      def child_parameters_hash(reference = nil, recursive: :collapse)
        regex = reference ?
                    Parameter.reference_search(reference) :
                    Regexp.new("^((#{parameter_children.map { |c| Regexp.escape(c.name) }.join('|')})#\\K(.*))$")
        parameter_children.each_with_object({}) do |child, result|
          child.parameters_hash(recursive).each do |name, param|
            next unless param[:reference_name] =~ regex
            result[name] = param
          end
        end
      end

      def child_parameter_hash(reference = nil)
        child_parameters_hash(reference).first
      end

      def parameter_values(include_export = false, include_private = true)
        parameters.each_with_object({}) do |param, result|
          next unless param.export ? include_export : include_private
          result[param.name] = param.default
        end
      end

      def params_from_hash(params)
        return unless params
        old_params = parameters.map(&:id)
        params.each do |name, definition|
          definition[:name] = name
          definition[:with_parameters_type] = self.class.name
          definition[:with_parameters_id] = self.id
          definition[:export] = true unless definition.has_key?(:export)
          targets = definition.delete(:targets) || []
          parameter = Teneo::DataModel::Parameter.from_hash(definition)
          parameters << parameter
          parameter.target_list = targets
        end
        obsolete_params = old_params - parameters.map(&:id)
        obsolete_params.each do |id|
          parameters.find(id)&.destroy!
        end
        save!
        self
      end

      def all_parameters
        result = parameters.to_a
        parameter_children.each do |pchild|
          params = pchild.all_parameters
          params.delete_if { |p| p.referenced.any? { |r| r.with_parameters == self } }
          result += params
        end
        Hash[result.map { |p| [p.name, p.value] }]
      end

      class_methods do

        def params_from_values(target_host, values = {})
          return {} unless values
          values.each_with_object(Hash.new { |h, k| h[k] = {} }) do |(name, value), result|
            reference = "#{target_host}##{name}"
            result[name] = { name: name, targets: [reference], default: value, export: false }
          end
        end

      end

    end

  end
end