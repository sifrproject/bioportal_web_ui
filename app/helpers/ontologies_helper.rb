module OntologiesHelper
  
  # Provides a link or string based on the status of an ontology.
  def get_status_text(ontology, params = {})
    # Don't display a link for ontologies that aren't browsable
    # (these are temporarily defined in environment.rb)
    unless $NOT_EXPLORABLE.nil?
      $NOT_EXPLORABLE.each do |virtual_id|
        if ontology.ontologyId.eql?(virtual_id.to_s)
          return ""
        end
      end
    end

    case ontology.statusId.to_i
    when 1 # Ontology is parsing
      return "waiting to parse"
    when 2
      return "parsing"
    when 3 # Ontology is ready to be explored
      return ""
    when 4 # Error in parsing
      return "<span style='color: red;'>parsing error</span>"
    when 6 # Ontology is deprecated
      return "archived"
    end
  end
  
  # Link for private/public/licensed ontologies
  def visibility_link(ontology)
    if ontology.terms_disabled?
      return "<a href='/ontologies/#{ontology.ontologyId}'>Summary Only</a>"
    else
      return "<a href='/ontologies/#{ontology.ontologyId}?p=terms'>Public</a>"
    end
  end

  # Provides a link or string based on the status of an ontology.
  def get_visualize_link(ontology, params = {})
    # Don't display a link for ontologies that aren't browsable
    # (these are temporarily defined in environment.rb)
    unless $NOT_EXPLORABLE.nil?
      $NOT_EXPLORABLE.each do |virtual_id|
        if ontology.ontologyId.eql?(virtual_id.to_s)
          return ""
        end
      end
    end

    case ontology.statusId.to_i
    when 1 # Ontology is parsing
      return "Waiting to Parse"
    when 2
      return "Parsing Ontology"
    when 3 # Ontology is ready to be explored
      return "<a href=\"/visualize/#{ontology.id}\">Explore</a>" if params[:path_only].nil?
      return "/visualize/#{ontology.id}"
    when 4 # Error in parsing
      return "Parsing Error"
    when 6 # Ontology is deprecated
      return "Archived, not available to explore"
    end
  end

  # Provides a link for an ontology based on where it's hosted (Local or remote)
  def get_download_link(ontology)
    # Don't display a link for ontologies that aren't downloadable
    # (these are temporarily defined in environment.rb)
    unless $NOT_DOWNLOADABLE.nil?
      $NOT_DOWNLOADABLE.each do |virtual_id|
        if ontology.ontologyId.eql?(virtual_id.to_s)
          return ""
        end
      end
    end

    if ontology.metadata_only?
      return "<a href=\"#{ontology.homepage}\" target=\"_blank\">Ontology Homepage</a>"
    else
      return "<a href=\"#{DataAccess.download(ontology.id)}\" target=\"_blank\">Ontology</a>"
    end
  end

  def get_view_ontology_version(view_on_ontology_id)
    return DataAccess.getOntology(view_on_ontology_id).versionNumber
  end

  # Generates a properly-formatted link for diffs
  def get_diffs_link(diffs, versions, current_version, index)
    for diff in diffs
      if diff[1].to_i.eql?(current_version.id.to_i) && diff[0].to_i.eql?(versions[index + 1].id.to_i)
        return "<a href='#{$REST_URL}/diffs/download/#{diff[0]}/#{diff[1]}?format=txt'>Diff</a>"
      end
    end
    
    return ""
  end
  
  # Generates an array for use with version drop-down lists
  def get_versions_array_for_select(ontology_version_id)
    ontology = DataAccess.getOntology(ontology_version_id)
    ont_versions = DataAccess.getOntologyVersions(ontology.ontologyId).sort! {|ont_a,ont_b| ont_b.internalVersion.to_i <=> ont_a.internalVersion.to_i}
    ont_versions_array = []
    ont_versions.each {|ont| ont_versions_array << [ ont.versionNumber, ont.id ] }
    return ont_versions_array
  end
  
  def get_ont_icons(ontology)
    mappings_count = DataAccess.getMappingCountOntologiesHash
    mappings_count = mappings_count[ontology.ontologyId].to_i
    notes_count = DataAccess.getNotesCounts
    notes_count = notes_count[ontology.ontologyId].to_i
    
    formatting_options = { :thousand => "K", :million => "M", :billion => "B" }
    
    mappings_count_formatted = (mappings_count.nil? || mappings_count == 0) ? "" : number_to_human(mappings_count, :precision => 0, :units => formatting_options).gsub(" ", "")
    notes_count_formatted = (notes_count.nil? || notes_count == 0) ? "" : number_to_human(notes_count, :units => formatting_options).gsub(" ", "")
    
    links = ""
    links << "<a class='ont_icons' href=''>T</a>"
    links << "<a class='ont_icons' href=''>M<span class='ont_counts'>#{mappings_count_formatted}</span></a>"
    links << "<a class='ont_icons' href=''>N<span class='ont_counts'>#{notes_count_formatted}</span></a>"
  end
  
  def terms_link(ontology, count)
    loc = ontology.terms_disabled? ? "summary" : "terms"
    
    if count.nil? || count == 0
      return "0"
    else
      return "<a href='/ontologies/#{ontology.ontologyId}/?p=#{loc}'>#{number_with_delimiter(count, :delimiter => ',')}</a>"
    end
  end
  
  def mappings_link(ontology, count)
    loc = "mappings"
    
    if count.nil? || count == 0
      return "0"
    else
      return "<a href='/ontologies/#{ontology.ontologyId}/?p=#{loc}'>#{number_with_delimiter(count, :delimiter => ',')}</a>"
    end
  end

  def notes_link(ontology, count)
    loc = "notes"
    
    if count.nil? || count == 0
      return "0"
    else
      return "<a href='/ontologies/#{ontology.ontologyId}/?p=#{loc}'>#{number_with_delimiter(count, :delimiter => ',')}</a>"
    end
  end

end