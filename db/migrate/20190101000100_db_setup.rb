# frozen_string_literal: true

class DbSetup < ActiveRecord::Migration[5.2]

  # noinspection RubyResolve
  def change

    # Users and Organizations
    # #######################

    create_table :users do |t|
      t.string :uuid, null: false, index: {unique: true}
      t.column :email, :citext, null: false, default: '', index: {unique: true}

      t.string :first_name
      t.string :last_name

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :organizations do |t|
      t.string :name, null: false, index: {unique: true}
      t.string :inst_code, null: false
      t.string :description

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :storage_types do |t|
      t.string :protocol, null: false, index: {unique: true}
      t.string :description
      t.string :driver_class
      # with_parameters

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :storages do |t|
      t.string :name, null: false
      t.string :purpose, default: 'upload'
      # with_parameter_refs

      t.column :lock_version, :integer, null: false, default: 0

      t.index [:organization_id, :name], unique: true

      t.references :storage_type, foreign_key: true, null: false
      t.references :organization, foreign_key: true, null: false
    end

    create_table :memberships do |t|
      t.string :role, null: false
      t.references :user, foreign_key: true, null: false
      t.references :organization, foreign_key: true, null: false

      t.index [:user_id, :organization_id, :role], unique: true

      t.column :lock_version, :integer, null: false, default: 0
    end

    # Code tables
    # ###########

    create_table :material_flows do |t|
      t.string :name, null: false
      t.string :ext_id, null: false
      t.string :inst_code
      t.string :description
      t.string :ingest_dir, null: false
      t.string :ingest_type, null: false, default: 'METS'

      t.index [:inst_code, :name], unique: true

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :producers do |t|
      t.string :name, null: false
      t.string :ext_id, null: false
      t.string :inst_code, null: false
      t.string :description
      t.string :agent, null: false
      t.string :password, null: false

      t.index [:inst_code, :name], unique: true

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :retention_policies do |t|
      t.string :name, null: false, index: {unique: true}
      t.string :ext_id, null: false
      t.string :description

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :access_rights do |t|
      t.string :name, null: false, index: {unique: true}
      t.string :ext_id, null: false
      t.string :description

      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :representation_infos do |t|
      t.string :name, null: false, index: {unique: true}
      t.string :preservation_type, null: false, index: true
      t.string :usage_type, null: false
      t.string :representation_code

      t.column :lock_version, :integer, null: false, default: 0
    end

    # Inputs and configurations
    # #########################

    create_table :parameters do |t|
      t.string :name, null: false
      t.boolean :export, null: false, default: true
      t.string :data_type
      t.string :constraint
      t.string :default
      t.string :description
      t.text :help

      t.references :with_parameters, polymorphic: true, index: {name: :index_parameters_on_with_parameters}
      t.index [:with_parameters_type, :with_parameters_id, :name], name: :index_with_parameters_name,unique: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :parameter_references do |t|
      t.references :source, foreign_key: {to_table: :parameters, null: false}
      t.references :target, foreign_key: {to_table: :parameters, null: false}

      t.index [:source_id, :target_id], unique: true
      t.index [:target_id, :source_id], unique: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    # Converters
    # ##########

    create_table :converters do |t|
      t.string :category, null: false, default: 'converter'
      t.string :name
      t.string :class_name
      t.string :script_name
      t.string :description
      t.string :help
      t.string :input_formats, array: true
      t.string :output_formats, array: true
      # with_parameter_defs

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    # Stage Tasks and Workflows
    # #########################

    create_table :tasks do |t|
      t.string :stage, null: false
      t.string :name, null: false
      t.string :class_name, null: false
      t.string :description
      t.string :help
      # with_parameter_defs

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

    end

    create_table :stage_workflows do |t|
      t.string :stage, null: false
      t.string :name, null: false, index: {unique: true}
      t.string :description
      # with parameter_refs

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :stage_tasks do |t|
      t.integer :position

      t.references :stage_workflow, foreign_key: true, null: false
      t.references :task, foreign_key: true, null: false

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:stage_workflow_id, :position]#, unique: true
    end


    # Ingest Agreements
    # #################

    create_table :ingest_agreements do |t|
      t.string :name, null: false
      t.string :description
      t.string :project_name
      t.string :collection_name
      t.string :contact_ingest, array: true
      t.string :contact_collection, array: true
      t.string :contact_system, array: true
      t.string :collection_description
      t.string :ingest_run_name
      t.string :collector

      t.references :producer, foreign_key: true
      t.references :material_flow, foreign_key: true

      t.references :organization, foreign_key: true, null: false

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:organization_id, :name], unique: true
    end

    # Ingest Models, Representations and Conversions
    # ##############################################

    create_table :ingest_models do |t|
      t.string :name, null: false
      t.string :description
      t.string :entity_type
      t.string :user_a
      t.string :user_b
      t.string :user_c
      t.string :identifier
      t.string :status

      t.references :access_right, foreign_key: true, null: false
      t.references :retention_policy, foreign_key: true, null: false

      t.references :ingest_agreement, foreign_key: true, null: true

      t.references :template, foreign_key: {to_table: :ingest_models}

      t.index [:ingest_agreement_id, :name], unique: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :representations do |t|
      t.integer :position
      t.string :label, null: false
      t.boolean :optional, default: false
      t.boolean :keep_structure, default: true

      t.references :access_right, foreign_key: true
      t.references :representation_info, foreign_key: true, null: false

      t.references :from, foreign_key: {to_table: :representations}
      t.references :ingest_model, foreign_key: true, null: false

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:ingest_model_id, :position]#, unique: true
      t.index [:ingest_model_id, :label], unique: true
    end

    create_table :conversion_workflows do |t|
      t.integer :position
      t.string :name
      t.string :description
      t.boolean :copy_files, default: false
      t.boolean :copy_structure, default: true
      t.string :input_formats, array: true
      t.string :input_filename_regex

      t.references :representation, foreign_key: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:representation_id, :name], unique: true
      t.index [:representation_id, :position]#, unique: true

    end

    create_table :conversion_tasks do |t|
      t.integer :position
      t.string :name, null: false
      t.string :description
      t.string :output_format
      # with_values

      t.references :conversion_workflow, foreign_key: true
      t.references :converter, foreign_key: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:conversion_workflow_id, :name], unique: true
      t.index [:conversion_workflow_id, :position]#, unique: true

    end

    # Ingest Workflows
    # ################

    create_table :ingest_workflows do |t|
      t.string :name, null: false
      t.string :description
      # with_parameters

      t.references :ingest_agreement, foreign_key: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:ingest_agreement_id, :name], unique: true
    end

    create_table :ingest_stages do |t|
      t.string :stage
      t.boolean :autorun, null: false, default: true
      # with_values

      t.references :ingest_workflow, foreign_key: true
      t.references :stage_workflow, foreign_key: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:ingest_workflow_id, :stage], unique: true
    end

    # Packages, Runs and Items
    # ########################

    create_table :packages do |t|
      t.string :name, null: false
      t.string :stage
      t.string :status
      t.jsonb :options, default: '{}'
      # with_values

      t.references :ingest_workflow, null: false, foreign_key: true

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0
    end

    create_table :runs do |t|
      t.datetime :start_date
      t.boolean :log_to_file, default: false
      t.string :log_level, default: 'INFO'
      t.string :log_filename
      t.string :name, null: false
      t.jsonb :config, default: '{}'
      t.jsonb :options, default: '{}'
      t.jsonb :properties, default: '{}'

      t.references :package, foreign_key: {on_delete: :cascade}
      t.references :user, foreign_key: {on_delete: :nullify}

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index :options, using: :gin
      t.index :properties, using: :gin
    end

    create_table :items do |t|
      t.string :type, null: false
      t.references :parent, polymorphic: true
      t.integer :position
      t.string :name, null: false
      t.string :label
      t.jsonb :options, default: '{}'
      t.jsonb :properties, default: '{}'

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.column :lock_version, :integer, null: false, default: 0

      t.index [:parent_type, :parent_id, :position]#, unique: true
      t.index :options, using: :gin
      t.index :properties, using: :gin
    end

    create_table :metadata_records do |t|
      t.string :format, null: false
      t.xml :data

      t.references :item, foreign_key: true, null: false
    end

    create_table :status_logs do |t|
      t.string :status
      t.references :item, foreign_key: true
      t.references :run, foreign_key: true, null: false
      t.string :task
      t.integer :progress, default: 0
      t.integer :max, default: 0

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}
      t.index [:created_at, :run_id]
      t.index [:created_at, :item_id]
    end

    create_table :message_logs do |t|
      t.string :severity
      t.references :item, foreign_key: true
      t.references :run, foreign_key: true, null: false
      t.string :task
      t.string :message
      t.jsonb :data

      t.datetime :created_at, null: false, default: -> {'CURRENT_TIMESTAMP'}

      t.index [:created_at, :run_id, :severity]
      t.index [:created_at, :item_id, :severity]
    end

    # Formats database
    # ################

    create_table :formats do |t|
      t.string :name, null: false, index: {unique: true}
      t.string :category, null: false
      t.string :description
      t.string :mimetypes, array: true, null: false
      t.string :puids, array: true
      t.string :extensions, array: true, null: false

      t.timestamps default: -> {'CURRENT_TIMESTAMP'}

      t.index :mimetypes, using: :gin
      t.index :puids, using: :gin
      t.index :extensions, using: :gin
    end

  end
end
