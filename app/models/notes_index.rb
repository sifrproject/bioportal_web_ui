class NotesIndex < ActiveRecord::Base

  def populate(note)
    if note
      self.note_id = note.id
      self.ontology_id = note.ontologyId
      self.author = note.author
      self.note_type = note.type
      self.subject = note.subject
      self.body = note.body rescue ""
      self.applies_to = note.appliesTo['id']
      self.applies_to_type = note.appliesTo['type']
      self.created = note.created
    end
  end

end