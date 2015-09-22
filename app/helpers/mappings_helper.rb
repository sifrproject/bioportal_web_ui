module MappingsHelper

  RELATIONSHIP_URIS = {
    "http://www.w3.org/2004/02/skos/core" => "skos:",
    "http://www.w3.org/2000/01/rdf-schema" => "rdfs:",
    "http://www.w3.org/2002/07/owl" => "owl:",
    "http://www.w3.org/1999/02/22-rdf-syntax-ns" => "rdf:"
  }

  INTERPORTAL_HASH = $INTERPORTAL_HASH

  def get_short_id(uri)
    split = uri.split("#")
    name = split.length > 1 && RELATIONSHIP_URIS.keys.include?(split[0]) ? RELATIONSHIP_URIS[split[0]] + split[1] : uri
    "<a href='#{uri}' target='_blank'>#{name}</a>"
  end

  # a little method that returns true if the URIs array contain a gold:translation or gold:freeTranslation
  def is_translation(relation_array)
    if relation_array.kind_of?(Array)
      relation_array.map!(&:downcase)
      if relation_array.include? "http://purl.org/linguistics/gold/translation"
        true
      elsif relation_array.include? "http://purl.org/linguistics/gold/freetranslation"
        true
      else
        false
      end
    else
      LOG.add :error, "Warning: Mapping relation is not an array"
      false
    end
  end

  # method to get (using http) prefLabel for interportal classes
  def getInterportalPrefLabel(class_uri, class_ui_url)
    interportal_key = getInterportalKey(class_ui_url)
    if interportal_key
      json_class = JSON.parse(Net::HTTP.get(URI.parse("#{class_uri}?apikey=#{interportal_key}")))
      if !json_class["prefLabel"].nil?
        return json_class["prefLabel"]
      else
        return nil
      end
    else
      return nil
    end
  end

  # to get the apikey from the interportal instance of the interportal class.
  # The best way to know from which interportal instance the class came is to compare the UI url
  def getInterportalKey(class_ui_url)
    if !INTERPORTAL_HASH.nil?
      INTERPORTAL_HASH.each do |key, value|
        if class_ui_url.start_with?(value["ui"])
          return value["apikey"]
        else
          return nil
        end
      end
    end
  end

  # method to extract the prefLabel from the external class URI
  def getExternalPrefLabel(class_uri)
    if class_uri.include? "#"
      prefLabel = class_uri.split("#")[-1]
    else
      prefLabel = class_uri.split("/")[-1]
    end
    return prefLabel
  end

end
