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

ActiveRecord::Schema[7.0].define(version: 2024_09_30_082839) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "belts", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.string "name_domain"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "validated_date", default: "2022-04-27"
    t.integer "level", null: false
    t.bigint "domain_id"
    t.index ["domain_id"], name: "index_belts_on_domain_id"
    t.index ["student_id"], name: "index_belts_on_student_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.string "name"
    t.bigint "skill_id", null: false
    t.boolean "shared", default: true
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "for_belt", default: false
    t.index ["skill_id"], name: "index_challenges_on_skill_id"
    t.index ["user_id"], name: "index_challenges_on_user_id"
  end

  create_table "classrooms", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "shared"
    t.bigint "grade_id"
    t.index ["grade_id"], name: "index_classrooms_on_grade_id"
    t.index ["user_id"], name: "index_classrooms_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.string "name"
    t.string "conversation_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "domains", force: :cascade do |t|
    t.string "name"
    t.bigint "grade_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "special"
    t.integer "position"
    t.index ["grade_id"], name: "index_domains_on_grade_id"
  end

  create_table "grades", force: :cascade do |t|
    t.string "grade_level"
    t.string "name"
    t.bigint "school_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_grades_on_school_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "conversation_id"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "read_marks", force: :cascade do |t|
    t.string "readable_type", null: false
    t.bigint "readable_id"
    t.string "reader_type", null: false
    t.bigint "reader_id"
    t.datetime "timestamp", precision: nil, null: false
    t.index ["readable_type", "readable_id"], name: "index_read_marks_on_readable_type_and_readable_id"
    t.index ["reader_id", "reader_type", "readable_type", "readable_id"], name: "read_marks_reader_readable_index", unique: true
    t.index ["reader_type", "reader_id"], name: "index_read_marks_on_reader_type_and_reader_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "skill_id"
    t.string "kind"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_results_on_skill_id"
    t.index ["student_id"], name: "index_results_on_student_id"
  end

  create_table "school_roles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "school_id"
    t.boolean "super_teacher", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_school_roles_on_school_id"
    t.index ["user_id"], name: "index_school_roles_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.string "email"
    t.boolean "special_domains", default: false
    t.string "code"
  end

  create_table "shared_classrooms", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "classroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_shared_classrooms_on_classroom_id"
    t.index ["user_id"], name: "index_shared_classrooms_on_user_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name_domain"
    t.integer "level"
    t.string "name"
    t.string "symbol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sub_domain"
    t.bigint "school_id"
    t.bigint "domain_id"
    t.integer "position"
    t.index ["domain_id"], name: "index_skills_on_domain_id"
    t.index ["school_id"], name: "index_skills_on_school_id"
  end

  create_table "students", force: :cascade do |t|
    t.string "first_name"
    t.bigint "classroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_students_on_classroom_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "stripe_subscription_id", default: "", null: false
    t.string "status", default: "incomplete", null: false
    t.boolean "cancel_at_period_end", default: false, null: false
    t.date "current_period_start", null: false
    t.date "current_period_end", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "school_id"
    t.integer "quantity"
    t.string "plan_id"
    t.date "start_date"
    t.date "trial_end"
    t.string "rythm", default: "annuel"
    t.index ["school_id"], name: "index_subscriptions_on_school_id"
  end

  create_table "tables", force: :cascade do |t|
    t.integer "columns", default: 1
    t.integer "rows", default: 1
    t.json "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_conversations", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "conversation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_user_conversations_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_user_conversations_on_user_id_and_conversation_id", unique: true
    t.index ["user_id"], name: "index_user_conversations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin"
    t.text "stripe_customer_id"
    t.boolean "demo", default: false
    t.string "discovery_method"
    t.datetime "last_seen"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_plan_domains", force: :cascade do |t|
    t.string "name_domain"
    t.integer "level"
    t.bigint "work_plan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false
    t.bigint "domain_id"
    t.index ["domain_id"], name: "index_work_plan_domains_on_domain_id"
    t.index ["work_plan_id"], name: "index_work_plan_domains_on_work_plan_id"
  end

  create_table "work_plan_skills", force: :cascade do |t|
    t.bigint "work_plan_domain_id", null: false
    t.bigint "skill_id", null: false
    t.string "kind"
    t.bigint "challenge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false
    t.string "status", default: "new"
    t.integer "position"
    t.index ["challenge_id"], name: "index_work_plan_skills_on_challenge_id"
    t.index ["skill_id"], name: "index_work_plan_skills_on_skill_id"
    t.index ["work_plan_domain_id"], name: "index_work_plan_skills_on_work_plan_domain_id"
  end

  create_table "work_plans", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.bigint "student_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.date "end_date"
    t.bigint "shared_user_id"
    t.boolean "special_wps", default: false
    t.bigint "grade_id"
    t.index ["grade_id"], name: "index_work_plans_on_grade_id"
    t.index ["shared_user_id"], name: "index_work_plans_on_shared_user_id"
    t.index ["student_id"], name: "index_work_plans_on_student_id"
    t.index ["user_id"], name: "index_work_plans_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "belts", "domains"
  add_foreign_key "belts", "students"
  add_foreign_key "challenges", "skills"
  add_foreign_key "challenges", "users"
  add_foreign_key "classrooms", "grades"
  add_foreign_key "classrooms", "users"
  add_foreign_key "domains", "grades"
  add_foreign_key "grades", "schools"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "results", "skills"
  add_foreign_key "results", "students"
  add_foreign_key "school_roles", "schools"
  add_foreign_key "school_roles", "users"
  add_foreign_key "shared_classrooms", "classrooms"
  add_foreign_key "shared_classrooms", "users"
  add_foreign_key "skills", "domains"
  add_foreign_key "skills", "schools"
  add_foreign_key "students", "classrooms"
  add_foreign_key "subscriptions", "schools"
  add_foreign_key "user_conversations", "conversations"
  add_foreign_key "user_conversations", "users"
  add_foreign_key "work_plan_domains", "domains"
  add_foreign_key "work_plan_domains", "work_plans"
  add_foreign_key "work_plan_skills", "challenges"
  add_foreign_key "work_plan_skills", "skills"
  add_foreign_key "work_plan_skills", "work_plan_domains"
  add_foreign_key "work_plans", "grades"
  add_foreign_key "work_plans", "students"
  add_foreign_key "work_plans", "users"
  add_foreign_key "work_plans", "users", column: "shared_user_id"
end
