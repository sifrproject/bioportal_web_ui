module MappingsHelper

  RELATIONSHIP_URIS = {
    "http://www.w3.org/2004/02/skos/core" => "skos:",
    "http://www.w3.org/2000/01/rdf-schema" => "rdfs:",
    "http://www.w3.org/2002/07/owl" => "owl:",
    "http://www.w3.org/1999/02/22-rdf-syntax-ns" => "rdf:"
  }

  def get_short_id(uri)
    split = uri.split("#")
    name = split.length > 1 && RELATIONSHIP_URIS.keys.include?(split[0]) ? RELATIONSHIP_URIS[split[0]] + split[1] : uri
    "<a href='#{uri}' target='_blank'>#{name}</a>"
  end

  # a little method that returns true if the URIs array contain a gold:translation or gold:freeTranslation
  def is_translation(relation_array)
    if relation_array.include? "http://purl.org/linguistics/gold/translation"
      true
    elsif relation_array.include? "http://purl.org/linguistics/gold/freeTranslation"
      true
    else
      false
    end
  end

end
