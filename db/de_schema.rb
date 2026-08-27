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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_180004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "access_account_user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "account_user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_access_account_user_roles_on_account_id"
    t.index ["account_user_id", "role_id"], name: "idx_acc_user_role_composite"
    t.index ["account_user_id"], name: "index_access_account_user_roles_on_account_user_id"
    t.index ["created_at"], name: "index_access_account_user_roles_on_created_at"
    t.index ["role_id"], name: "index_access_account_user_roles_on_role_id"
  end

  create_table "access_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "identifier", null: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.boolean "system_provided", default: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "identifier"], name: "index_access_roles_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_access_roles_on_account_id_and_name"
    t.index ["account_id"], name: "index_access_roles_on_account_id"
    t.index ["created_at"], name: "index_access_roles_on_created_at"
  end

  create_table "activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "actor_id"
    t.string "actor_type"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "event_data", default: {}, null: false
    t.string "event_key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "object_changes", default: {}, null: false
    t.jsonb "object_snapshot", default: {}, null: false
    t.uuid "trackable_id", null: false
    t.string "trackable_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_activities_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_activities_on_account_id"
    t.index ["actor_type", "actor_id"], name: "index_activities_on_actor"
    t.index ["event_key"], name: "index_activities_on_event_key"
    t.index ["object_changes"], name: "index_activities_on_object_changes_gin", using: :gin
    t.index ["object_snapshot"], name: "index_activities_on_object_snapshot_gin", using: :gin
    t.index ["trackable_type", "trackable_id", "created_at"], name: "index_activities_on_trackable_and_created_at"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "ai_agent_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agent_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "fallback_message"
    t.string "greeting_message"
    t.string "handoff_message"
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["agent_id", "locale"], name: "index_ai_agent_translations_on_agent_id_and_locale", unique: true
  end

  create_table "ai_agents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "agent_type", default: 0, null: false
    t.float "confidence_threshold", default: 0.7, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "language", default: "en", null: false
    t.integer "max_exchanges", default: 5, null: false
    t.string "name", default: "AI Assistant", null: false
    t.uuid "portal_id"
    t.integer "status", default: 0, null: false
    t.text "system_prompt"
    t.integer "tone", default: 0, null: false
    t.integer "total_conversations", default: 0, null: false
    t.integer "total_handoffs", default: 0, null: false
    t.integer "total_resolutions", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "status"], name: "index_ai_agents_on_account_id_and_status"
    t.index ["account_id"], name: "index_ai_agents_on_account_id"
    t.index ["portal_id"], name: "index_ai_agents_on_portal_id"
  end

  create_table "applied_labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "label_id", null: false
    t.uuid "labelable_id", null: false
    t.string "labelable_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_applied_labels_on_account_id"
    t.index ["label_id"], name: "index_applied_labels_on_label_id"
    t.index ["labelable_id", "labelable_type", "label_id"], name: "index_applied_labels_uniqueness", unique: true
    t.index ["labelable_type", "labelable_id"], name: "index_applied_labels_on_labelable"
  end

  create_table "assignment_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id"
    t.jsonb "conditions", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.integer "idle_timeout_minutes"
    t.integer "max_conversations_per_agent"
    t.string "name", null: false
    t.integer "position"
    t.boolean "prioritize_by_conversation_priority", default: false, null: false
    t.boolean "reassign_on_offline", default: false, null: false
    t.boolean "respect_business_hours", default: false, null: false
    t.integer "status", default: 0, null: false
    t.integer "strategy", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_assignment_policies_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_assignment_policies_on_account_id_and_name"
    t.index ["account_id", "status", "position"], name: "idx_ap_execution_order"
    t.index ["account_id"], name: "index_assignment_policies_on_account_id"
    t.index ["business_hour_group_id"], name: "index_assignment_policies_on_business_hour_group_id"
  end

  create_table "assignment_policy_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "assignment_policy_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_assignment_policy_inboxes_on_account_id"
    t.index ["assignment_policy_id", "inbox_id"], name: "idx_ap_inbox_unique", unique: true
    t.index ["assignment_policy_id"], name: "index_assignment_policy_inboxes_on_assignment_policy_id"
    t.index ["inbox_id"], name: "index_assignment_policy_inboxes_on_inbox_id"
  end

  create_table "attachment_translations", force: :cascade do |t|
    t.string "alt_title"
    t.uuid "attachment_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["attachment_id", "locale"], name: "index_attachment_translations_on_attachment_id_and_locale", unique: true
    t.index ["attachment_id"], name: "index_attachment_translations_on_attachment_id"
    t.index ["locale"], name: "index_attachment_translations_on_locale"
  end

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "attachment_type", default: 0, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "extension"
    t.float "latitude"
    t.float "longitude"
    t.string "remote_url"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "attachment_type"], name: "index_attachments_on_account_id_and_attachment_type"
    t.index ["account_id"], name: "index_attachments_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_attachments_on_resource"
  end

  create_table "automation_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "error_message"
    t.uuid "executable_id", null: false
    t.string "executable_type", null: false
    t.jsonb "executed_actions", default: [], null: false
    t.datetime "executed_at", null: false
    t.integer "execution_duration_ms"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "triggered_by", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "executed_at"], name: "index_automation_executions_on_account_id_and_executed_at"
    t.index ["account_id", "status"], name: "index_automation_executions_on_account_id_and_status"
    t.index ["account_id", "triggered_by"], name: "index_automation_executions_on_account_id_and_triggered_by"
    t.index ["account_id"], name: "index_automation_executions_on_account_id"
    t.index ["executable_type", "executable_id", "executed_at"], name: "idx_automation_executions_executable_timeline"
    t.index ["executable_type", "executable_id"], name: "index_automation_executions_on_executable"
    t.index ["resource_type", "resource_id"], name: "index_automation_executions_on_resource"
  end

  create_table "automations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "actions", default: [], null: false
    t.integer "automation_type", default: 1, null: false
    t.jsonb "conditions", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "event_name"
    t.integer "flags", default: 0, null: false
    t.string "name", null: false
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.boolean "system_provided", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "automation_type", "event_name", "status"], name: "idx_automations_event_lookup"
    t.index ["account_id", "automation_type", "status", "position"], name: "idx_automations_execution_order"
    t.index ["account_id", "created_at"], name: "index_automations_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_automations_on_account_id_and_name"
    t.index ["account_id", "system_provided"], name: "index_automations_on_account_id_and_system_provided"
    t.index ["account_id"], name: "index_automations_on_account_id"
  end

  create_table "business_hour_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "name", null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_business_hour_groups_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_business_hour_groups_on_account_id_and_name"
    t.index ["account_id"], name: "index_business_hour_groups_on_account_id"
  end

  create_table "business_hour_translations", force: :cascade do |t|
    t.uuid "business_hour_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.text "reason"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["business_hour_id", "locale"], name: "idx_on_business_hour_id_locale_71e69d1935", unique: true
    t.index ["business_hour_id"], name: "index_business_hour_translations_on_business_hour_id"
    t.index ["locale"], name: "index_business_hour_translations_on_locale"
  end

  create_table "business_hours", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id", null: false
    t.datetime "close_from"
    t.datetime "close_till"
    t.time "closing_time"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "day_of_week"
    t.time "opening_time"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_business_hours_on_account_id"
    t.index ["business_hour_group_id", "close_from", "close_till"], name: "index_business_hours_on_close_time"
    t.index ["business_hour_group_id", "created_at"], name: "index_business_hours_on_business_hour_group_id_and_created_at"
    t.index ["business_hour_group_id", "day_of_week", "opening_time", "closing_time"], name: "index_business_hours_on_work_time"
    t.index ["business_hour_group_id"], name: "index_business_hours_on_business_hour_group_id"
  end

  create_table "canned_response_translations", force: :cascade do |t|
    t.uuid "canned_response_id", null: false
    t.string "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["canned_response_id", "locale"], name: "idx_on_canned_response_id_locale_63eed27ff0", unique: true
    t.index ["canned_response_id"], name: "index_canned_response_translations_on_canned_response_id"
    t.index ["locale"], name: "index_canned_response_translations_on_locale"
  end

  create_table "canned_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "identifier", null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_canned_responses_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_canned_responses_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_canned_responses_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_canned_responses_on_account_id_and_status"
    t.index ["account_id"], name: "index_canned_responses_on_account_id"
  end

  create_table "channel_contact_form_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "contact_form_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.string "submit_button_text"
    t.string "subtitle"
    t.string "success_message"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["contact_form_id", "locale"], name: "index_ccft_on_contact_form_id_and_locale", unique: true
    t.index ["contact_form_id"], name: "index_ccft_on_contact_form_id"
  end

  create_table "channel_contact_forms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "allowed_hosts", default: [], array: true
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "flags", default: 0, null: false
    t.string "name"
    t.uuid "outbound_channel_id"
    t.string "outbound_channel_type"
    t.string "secret", null: false
    t.integer "status", default: 0, null: false
    t.string "submit_redirect_url"
    t.jsonb "ui_configurations", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_contact_forms_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_channel_contact_forms_on_account_id_and_status"
    t.index ["account_id"], name: "index_channel_contact_forms_on_account_id"
    t.index ["outbound_channel_type", "outbound_channel_id"], name: "index_channel_contact_forms_on_outbound_channel"
    t.index ["secret"], name: "index_channel_contact_forms_on_secret", unique: true
  end

  create_table "channel_customs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "description"
    t.jsonb "headers", default: {}, null: false
    t.string "hmac_token", null: false
    t.string "identifier", null: false
    t.string "name"
    t.jsonb "response_mapping", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "webhook_secret", null: false
    t.string "webhook_url"
    t.index ["account_id", "created_at"], name: "index_channel_customs_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_channel_customs_on_account_id_and_identifier", unique: true
    t.index ["account_id"], name: "index_channel_customs_on_account_id"
    t.index ["status"], name: "index_channel_customs_on_status"
  end

  create_table "channel_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "email"
    t.integer "flags", default: 0, null: false
    t.string "forward_email"
    t.string "forward_email_token"
    t.datetime "forwarding_verified_at"
    t.jsonb "imap_configurations", default: {}, null: false
    t.string "name"
    t.integer "service"
    t.jsonb "smtp_configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_emails_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_emails_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_emails_on_account_id"
    t.index ["email"], name: "index_channel_emails_on_email", unique: true
    t.index ["flags"], name: "index_channel_emails_on_flags"
    t.index ["forward_email"], name: "index_channel_emails_on_forward_email", unique: true
    t.index ["status"], name: "index_channel_emails_on_status"
  end

  create_table "channel_facebook_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token", null: false
    t.uuid "account_id", null: false
    t.string "avatar_url"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "name"
    t.string "page_identifier", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "user_access_token"
    t.index ["account_id", "created_at"], name: "index_channel_facebook_pages_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_facebook_pages_on_account_id_and_name"
    t.index ["account_id", "page_identifier"], name: "index_channel_facebook_pages_on_account_id_and_page_identifier", unique: true
    t.index ["account_id"], name: "index_channel_facebook_pages_on_account_id"
    t.index ["page_identifier"], name: "index_channel_facebook_pages_on_page_identifier"
    t.index ["status"], name: "index_channel_facebook_pages_on_status"
  end

  create_table "channel_instagram", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token", null: false
    t.uuid "account_id", null: false
    t.string "avatar_url"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "expires_at", null: false
    t.string "instagram_id", null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "username"
    t.index ["account_id", "created_at"], name: "index_channel_instagram_on_account_id_and_created_at"
    t.index ["account_id", "instagram_id"], name: "index_channel_instagram_on_account_id_and_instagram_id", unique: true
    t.index ["account_id"], name: "index_channel_instagram_on_account_id"
    t.index ["instagram_id"], name: "index_channel_instagram_on_instagram_id", unique: true
    t.index ["status"], name: "index_channel_instagram_on_status"
  end

  create_table "channel_short_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "full_phone_number"
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.integer "service", default: 0, null: false
    t.string "service_identifier"
    t.integer "short_message_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_short_messages_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_short_messages_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_short_messages_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_short_messages_on_full_phone_number", unique: true
    t.index ["service", "service_identifier"], name: "index_channel_short_messages_on_service_and_service_identifier", unique: true
    t.index ["status"], name: "index_channel_short_messages_on_status"
  end

  create_table "channel_web_widget_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "launcher_text"
    t.string "locale", null: false
    t.string "pre_chat_subtitle"
    t.string "pre_chat_title"
    t.string "reply_time_text"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "web_widget_id", null: false
    t.string "welcome_tagline"
    t.string "welcome_title"
    t.index ["web_widget_id", "locale"], name: "index_cwwt_on_widget_and_locale", unique: true
  end

  create_table "channel_web_widgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "allowed_hosts", default: [], array: true
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "default_locale", default: "en", null: false
    t.uuid "fallback_channel_id"
    t.string "fallback_channel_type"
    t.integer "flags", default: 0, null: false
    t.string "name"
    t.uuid "portal_id"
    t.uuid "pre_chat_form_id"
    t.string "secret", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_web_widgets_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_web_widgets_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_web_widgets_on_account_id"
    t.index ["fallback_channel_type", "fallback_channel_id"], name: "index_web_widgets_on_fallback_channel"
    t.index ["portal_id"], name: "index_channel_web_widgets_on_portal_id"
    t.index ["pre_chat_form_id"], name: "index_channel_web_widgets_on_pre_chat_form_id"
    t.index ["secret"], name: "index_channel_web_widgets_on_secret", unique: true
    t.index ["status"], name: "index_channel_web_widgets_on_status"
  end

  create_table "channel_whatsapps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "api_key"
    t.string "business_account_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "flags", default: 0, null: false
    t.string "full_phone_number", null: false
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.string "phone_number_id"
    t.integer "service", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "webhook_secret"
    t.index ["account_id", "created_at"], name: "index_channel_whatsapps_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_whatsapps_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_whatsapps_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_whatsapps_on_full_phone_number", unique: true
    t.index ["service"], name: "index_channel_whatsapps_on_service"
    t.index ["status"], name: "index_channel_whatsapps_on_status"
  end

  create_table "conversation_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_activity_at"
    t.datetime "last_seen_at"
    t.uuid "member_id", null: false
    t.string "member_type", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_conversation_members_on_account_id"
    t.index ["conversation_id", "member_id"], name: "index_conversation_members_on_conversation_id_and_member_id", unique: true
    t.index ["conversation_id", "role"], name: "index_conversation_members_on_conversation_id_and_role"
    t.index ["conversation_id"], name: "index_conversation_members_on_conversation_id"
    t.index ["member_type", "member_id"], name: "index_conversation_members_on_member"
  end

  create_table "conversation_slas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "sla_policy_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "target_first_response_at"
    t.datetime "target_next_response_at"
    t.datetime "target_resolution_at"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_conversation_slas_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_conversation_slas_on_account_id_and_status"
    t.index ["account_id"], name: "index_conversation_slas_on_account_id"
    t.index ["conversation_id", "sla_policy_id"], name: "index_conversation_slas_on_conversation_id_and_sla_policy_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_conversation_slas_on_sla_policy_id"
    t.index ["target_first_response_at"], name: "index_conversation_slas_on_target_first_response_at"
    t.index ["target_next_response_at"], name: "index_conversation_slas_on_target_next_response_at"
    t.index ["target_resolution_at"], name: "index_conversation_slas_on_target_resolution_at"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "ai_metadata", default: {}, null: false
    t.integer "ai_status", default: 0, null: false
    t.uuid "assignee_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "external_id"
    t.datetime "first_respond_at"
    t.string "identifier", null: false
    t.uuid "inbox_id", null: false
    t.datetime "last_activity_at"
    t.string "locale"
    t.uuid "outbound_channel_id"
    t.string "outbound_channel_type"
    t.integer "priority", default: 0, null: false
    t.integer "source"
    t.integer "status", default: 0, null: false
    t.datetime "status_changed_at"
    t.uuid "team_id"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_conversations_on_account_id_and_created_at"
    t.index ["account_id", "external_id"], name: "index_conversations_on_account_id_and_external_id"
    t.index ["account_id", "identifier"], name: "index_conversations_on_account_id_and_identifier", unique: true
    t.index ["account_id", "last_activity_at"], name: "index_conversations_on_account_id_and_last_activity_at"
    t.index ["account_id", "priority"], name: "index_conversations_on_account_id_and_priority"
    t.index ["account_id", "status"], name: "index_conversations_on_account_id_and_status"
    t.index ["account_id", "title"], name: "index_conversations_on_account_id_and_title"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["ai_metadata"], name: "index_conversations_on_ai_metadata", using: :gin
    t.index ["assignee_id"], name: "index_conversations_on_assignee_id"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
    t.index ["outbound_channel_type", "outbound_channel_id"], name: "index_conversations_on_outbound_channel"
    t.index ["team_id"], name: "index_conversations_on_team_id"
  end

  create_table "csat_survey_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "content"
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "csat_survey_id"
    t.uuid "customer_id", null: false
    t.uuid "message_id"
    t.integer "rating"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "rating"], name: "index_csat_survey_responses_on_account_id_and_rating"
    t.index ["account_id", "status"], name: "index_csat_survey_responses_on_account_id_and_status"
    t.index ["account_id"], name: "index_csat_survey_responses_on_account_id"
    t.index ["conversation_id"], name: "index_csat_survey_responses_on_conversation_id"
    t.index ["csat_survey_id"], name: "index_csat_survey_responses_on_csat_survey_id"
    t.index ["customer_id"], name: "index_csat_survey_responses_on_customer_id"
    t.index ["message_id"], name: "index_csat_survey_responses_on_message_id"
  end

  create_table "csat_survey_translations", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.string "portal_feedback_label"
    t.text "portal_subtitle"
    t.string "portal_title"
    t.string "prompt"
    t.uuid "survey_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["locale"], name: "index_csat_survey_translations_on_locale"
    t.index ["survey_id", "locale"], name: "index_csat_translations_on_survey_and_locale", unique: true
    t.index ["survey_id"], name: "index_csat_survey_translations_on_survey_id"
  end

  create_table "csat_surveys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "email_template_id"
    t.string "name", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_csat_surveys_on_account_id"
    t.index ["email_template_id"], name: "index_csat_surveys_on_email_template_id"
  end

  create_table "custom_field_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "custom_field_id", null: false
    t.integer "position"
    t.boolean "required_override"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["custom_field_id", "resource_type", "resource_id"], name: "idx_custom_field_resources_unique", unique: true
    t.index ["custom_field_id"], name: "index_custom_field_resources_on_custom_field_id"
    t.index ["resource_type", "resource_id", "position"], name: "idx_cfr_on_resource_and_position"
  end

  create_table "custom_field_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "custom_field_id", null: false
    t.text "description"
    t.string "label"
    t.string "locale", null: false
    t.jsonb "options", default: [], null: false
    t.string "placeholder"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["custom_field_id", "locale"], name: "index_custom_field_translations_on_custom_field_id_and_locale", unique: true
    t.index ["custom_field_id"], name: "index_custom_field_translations_on_custom_field_id"
  end

  create_table "custom_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "entity_type", default: 0, null: false
    t.integer "field_type", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.string "key", null: false
    t.string "mapped_to"
    t.integer "position"
    t.boolean "required", default: false, null: false
    t.boolean "system_provided", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "validations", default: {}, null: false
    t.index ["account_id", "created_at"], name: "index_custom_fields_on_account_id_and_created_at"
    t.index ["account_id", "entity_type"], name: "index_custom_fields_on_account_id_and_entity_type"
    t.index ["account_id", "field_type"], name: "index_custom_fields_on_account_id_and_field_type"
    t.index ["account_id", "key"], name: "index_custom_fields_on_account_id_and_key", unique: true
    t.index ["account_id", "position"], name: "index_custom_fields_on_account_id_and_position"
    t.index ["account_id"], name: "index_custom_fields_on_account_id"
  end

  create_table "customer_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "connection_token", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "customer_id", null: false
    t.string "external_id", null: false
    t.uuid "inbox_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["connection_token"], name: "index_customer_inboxes_on_connection_token", unique: true
    t.index ["customer_id", "inbox_id"], name: "index_customer_inboxes_on_customer_id_and_inbox_id", unique: true
    t.index ["customer_id"], name: "index_customer_inboxes_on_customer_id"
    t.index ["external_id"], name: "index_customer_inboxes_on_external_id"
    t.index ["inbox_id"], name: "index_customer_inboxes_on_inbox_id"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.integer "customer_type", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.string "display_name"
    t.date "dob"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "external_id"
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "full_phone_number"
    t.integer "gender"
    t.string "identifier"
    t.datetime "last_activity_at"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "locale", default: "en", null: false
    t.datetime "locked_at"
    t.string "middle_name"
    t.string "name", default: ""
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "schedular_data", default: {}, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "username"
    t.index ["account_id", "created_at"], name: "index_customers_on_account_id_and_created_at"
    t.index ["account_id", "email"], name: "index_customers_on_account_id_and_email", unique: true
    t.index ["account_id", "external_id"], name: "index_customers_on_account_id_and_external_id"
    t.index ["account_id", "full_phone_number"], name: "index_customers_on_account_id_and_full_phone_number"
    t.index ["account_id", "locale"], name: "index_customers_on_account_id_and_locale"
    t.index ["account_id", "name"], name: "index_customers_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_customers_on_account_id_and_status"
    t.index ["account_id", "username"], name: "index_customers_on_account_id_and_username", unique: true
    t.index ["account_id"], name: "index_customers_on_account_id"
    t.index ["confirmation_token"], name: "index_customers_on_confirmation_token", unique: true
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_customers_on_unlock_token", unique: true
  end

  create_table "email_template_layout_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.text "compiled_html"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "design", default: {}
    t.text "draft_body"
    t.jsonb "draft_design", default: {}
    t.uuid "email_template_layout_id", null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_layout_id", "locale"], name: "idx_email_layout_translations_on_layout_id_and_locale", unique: true
    t.index ["email_template_layout_id"], name: "idx_on_email_template_layout_id_412d4e8613"
    t.index ["locale"], name: "index_email_template_layout_translations_on_locale"
  end

  create_table "email_template_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_template_layouts_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_template_layouts_on_account_id"
  end

  create_table "email_template_translations", force: :cascade do |t|
    t.text "body"
    t.text "compiled_html"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "design", default: {}
    t.text "draft_body"
    t.jsonb "draft_design", default: {}
    t.string "draft_subject"
    t.uuid "email_template_id", null: false
    t.string "locale", null: false
    t.string "subject"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_id", "locale"], name: "idx_on_email_template_id_locale_c1ab8a226b", unique: true
    t.index ["email_template_id"], name: "index_email_template_translations_on_email_template_id"
    t.index ["locale"], name: "index_email_template_translations_on_locale"
    t.index ["subject", "locale"], name: "index_email_template_translations_on_subject_and_locale"
  end

  create_table "email_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "email_template_layout_id"
    t.string "name"
    t.integer "status", default: 0, null: false
    t.integer "template_type"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_templates_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_templates_on_account_id"
    t.index ["email_template_layout_id"], name: "index_email_templates_on_email_template_layout_id"
  end

  create_table "filters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "filter_type", default: 0, null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id", "created_at"], name: "index_filters_on_account_id_and_created_at"
    t.index ["account_id", "filter_type"], name: "index_filters_on_account_id_and_filter_type"
    t.index ["account_id", "name"], name: "index_filters_on_account_id_and_name"
    t.index ["account_id"], name: "index_filters_on_account_id"
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "help_center_article_reactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "article_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "ip_address"
    t.integer "reaction_type", null: false
    t.string "session_id"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id", "ip_address"], name: "idx_on_article_id_ip_address_26c6109755", unique: true
    t.index ["article_id"], name: "index_help_center_article_reactions_on_article_id"
    t.index ["reaction_type"], name: "index_help_center_article_reactions_on_reaction_type"
  end

  create_table "help_center_article_translations", force: :cascade do |t|
    t.boolean "ai_training_synced", default: false, null: false
    t.uuid "article_id", null: false
    t.text "content"
    t.jsonb "content_embedding"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "draft_content"
    t.string "draft_title"
    t.string "locale", null: false
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.text "meta_title"
    t.text "search_excerpt"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["ai_training_synced"], name: "index_help_center_article_translations_on_ai_training_synced"
    t.index ["article_id", "locale"], name: "idx_on_article_id_locale_b93b0eb9fb", unique: true
    t.index ["article_id", "slug"], name: "index_help_center_article_translations_on_article_id_and_slug"
    t.index ["article_id"], name: "index_help_center_article_translations_on_article_id"
    t.index ["locale"], name: "index_help_center_article_translations_on_locale"
    t.index ["title", "locale"], name: "index_help_center_article_translations_on_title_and_locale"
  end

  create_table "help_center_articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "article_type", default: 0, null: false
    t.uuid "author_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "portal_id", null: false
    t.integer "position"
    t.uuid "primary_category_id"
    t.jsonb "stats", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "views_count", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id"], name: "index_help_center_articles_on_account_id"
    t.index ["author_id"], name: "index_help_center_articles_on_author_id"
    t.index ["portal_id", "article_type"], name: "index_help_center_articles_on_portal_id_and_article_type"
    t.index ["portal_id", "created_at"], name: "index_help_center_articles_on_portal_id_and_created_at"
    t.index ["portal_id", "flags"], name: "index_help_center_articles_on_portal_id_and_flags"
    t.index ["portal_id", "position"], name: "index_help_center_articles_on_portal_id_and_position"
    t.index ["portal_id", "status"], name: "index_help_center_articles_on_portal_id_and_status"
    t.index ["portal_id", "visibility"], name: "index_help_center_articles_on_portal_id_and_visibility"
    t.index ["portal_id"], name: "index_help_center_articles_on_portal_id"
    t.index ["primary_category_id"], name: "index_help_center_articles_on_primary_category_id"
  end

  create_table "help_center_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "flags", default: 0, null: false
    t.string "icon_key"
    t.uuid "portal_id", null: false
    t.integer "position"
    t.integer "published_articles_count", default: 0, null: false
    t.jsonb "stats", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "views_count", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id"], name: "index_help_center_categories_on_account_id"
    t.index ["portal_id", "ancestry"], name: "index_help_center_categories_on_portal_id_and_ancestry"
    t.index ["portal_id", "created_at"], name: "index_help_center_categories_on_portal_id_and_created_at"
    t.index ["portal_id", "flags"], name: "index_help_center_categories_on_portal_id_and_flags"
    t.index ["portal_id", "position"], name: "index_help_center_categories_on_portal_id_and_position"
    t.index ["portal_id", "status"], name: "index_help_center_categories_on_portal_id_and_status"
    t.index ["portal_id", "visibility"], name: "index_help_center_categories_on_portal_id_and_visibility"
    t.index ["portal_id"], name: "index_help_center_categories_on_portal_id"
  end

  create_table "help_center_category_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "position", default: 0, null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "resource_id", "resource_type"], name: "idx_on_category_id_resource_id_resource_type_3ce5a596a2", unique: true
    t.index ["category_id"], name: "index_help_center_category_resources_on_category_id"
    t.index ["position"], name: "index_help_center_category_resources_on_position"
    t.index ["resource_type", "resource_id"], name: "index_help_center_category_resources_on_resource"
  end

  create_table "help_center_category_translations", force: :cascade do |t|
    t.uuid "category_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "locale", null: false
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.text "meta_title"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "locale"], name: "idx_on_category_id_locale_d331d52f3b", unique: true
    t.index ["category_id", "slug"], name: "idx_on_category_id_slug_4dabbf4c72"
    t.index ["category_id"], name: "index_help_center_category_translations_on_category_id"
    t.index ["locale"], name: "index_help_center_category_translations_on_locale"
    t.index ["name", "locale"], name: "index_help_center_category_translations_on_name_and_locale"
  end

  create_table "help_center_portal_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "contact_page_subtitle"
    t.string "contact_page_title"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "footer_text"
    t.string "header_tagline"
    t.string "hero_subtitle"
    t.string "hero_title"
    t.string "locale", null: false
    t.uuid "portal_id", null: false
    t.string "search_placeholder"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["portal_id", "locale"], name: "index_help_center_portal_translations_on_portal_id_and_locale", unique: true
    t.index ["portal_id"], name: "index_help_center_portal_translations_on_portal_id"
  end

  create_table "help_center_portals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.uuid "contact_form_channel_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "default_locale", default: "en", null: false
    t.uuid "domain_id", null: false
    t.integer "flags", default: 0, null: false
    t.string "locales", default: ["en"], null: false, array: true
    t.string "name"
    t.integer "status", default: 0, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_help_center_portals_on_account_id_and_created_at"
    t.index ["account_id", "default_locale"], name: "index_help_center_portals_on_account_id_and_default_locale"
    t.index ["account_id", "name"], name: "index_help_center_portals_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_help_center_portals_on_account_id_and_status"
    t.index ["account_id"], name: "index_help_center_portals_on_account_id"
    t.index ["contact_form_channel_id"], name: "index_help_center_portals_on_contact_form_channel_id"
    t.index ["domain_id"], name: "index_help_center_portals_on_domain_id", unique: true
  end

  create_table "help_center_redirects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale"
    t.uuid "portal_id", null: false
    t.string "source_path", null: false
    t.integer "status_code", default: 301, null: false
    t.string "target_path", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["portal_id", "source_path", "locale"], name: "idx_on_portal_id_source_path_locale_07330b3b65", unique: true
    t.index ["portal_id"], name: "index_help_center_redirects_on_portal_id"
  end

  create_table "help_center_related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "linked_resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_help_center_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_help_center_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_help_center_related_resources_on_resource"
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.string "administration_url"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "custom_attributes", default: {}, null: false
    t.uuid "customer_id", null: false
    t.string "external_id"
    t.string "first_name"
    t.string "identifier", null: false
    t.uuid "identity_source_id"
    t.integer "identity_type", default: 0, null: false
    t.string "last_name"
    t.string "middle_name"
    t.string "name"
    t.jsonb "raw_response", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_identities_on_account_id_and_created_at"
    t.index ["account_id", "external_id"], name: "index_identities_on_account_id_and_external_id"
    t.index ["account_id", "identifier"], name: "index_identities_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_identities_on_account_id_and_name"
    t.index ["account_id"], name: "index_identities_on_account_id"
    t.index ["customer_id", "identity_source_id"], name: "index_identities_on_customer_id_and_identity_source_id", unique: true
    t.index ["customer_id"], name: "index_identities_on_customer_id"
    t.index ["identity_source_id"], name: "index_identities_on_identity_source_id"
  end

  create_table "identity_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.jsonb "headers", default: {}, null: false
    t.string "name", null: false
    t.jsonb "params", default: {}, null: false
    t.jsonb "response_mapping", default: {}, null: false
    t.integer "source_type", default: 0, null: false
    t.string "source_url"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_identity_sources_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_identity_sources_on_account_id_and_name"
    t.index ["account_id"], name: "index_identity_sources_on_account_id"
  end

  create_table "inbox_teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.uuid "team_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["inbox_id", "team_id"], name: "index_inbox_teams_on_inbox_id_and_team_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_teams_on_inbox_id"
    t.index ["team_id"], name: "index_inbox_teams_on_team_id"
  end

  create_table "inbox_translations", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "greetings"
    t.uuid "inbox_id", null: false
    t.string "locale", null: false
    t.text "notice"
    t.text "out_of_office_message"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["inbox_id", "locale"], name: "index_inbox_translations_on_inbox_id_and_locale", unique: true
    t.index ["inbox_id"], name: "index_inbox_translations_on_inbox_id"
    t.index ["locale"], name: "index_inbox_translations_on_locale"
  end

  create_table "inbox_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_inbox_users_on_created_at"
    t.index ["inbox_id", "user_id"], name: "index_inbox_users_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_users_on_inbox_id"
    t.index ["user_id"], name: "index_inbox_users_on_user_id"
  end

  create_table "inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "ai_agent_id"
    t.uuid "business_hour_group_id"
    t.uuid "channel_id", null: false
    t.string "channel_type", null: false
    t.jsonb "configurations", default: {}, null: false
    t.uuid "conversation_reply_template_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "csat_survey_id"
    t.string "default_locale", default: "en", null: false
    t.string "display_name"
    t.integer "flags", default: 0, null: false
    t.string "name", default: "", null: false
    t.boolean "primary_inbox", default: false, null: false
    t.integer "reopen_window_seconds", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_inboxes_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_inboxes_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_inboxes_on_account_id_and_status"
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["ai_agent_id"], name: "index_inboxes_on_ai_agent_id"
    t.index ["business_hour_group_id"], name: "index_inboxes_on_business_hour_group_id"
    t.index ["channel_type", "channel_id"], name: "index_inboxes_on_channel"
    t.index ["channel_type", "channel_id"], name: "index_inboxes_on_channel_primary", unique: true, where: "(primary_inbox = true)"
    t.index ["conversation_reply_template_id"], name: "index_inboxes_on_conversation_reply_template_id"
    t.index ["csat_survey_id"], name: "index_inboxes_on_csat_survey_id"
  end

  create_table "integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "provider", null: false
    t.jsonb "settings", default: {}
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "provider"], name: "index_integrations_on_account_id_and_provider"
    t.index ["account_id"], name: "index_integrations_on_account_id"
    t.index ["created_at"], name: "index_integrations_on_created_at"
  end

  create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "color"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.string "identifier", null: false
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_labels_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_labels_on_account_id_and_identifier", unique: true
    t.index ["account_id", "title"], name: "index_labels_on_account_id_and_title"
    t.index ["account_id"], name: "index_labels_on_account_id"
  end

  create_table "macros", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "actions", default: [], null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.string "name", null: false
    t.uuid "scopeable_id"
    t.string "scopeable_type"
    t.integer "status", default: 0, null: false
    t.boolean "system_provided", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id", "name"], name: "index_macros_on_account_id_and_name"
    t.index ["account_id", "scopeable_type", "scopeable_id"], name: "idx_macros_scopeable"
    t.index ["account_id", "status"], name: "index_macros_on_account_id_and_status"
    t.index ["account_id", "system_provided"], name: "index_macros_on_account_id_and_system_provided"
    t.index ["account_id", "visibility"], name: "index_macros_on_account_id_and_visibility"
    t.index ["account_id"], name: "index_macros_on_account_id"
    t.index ["created_at"], name: "index_macros_on_created_at"
    t.index ["scopeable_type", "scopeable_id"], name: "index_macros_on_scopeable"
  end

  create_table "mentions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "mentioned_id", null: false
    t.string "mentioned_type", null: false
    t.datetime "read_at"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "mentioned_id", "read_at"], name: "index_mentions_on_account_user_read"
    t.index ["account_id"], name: "index_mentions_on_account_id"
    t.index ["mentioned_type", "mentioned_id"], name: "index_mentions_on_mentioned"
    t.index ["resource_id", "resource_type", "mentioned_id", "mentioned_type"], name: "index_mentions_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_mentions_on_resource"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "ai_metadata", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.text "content"
    t.integer "content_type", default: 0, null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "external_id"
    t.string "external_reply_to_id"
    t.uuid "inbox_id", null: false
    t.string "locale"
    t.uuid "outbound_channel_id"
    t.string "outbound_channel_type"
    t.uuid "sender_id", null: false
    t.string "sender_type", null: false
    t.integer "source"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "visibility", default: 1, null: false
    t.index ["account_id", "external_id"], name: "index_messages_on_account_id_and_external_id"
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["ai_metadata"], name: "index_messages_on_ai_metadata", using: :gin
    t.index ["conversation_id", "content_type"], name: "index_messages_on_conversation_id_and_content_type"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id", "status"], name: "index_messages_on_conversation_id_and_status"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["outbound_channel_type", "outbound_channel_id"], name: "index_messages_on_outbound_channel"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "resource_id"
    t.string "resource_type"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id", "created_at"], name: "index_notes_on_account_id_and_created_at"
    t.index ["account_id", "title"], name: "index_notes_on_account_id_and_title"
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notes_on_resource"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "email_flags", default: 0, null: false
    t.integer "push_flags", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_notification_settings_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_notification_settings_on_account_id"
    t.index ["user_id", "created_at"], name: "index_notification_settings_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "notification_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "name"
    t.integer "subscription_type", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notification_subscriptions_on_user_id_and_created_at"
    t.index ["user_id", "subscription_type"], name: "idx_on_user_id_subscription_type_c17965cf4e"
    t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "event", default: 0, null: false
    t.datetime "read_at"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "event"], name: "index_notifications_on_user_id_and_event"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "linked_resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_related_resources_on_resource"
  end

  create_table "skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "name", null: false
    t.integer "skill_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_skills_on_account_id_and_name", unique: true
    t.index ["account_id", "skill_type"], name: "index_skills_on_account_id_and_skill_type"
    t.index ["account_id"], name: "index_skills_on_account_id"
  end

  create_table "sla_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.uuid "sla_policy_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_sla_inboxes_on_account_id"
    t.index ["inbox_id"], name: "index_sla_inboxes_on_inbox_id"
    t.index ["sla_policy_id", "inbox_id"], name: "index_sla_inboxes_on_sla_policy_id_and_inbox_id", unique: true
    t.index ["sla_policy_id"], name: "index_sla_inboxes_on_sla_policy_id"
  end

  create_table "sla_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.boolean "during_working_hours", default: false, null: false
    t.float "initial_response_time_limit"
    t.string "name", null: false
    t.float "resolution_time_limit"
    t.float "response_time_limit"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_sla_policies_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_sla_policies_on_account_id_and_name"
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
    t.index ["business_hour_group_id"], name: "index_sla_policies_on_business_hour_group_id"
  end

  create_table "team_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "role", default: 0, null: false
    t.uuid "team_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_team_users_on_created_at"
    t.index ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_users_on_team_id"
    t.index ["user_id"], name: "index_team_users_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "auto_assign", default: true, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.string "identifier", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_teams_on_account_id_and_created_at"
    t.index ["account_id", "flags"], name: "index_teams_on_account_id_and_flags"
    t.index ["account_id", "identifier"], name: "index_teams_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_teams_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_teams_on_account_id_and_status"
    t.index ["account_id"], name: "index_teams_on_account_id"
  end

  create_table "user_skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "proficiency", default: 1, null: false
    t.uuid "skill_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id"], name: "index_user_skills_on_account_id"
    t.index ["skill_id"], name: "index_user_skills_on_skill_id"
    t.index ["user_id", "skill_id"], name: "idx_user_skill_unique", unique: true
    t.index ["user_id"], name: "index_user_skills_on_user_id"
  end

  create_table "webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "endpoint_url", null: false
    t.string "event_name", null: false
    t.jsonb "request_payload", default: {}
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_webhook_deliveries_on_created_at"
    t.index ["event_name"], name: "index_webhook_deliveries_on_event_name"
    t.index ["resource_type", "resource_id"], name: "index_webhook_deliveries_on_resource"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
  end

  create_table "webhook_delivery_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_number", default: 1, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "error_trace"
    t.integer "http_status"
    t.text "response_body"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "webhook_delivery_id", null: false
    t.index ["created_at"], name: "index_webhook_delivery_attempts_on_created_at"
    t.index ["webhook_delivery_id"], name: "index_webhook_delivery_attempts_on_webhook_delivery_id"
  end

  add_foreign_key "access_account_user_roles", "access_roles", column: "role_id", on_delete: :cascade
  add_foreign_key "ai_agent_translations", "ai_agents", column: "agent_id", on_delete: :cascade
  add_foreign_key "ai_agents", "help_center_portals", column: "portal_id", on_delete: :nullify
  add_foreign_key "assignment_policies", "business_hour_groups", on_delete: :nullify
  add_foreign_key "assignment_policy_inboxes", "assignment_policies", on_delete: :cascade
  add_foreign_key "assignment_policy_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "attachment_translations", "attachments", on_delete: :cascade
  add_foreign_key "business_hour_translations", "business_hours", on_delete: :cascade
  add_foreign_key "business_hours", "business_hour_groups", on_delete: :cascade
  add_foreign_key "canned_response_translations", "canned_responses", on_delete: :cascade
  add_foreign_key "channel_contact_form_translations", "channel_contact_forms", column: "contact_form_id", on_delete: :cascade
  add_foreign_key "channel_web_widget_translations", "channel_web_widgets", column: "web_widget_id"
  add_foreign_key "channel_web_widgets", "channel_contact_forms", column: "pre_chat_form_id", on_delete: :nullify
  add_foreign_key "channel_web_widgets", "help_center_portals", column: "portal_id", on_delete: :nullify
  add_foreign_key "conversation_members", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "sla_policies", on_delete: :cascade
  add_foreign_key "conversations", "inboxes", on_delete: :cascade
  add_foreign_key "csat_survey_responses", "conversations", on_delete: :cascade
  add_foreign_key "csat_survey_responses", "csat_surveys", on_delete: :nullify
  add_foreign_key "csat_survey_responses", "customers", on_delete: :cascade
  add_foreign_key "csat_survey_responses", "messages", on_delete: :nullify
  add_foreign_key "csat_survey_translations", "csat_surveys", column: "survey_id", on_delete: :cascade
  add_foreign_key "csat_surveys", "email_templates", on_delete: :nullify
  add_foreign_key "custom_field_resources", "custom_fields", on_delete: :cascade
  add_foreign_key "custom_field_translations", "custom_fields", on_delete: :cascade
  add_foreign_key "customer_inboxes", "customers", on_delete: :cascade
  add_foreign_key "customer_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "email_template_layout_translations", "email_template_layouts", on_delete: :cascade
  add_foreign_key "email_template_translations", "email_templates", on_delete: :cascade
  add_foreign_key "help_center_article_reactions", "help_center_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "help_center_article_translations", "help_center_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "help_center_articles", "help_center_categories", column: "primary_category_id", on_delete: :nullify
  add_foreign_key "help_center_articles", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_categories", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_category_resources", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "help_center_category_translations", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "help_center_portal_translations", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_portals", "channel_contact_forms", column: "contact_form_channel_id", on_delete: :nullify
  add_foreign_key "help_center_redirects", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "identities", "customers", on_delete: :cascade
  add_foreign_key "identities", "identity_sources", on_delete: :cascade
  add_foreign_key "inbox_teams", "inboxes", on_delete: :cascade
  add_foreign_key "inbox_teams", "teams", on_delete: :cascade
  add_foreign_key "inbox_translations", "inboxes", on_delete: :cascade
  add_foreign_key "inbox_users", "inboxes", on_delete: :cascade
  add_foreign_key "inboxes", "ai_agents", on_delete: :nullify
  add_foreign_key "inboxes", "business_hour_groups", on_delete: :nullify
  add_foreign_key "inboxes", "csat_surveys", on_delete: :nullify
  add_foreign_key "inboxes", "email_templates", column: "conversation_reply_template_id", on_delete: :nullify
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "inboxes", on_delete: :cascade
  add_foreign_key "sla_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "sla_inboxes", "sla_policies", on_delete: :cascade
  add_foreign_key "sla_policies", "business_hour_groups", on_delete: :nullify
  add_foreign_key "team_users", "teams", on_delete: :cascade
  add_foreign_key "user_skills", "skills", on_delete: :cascade
  add_foreign_key "webhook_delivery_attempts", "webhook_deliveries", on_delete: :cascade
end
