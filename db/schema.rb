# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_03_20_120000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_rights", force: :cascade do |t|
    t.string "name", null: false
    t.string "ext_id", null: false
    t.string "description"
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_access_rights_on_name", unique: true
  end

  create_table "conversion_tasks", force: :cascade do |t|
    t.integer "position", null: false
    t.string "name", null: false
    t.string "description"
    t.string "output_format"
    t.bigint "conversion_workflow_id"
    t.bigint "converter_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["conversion_workflow_id", "name"], name: "index_conversion_tasks_on_conversion_workflow_id_and_name", unique: true
    t.index ["conversion_workflow_id", "position"], name: "index_conversion_tasks_on_conversion_workflow_id_and_position", unique: true
    t.index ["conversion_workflow_id"], name: "index_conversion_tasks_on_conversion_workflow_id"
    t.index ["converter_id"], name: "index_conversion_tasks_on_converter_id"
  end

  create_table "conversion_workflows", force: :cascade do |t|
    t.integer "position", null: false
    t.string "name"
    t.string "description"
    t.string "input_formats", array: true
    t.string "input_filename_regex"
    t.bigint "representation_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["representation_id", "name"], name: "index_conversion_workflows_on_representation_id_and_name", unique: true
    t.index ["representation_id", "position"], name: "index_conversion_workflows_on_representation_id_and_position", unique: true
    t.index ["representation_id"], name: "index_conversion_workflows_on_representation_id"
  end

  create_table "converters", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "class_name"
    t.string "script_name"
    t.string "input_formats", array: true
    t.string "output_formats", array: true
    t.string "category", default: "converter", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
  end

  create_table "formats", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.string "description"
    t.string "mime_types", null: false, array: true
    t.string "puids", array: true
    t.string "extensions", null: false, array: true
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["extensions"], name: "index_formats_on_extensions", using: :gin
    t.index ["mime_types"], name: "index_formats_on_mime_types", using: :gin
    t.index ["name"], name: "index_formats_on_name", unique: true
    t.index ["puids"], name: "index_formats_on_puids", using: :gin
  end

  create_table "ingest_agreements", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "project_name"
    t.string "collection_name"
    t.string "contact_ingest", array: true
    t.string "contact_collection", array: true
    t.string "contact_system", array: true
    t.string "collection_description"
    t.string "ingest_run_name"
    t.string "collector"
    t.bigint "producer_id"
    t.bigint "material_flow_id"
    t.bigint "organization_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["material_flow_id"], name: "index_ingest_agreements_on_material_flow_id"
    t.index ["organization_id", "name"], name: "index_ingest_agreements_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_ingest_agreements_on_organization_id"
    t.index ["producer_id"], name: "index_ingest_agreements_on_producer_id"
  end

  create_table "ingest_models", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "entity_type"
    t.string "user_a"
    t.string "user_b"
    t.string "user_c"
    t.string "identifier"
    t.string "status"
    t.bigint "access_right_id", null: false
    t.bigint "retention_policy_id", null: false
    t.bigint "ingest_agreement_id"
    t.bigint "template_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["access_right_id"], name: "index_ingest_models_on_access_right_id"
    t.index ["ingest_agreement_id", "name"], name: "index_ingest_models_on_ingest_agreement_id_and_name", unique: true
    t.index ["ingest_agreement_id"], name: "index_ingest_models_on_ingest_agreement_id"
    t.index ["retention_policy_id"], name: "index_ingest_models_on_retention_policy_id"
    t.index ["template_id"], name: "index_ingest_models_on_template_id"
  end

  create_table "ingest_stages", force: :cascade do |t|
    t.string "stage"
    t.boolean "autorun", default: true, null: false
    t.bigint "ingest_workflow_id"
    t.bigint "stage_workflow_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["ingest_workflow_id", "stage"], name: "index_ingest_stages_on_ingest_workflow_id_and_stage", unique: true
    t.index ["ingest_workflow_id"], name: "index_ingest_stages_on_ingest_workflow_id"
    t.index ["stage_workflow_id"], name: "index_ingest_stages_on_stage_workflow_id"
  end

  create_table "ingest_workflows", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.bigint "ingest_agreement_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["ingest_agreement_id", "name"], name: "index_ingest_workflows_on_ingest_agreement_id_and_name", unique: true
    t.index ["ingest_agreement_id"], name: "index_ingest_workflows_on_ingest_agreement_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "type", null: false
    t.integer "position"
    t.string "name", null: false
    t.string "label"
    t.json "options", default: "{}"
    t.json "properties", default: "{}"
    t.string "parent_type"
    t.bigint "parent_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["parent_id", "position"], name: "index_items_on_parent_id_and_position", unique: true
    t.index ["parent_type", "parent_id"], name: "index_items_on_parent_type_and_parent_id"
  end

  create_table "material_flows", force: :cascade do |t|
    t.string "name", null: false
    t.string "ext_id", null: false
    t.string "inst_code"
    t.string "description"
    t.string "ingest_dir", null: false
    t.string "ingest_type", default: "METS", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["inst_code", "name"], name: "index_material_flows_on_inst_code_and_name", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.string "role", null: false
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id", "role"], name: "index_memberships_on_user_id_and_organization_id_and_role", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "inst_code", null: false
    t.string "description"
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "packages", force: :cascade do |t|
    t.string "name", null: false
    t.string "stage"
    t.string "status"
    t.string "base_dir"
    t.bigint "ingest_workflow_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["ingest_workflow_id"], name: "index_packages_on_ingest_workflow_id"
  end

  create_table "parameter_references", force: :cascade do |t|
    t.bigint "source_id"
    t.bigint "target_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["source_id", "target_id"], name: "index_parameter_references_on_source_id_and_target_id", unique: true
    t.index ["source_id"], name: "index_parameter_references_on_source_id"
    t.index ["target_id", "source_id"], name: "index_parameter_references_on_target_id_and_source_id", unique: true
    t.index ["target_id"], name: "index_parameter_references_on_target_id"
  end

  create_table "parameters", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "export", default: true, null: false
    t.string "data_type"
    t.string "constraint"
    t.string "default"
    t.string "description"
    t.text "help"
    t.string "with_parameters_type"
    t.bigint "with_parameters_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["with_parameters_type", "with_parameters_id", "name"], name: "index_with_parameters_name", unique: true
    t.index ["with_parameters_type", "with_parameters_id"], name: "index_parameters_on_with_parameters"
  end

  create_table "producers", force: :cascade do |t|
    t.string "name", null: false
    t.string "ext_id", null: false
    t.string "inst_code", null: false
    t.string "description"
    t.string "agent", null: false
    t.string "password", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["inst_code", "name"], name: "index_producers_on_inst_code_and_name", unique: true
  end

  create_table "representation_infos", force: :cascade do |t|
    t.string "name", null: false
    t.string "preservation_type", null: false
    t.string "usage_type", null: false
    t.string "representation_code"
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_representation_infos_on_name", unique: true
    t.index ["preservation_type"], name: "index_representation_infos_on_preservation_type"
  end

  create_table "representations", force: :cascade do |t|
    t.integer "position", null: false
    t.string "label", null: false
    t.boolean "optional", default: false
    t.bigint "access_right_id"
    t.bigint "representation_info_id", null: false
    t.bigint "from_id"
    t.bigint "ingest_model_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["access_right_id"], name: "index_representations_on_access_right_id"
    t.index ["from_id"], name: "index_representations_on_from_id"
    t.index ["ingest_model_id", "label"], name: "index_representations_on_ingest_model_id_and_label", unique: true
    t.index ["ingest_model_id", "position"], name: "index_representations_on_ingest_model_id_and_position", unique: true
    t.index ["ingest_model_id"], name: "index_representations_on_ingest_model_id"
    t.index ["representation_info_id"], name: "index_representations_on_representation_info_id"
  end

  create_table "retention_policies", force: :cascade do |t|
    t.string "name", null: false
    t.string "ext_id", null: false
    t.string "description"
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_retention_policies_on_name", unique: true
  end

  create_table "runs", force: :cascade do |t|
    t.datetime "start_date"
    t.boolean "log_to_file", default: false
    t.string "log_level", default: "INFO"
    t.string "log_filename"
    t.string "name", null: false
    t.json "config", default: "{}"
    t.json "options", default: "{}"
    t.json "properties", default: "{}"
    t.bigint "package_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["package_id"], name: "index_runs_on_package_id"
  end

  create_table "stage_tasks", force: :cascade do |t|
    t.integer "position"
    t.bigint "stage_workflow_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["stage_workflow_id", "position"], name: "index_stage_tasks_on_stage_workflow_id_and_position", unique: true
    t.index ["stage_workflow_id"], name: "index_stage_tasks_on_stage_workflow_id"
    t.index ["task_id"], name: "index_stage_tasks_on_task_id"
  end

  create_table "stage_workflows", force: :cascade do |t|
    t.string "stage", null: false
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_stage_workflows_on_name", unique: true
  end

  create_table "status_logs", force: :cascade do |t|
    t.string "status"
    t.string "task"
    t.integer "progress", default: 0
    t.integer "max", default: 0
    t.bigint "item_id"
    t.bigint "run_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["item_id"], name: "index_status_logs_on_item_id"
    t.index ["run_id"], name: "index_status_logs_on_run_id"
  end

  create_table "storage_types", force: :cascade do |t|
    t.string "protocol", null: false
    t.string "description"
    t.integer "lock_version", default: 0, null: false
    t.index ["protocol"], name: "index_storage_types_on_protocol", unique: true
  end

  create_table "storages", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_upload", default: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "storage_type_id", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id", "name"], name: "index_storages_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_storages_on_organization_id"
    t.index ["storage_type_id"], name: "index_storages_on_storage_type_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "stage", null: false
    t.string "name", null: false
    t.string "class_name", null: false
    t.string "description"
    t.string "help"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "email", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "conversion_tasks", "conversion_workflows"
  add_foreign_key "conversion_tasks", "converters"
  add_foreign_key "conversion_workflows", "representations"
  add_foreign_key "ingest_agreements", "material_flows"
  add_foreign_key "ingest_agreements", "organizations"
  add_foreign_key "ingest_agreements", "producers"
  add_foreign_key "ingest_models", "access_rights"
  add_foreign_key "ingest_models", "ingest_agreements"
  add_foreign_key "ingest_models", "ingest_models", column: "template_id"
  add_foreign_key "ingest_models", "retention_policies"
  add_foreign_key "ingest_stages", "ingest_workflows"
  add_foreign_key "ingest_stages", "stage_workflows"
  add_foreign_key "ingest_workflows", "ingest_agreements"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "packages", "ingest_workflows"
  add_foreign_key "parameter_references", "parameters", column: "source_id"
  add_foreign_key "parameter_references", "parameters", column: "target_id"
  add_foreign_key "representations", "access_rights"
  add_foreign_key "representations", "ingest_models"
  add_foreign_key "representations", "representation_infos"
  add_foreign_key "representations", "representations", column: "from_id"
  add_foreign_key "runs", "packages", on_delete: :cascade
  add_foreign_key "stage_tasks", "stage_workflows"
  add_foreign_key "stage_tasks", "tasks"
  add_foreign_key "status_logs", "items", on_delete: :cascade
  add_foreign_key "status_logs", "runs"
  add_foreign_key "storages", "organizations"
  add_foreign_key "storages", "storage_types"
end
