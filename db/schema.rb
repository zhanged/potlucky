# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131121190007) do

  create_table "friendships", force: true do |t|
    t.integer  "friender_id"
    t.integer  "friended_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["friended_id"], name: "index_friendships_on_friended_id"
  add_index "friendships", ["friender_id", "friended_id"], name: "index_friendships_on_friender_id_and_friended_id", unique: true
  add_index "friendships", ["friender_id"], name: "index_friendships_on_friender_id"

  create_table "gathers", force: true do |t|
    t.string   "activity"
    t.text     "invited"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
    t.integer  "tilt"
    t.integer  "num_invited"
    t.integer  "num_joining",  default: 1
    t.text     "invited_yes"
    t.text     "invited_no"
    t.string   "expire"
    t.datetime "completed"
    t.time     "time"
    t.date     "date"
    t.text     "location"
    t.text     "more_details"
    t.string   "activity_2"
    t.string   "activity_3"
    t.text     "location_2"
    t.text     "location_3"
    t.date     "date_2"
    t.date     "date_3"
    t.time     "time_2"
    t.time     "time_3"
    t.integer  "wait_hours"
    t.time     "wait_time"
    t.text     "gen_link"
  end

  add_index "gathers", ["user_id", "created_at"], name: "index_gathers_on_user_id_and_created_at"

  create_table "invitations", force: true do |t|
    t.integer  "gathering_id"
    t.integer  "invitee_id"
    t.string   "status",       default: "NA"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "number_used"
    t.integer  "activity_1v"
    t.integer  "activity_2v"
    t.integer  "activity_3v"
    t.integer  "time_1v"
    t.integer  "time_2v"
    t.integer  "time_3v"
    t.integer  "date_1v"
    t.integer  "date_2v"
    t.integer  "date_3v"
    t.integer  "location_1v"
    t.integer  "location_2v"
    t.integer  "location_3v"
  end

  add_index "invitations", ["gathering_id", "invitee_id"], name: "index_invitations_on_gathering_id_and_invitee_id", unique: true
  add_index "invitations", ["gathering_id"], name: "index_invitations_on_gathering_id"
  add_index "invitations", ["invitee_id"], name: "index_invitations_on_invitee_id"

  create_table "invite_mores", force: true do |t|
    t.text     "more_invitees"
    t.integer  "user_id"
    t.integer  "gather_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invite_mores", ["gather_id", "created_at"], name: "index_invite_mores_on_gather_id_and_created_at"

  create_table "links", force: true do |t|
    t.string   "in_url"
    t.text     "out_url"
    t.integer  "http_status",   default: 301
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "seen"
    t.integer  "gathering_id"
    t.integer  "invitation_id"
  end

  add_index "links", ["gathering_id", "invitation_id"], name: "index_links_on_gathering_id_and_invitation_id"
  add_index "links", ["in_url"], name: "index_links_on_in_url"

  create_table "tnumbers", force: true do |t|
    t.string   "tphone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "updates", force: true do |t|
    t.text     "content"
    t.integer  "user_id"
    t.integer  "gather_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "updates", ["gather_id", "created_at"], name: "index_updates_on_gather_id_and_created_at"

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           default: false
    t.string   "auth_token"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["remember_token"], name: "index_users_on_remember_token"

  create_table "wait_lists", force: true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
