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

ActiveRecord::Schema.define(version: 20130916221353) do

  create_table "gathers", force: true do |t|
    t.string   "activity"
    t.string   "invited"
    t.string   "location"
    t.string   "date"
    t.string   "time"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "details"
    t.integer  "tilt"
    t.integer  "num_invited"
    t.integer  "num_joining", default: 1
    t.string   "invited_yes"
    t.string   "invited_no"
  end

  add_index "gathers", ["user_id", "created_at"], name: "index_gathers_on_user_id_and_created_at"

  create_table "invitations", force: true do |t|
    t.integer  "gathering_id"
    t.integer  "invitee_id"
    t.string   "status",       default: "NA"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "number_used"
  end

  add_index "invitations", ["gathering_id", "invitee_id"], name: "index_invitations_on_gathering_id_and_invitee_id", unique: true
  add_index "invitations", ["gathering_id"], name: "index_invitations_on_gathering_id"
  add_index "invitations", ["invitee_id"], name: "index_invitations_on_invitee_id"

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
