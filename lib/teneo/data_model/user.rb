# frozen_string_literal: true
require "securerandom"
require "bcrypt"

# For performance reasons
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

require_relative "base"

module Teneo
  module DataModel
    # noinspection RailsParamDefResolve
    class User < Base
      self.table_name = "users"

      has_many :memberships,
               dependent: :destroy,
               inverse_of: :user

      has_many :organizations,
               through: :memberships

      accepts_nested_attributes_for :memberships, allow_destroy: true

      before_save :init

      def init
        self.uuid ||= SecureRandom.uuid
      end

      def name
        "#{first_name} #{last_name}"
      end

      def admin?
        self.admin == true
      end

      # sanitize email and username
      before_validation do
        self.email = self.email.to_s.downcase
      end

      validates_presence_of :email
      validates_uniqueness_of :email
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

      def self.authenticate(email, password)
        self.find_by(email_id: email)&.authenticate(password)
      end

      def password=(password)
        self.password_hash = BCrypt::Password.create(password)
      end

      def password
        BCrypt::Password.new(password_hash || "")
      end

      def authenticate(password)
        self.password == password && self
      end

      def self.find_for_jwt_authentication(sub)
        self.find_by(email: sub)
      end

      def jwt_subject
        self.email
      end

      def on_jwt_dispatch(_token, payload)
        payload[:jit] = self.jit = SecureRandom.base64(18)
        save!
      end

      def self.jwt_revoked?(payload, account)
        account.jit != payload[:jit]
      end

      def self.revoke_jwt(payload, account)
        account.jit = nil if account.jit == payload[:jit]
        account.save!
      end

      # @param [Hash] hash
      def self.from_hash(hash)
        roles = hash.delete(:roles)
        super(hash, [:email]).tap do |item|
          old = item.memberships.map(&:id)
          roles&.each do |role|
            role[:user_id] = item.id
            item.memberships << Teneo::DataModel::Membership.from_hash(role)
          end
          (old - item.memberships.map(&:id)).each { |id| item.memberships.find(id)&.destroy! }
          item.save!
        end
      end
    end
  end
end
