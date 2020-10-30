# frozen_string_literal: true
require 'teneo-data_model'
require 'securerandom'
require_relative 'base'

module Teneo
  module DataModel
    # noinspection RailsParamDefResolve
    class User < Base
      self.table_name = 'users'

      has_many :memberships,
               # class_name: Teneo::DataModel::Membership,
               dependent: :destroy,
               inverse_of: :user

      has_many :organizations,
               through: :memberships

      accepts_nested_attributes_for :memberships, allow_destroy: true

      after_initialize :init

      def init
        self.uuid ||= SecureRandom.uuid
      end


      def name
        "#{first_name} #{last_name}"
      end

      # @param [Hash] hash
      def self.from_hash(hash)
        roles = hash.delete(:roles)
        super(hash, [:email]).tap do |item|
          old = item.memberships.map(&:id)
          roles.each do |role|
            role[:user_id] = item.id
            item.memberships << Teneo::DataModel::Membership.from_hash(role)
          end
          (old - item.memberships.map(&:id)).each { |id| item.memberships.find(id)&.destroy! }
          item.save!
        end
      end

      # sanitize email and username
      before_validation do
        self.email = self.email.to_s.downcase
      end

      validates_presence_of :email
      validates_uniqueness_of :email, case_sensitive: false
      validates_format_of :email, with: URI::MailTo::EMAIL_REGEXP

      # @param [Organization] organization
      # @return [Array<String>]
      def roles_for(organization)
        self.memberships.where(organization: organization).map(&:role) rescue []
      end

      # @param [String] role
      # @return [Array<Organization>]
      def organizations_for(role)
        self.memberships.where(role: role).map(&:organization) rescue []
      end

      # @param [String] role
      # @param [Organization, IngestAgreement, IngestWorkflow, Package, Run] organization
      # @return [boolean]
      def is_authorized?(role, organization)
        organization = organization.package if organization.is_a?(Run)
        organization = organization.ingest_workflow if organization.is_a?(Package)
        organization = organization.ingest_agreement if organization.is_a?(IngestWorkflow)
        organization = organization.organization if organization.is_a?(IngestAgreement)
        return false unless organization.is_a?(Organization)
        self.roles_for(organization).include?(role)
      end

      # @param [String] role
      # @param [Organization] organization
      # @return [Membership]
      def add_role(role, organization)
        Membership.create(user: self, organization: organization, role: role)
      end

      # @param [String] role
      # @param [Organization] organization
      def del_role(role, organization)
        m = self.memberships.find_by(organization: organization, role: role)
        m&.destroy!
      end

      # @return [Hash<Organization, Array<String>>]
      def member_organizations
        # noinspection RubyResolve
        self.memberships.reduce({}) do |h, m|
          h[m.organization] ||= []
          h[m.organization].push(m.role)
          h
        end
      end

    end
  end
end