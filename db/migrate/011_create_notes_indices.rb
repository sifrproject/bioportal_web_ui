class CreateNotesIndices < ActiveRecord::Migration
  def self.up
    create_table "notes_indices" do |t|
      t.string   "note_id",                      :null => false
      t.integer  "ontology_id",                  :null => false
      t.integer  "author",                       :null => false
      t.string   "note_type",                    :null => false
      t.string   "subject",                      :null => false
      t.string   "applies_to",                   :null => false
      t.string   "applies_to_type",              :null => false
      t.text     "body"
      t.integer  "created",         :limit => 8, :null => false
      t.datetime "timestamp"
    end
    add_index "notes_indices", ["note_id"], :name => "note_id", :unique => true
  end

  def self.down
    drop_table "notes_indices"
  end
end
