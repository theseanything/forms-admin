# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_22_153000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "create_form_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dedup_version"
    t.bigint "form_id"
    t.string "form_name", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "form_name", "dedup_version"], name: "idx_on_group_id_form_name_dedup_version_9b12b4ae60", unique: true
    t.index ["group_id"], name: "index_create_form_events_on_group_id"
    t.index ["user_id"], name: "index_create_form_events_on_user_id"
  end

  create_table "draft_questions", force: :cascade do |t|
    t.jsonb "answer_settings", default: {}
    t.text "answer_type"
    t.datetime "created_at", null: false
    t.integer "form_id"
    t.text "guidance_markdown"
    t.text "hint_text"
    t.boolean "is_optional"
    t.boolean "is_repeatable"
    t.text "page_heading"
    t.string "page_id"
    t.text "question_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["form_id"], name: "index_draft_questions_on_form_id"
    t.index ["user_id"], name: "index_draft_questions_on_user_id"
  end

  create_table "form_documents", force: :cascade do |t|
    t.jsonb "content", comment: "The JSON which describes the form"
    t.datetime "created_at", null: false
    t.bigint "form_id", comment: "The form this document belongs to"
    t.datetime "published_at"
    t.bigint "supersedes_id"
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_form_documents_on_form_id"
    t.index ["supersedes_id"], name: "index_form_documents_on_supersedes_id"
  end

  create_table "form_submission_emails", force: :cascade do |t|
    t.string "confirmation_code"
    t.datetime "created_at", null: false
    t.string "created_by_email"
    t.string "created_by_name"
    t.integer "form_id"
    t.string "temporary_submission_email"
    t.datetime "updated_at", null: false
    t.string "updated_by_email"
    t.string "updated_by_name"
    t.index ["form_id"], name: "index_form_submission_emails_on_form_id"
  end

  create_table "forms", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.integer "copied_from_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.boolean "declaration_section_completed", default: false
    t.bigint "draft_form_document_id"
    t.string "external_id"
    t.datetime "first_made_live_at"
    t.string "language", default: "en", null: false
    t.bigint "live_form_document_id"
    t.boolean "question_section_completed", default: false
    t.boolean "share_preview_completed", default: false, null: false
    t.datetime "updated_at", null: false
    t.boolean "welsh_completed", default: false
    t.index ["draft_form_document_id"], name: "index_forms_on_draft_form_document_id"
    t.index ["external_id"], name: "index_forms_on_external_id", unique: true
    t.index ["live_form_document_id"], name: "index_forms_on_live_form_document_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "external_id", null: false
    t.boolean "multiple_branches_enabled", default: false
    t.string "name"
    t.bigint "organisation_id"
    t.string "status", default: "trial"
    t.datetime "updated_at", null: false
    t.bigint "upgrade_requester_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["external_id"], name: "index_groups_on_external_id", unique: true
    t.index ["name", "organisation_id"], name: "index_groups_on_name_and_organisation_id", unique: true
    t.index ["organisation_id"], name: "index_groups_on_organisation_id"
    t.index ["upgrade_requester_id"], name: "index_groups_on_upgrade_requester_id"
  end

  create_table "groups_form_ids", id: false, force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "group_id", null: false
    t.index ["form_id"], name: "index_groups_form_ids_on_form_id", unique: true
    t.index ["group_id"], name: "index_groups_form_ids_on_group_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "added_by_id", null: false, comment: "The user who created the membership"
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false, comment: "The group that the user is a member of"
    t.string "role", default: "editor"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, comment: "The user who is a member of the group"
    t.index ["added_by_id"], name: "index_memberships_on_added_by_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true, comment: "Ensure that a user can only be a member of a group once"
  end

  create_table "mou_signatures", comment: "User signatures of a memorandum of understanding (MOU) for an organisation", force: :cascade do |t|
    t.string "agreement_type", null: false
    t.datetime "created_at", null: false
    t.bigint "organisation_id", comment: "Organisation which user signed MOU on behalf of, or null"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, comment: "User who signed MOU"
    t.index ["organisation_id"], name: "index_mou_signatures_on_organisation_id"
    t.index ["user_id", "organisation_id"], name: "index_mou_signatures_on_user_id_and_organisation_id", unique: true, comment: "Users can only sign an MOU for an Organisation once"
    t.index ["user_id"], name: "index_mou_signatures_on_user_id"
    t.index ["user_id"], name: "index_mou_signatures_on_user_id_unique_without_organisation_id", unique: true, where: "(organisation_id IS NULL)", comment: "Users can only sign a single MOU without an organisation"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "abbreviation"
    t.boolean "closed", default: false
    t.datetime "created_at", null: false
    t.string "govuk_content_id"
    t.boolean "internal", default: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["govuk_content_id"], name: "index_organisations_on_govuk_content_id", unique: true
    t.index ["slug"], name: "index_organisations_on_slug", unique: true
  end

  create_table "schema_info", id: false, force: :cascade do |t|
    t.integer "version", default: 0, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "app_name"
    t.datetime "created_at", null: false
    t.boolean "disabled", default: false
    t.string "email"
    t.boolean "has_access", default: true
    t.datetime "last_signed_in_at"
    t.string "name"
    t.string "organisation_content_id"
    t.bigint "organisation_id"
    t.string "organisation_slug"
    t.text "permissions"
    t.string "provider"
    t.boolean "remotely_signed_out", default: false
    t.string "research_contact_status", default: "to_be_asked"
    t.string "role", default: "standard"
    t.datetime "terms_agreed_at"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.datetime "user_research_opted_in_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "create_form_events", "groups", on_delete: :cascade
  add_foreign_key "create_form_events", "users", on_delete: :cascade
  add_foreign_key "draft_questions", "users"
  add_foreign_key "form_documents", "form_documents", column: "supersedes_id"
  add_foreign_key "form_documents", "forms"
  add_foreign_key "forms", "form_documents", column: "draft_form_document_id"
  add_foreign_key "forms", "form_documents", column: "live_form_document_id"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "groups", "users", column: "upgrade_requester_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "users", column: "added_by_id"
  add_foreign_key "mou_signatures", "organisations"
  add_foreign_key "mou_signatures", "users"
  add_foreign_key "users", "organisations"
end
