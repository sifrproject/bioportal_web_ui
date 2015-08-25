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

ActiveRecord::Schema.define(version: 20150806211835) do

  create_table "analytics", force: :cascade do |t|
    t.string   "segment",    limit: 255
    t.string   "action",     limit: 255
    t.string   "bp_slice",   limit: 255
    t.string   "ip",         limit: 255
    t.integer  "user",       limit: 4
    t.text     "params",     limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeouts", force: :cascade do |t|
    t.string   "path",        limit: 255
    t.integer  "ontology_id", limit: 4
    t.text     "concept_id",  limit: 65535
    t.text     "params",      limit: 65535
    t.datetime "created"
  end

  create_table "virtual_appliance_users", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
