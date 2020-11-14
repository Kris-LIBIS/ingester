# frozen_string_literal: true

require_relative 'base'

module Teneo
  module DataModel
    # noinspection RailsParamDefResolve
    class Membership < Base
      self.table_name = 'memberships'

      ROLE_LIST = %w'uploader ingester admin'

      belongs_to :user, inverse_of: :memberships
      belongs_to :organization, inverse_of: :memberships

      validates :role, inclusion: { in: ROLE_LIST }
      validate :unique_role

      def unique_role
        query = Membership.where(user: user, organization: organization, role: role)
        query = query.where.not(id: id) if id # exclude self if persisted
        errors.add(:role, 'should be unique for a given user and organization') unless query.size == 0
      end

      def self.from_hash(hash, id_tags = [:organization_id, :user_id, :role])
        organization_name = hash.delete(:organization)
        query = organization_name ? { name: organization_name } : { id: hash[:organization_id] }
        organization = record_finder Teneo::DataModel::Organization, query
        hash[:organization_id] = organization.id

        user_email = hash.delete(:user)
        query = user_email ? { email: user_email } : { id: hash[:user_id] }
        user = record_finder Teneo::DataModel::User, query
        hash[:user_id] = user.id

        role_code = hash[:role]
        puts "Invalid role '#{role_code}'" unless ROLE_LIST.include? role_code

        super(hash, id_tags)
      end


    end
  end
end