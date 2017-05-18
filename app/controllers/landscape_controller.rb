require 'action_view'
include ActionView::Helpers::NumberHelper

class LandscapeController < ApplicationController
  layout 'ontology'

  def index
    #@ontologies = LinkedData::Client::Models::Ontology.all(include_views: false)
    #@submissions = LinkedData::Client::Models::OntologySubmission.all(values: params[:submission])

    # Array with color codes for the pie charts. iterate color_index to change color
    pie_colors_array = ["#2484c1", "#0c6197", "#4daa4b", "#90c469", "#daca61", "#e4a14b", "#e98125", "#cb2121", "#830909", "#923e99", "#ae83d5", "#bf273e", "#ce2aeb", "#bca44a", "#618d1b", "#1ee67b", "#b0ec44", "#a4a0c9", "#322849", "#86f71a", "#d1c87f", "#7d9058", "#44b9b0", "#7c37c0", "#cc9fb1", "#e65414", "#8b6834", "#248838"];

    groups_count_hash = {}
    domains_count_hash = {}
    # A hash for counting ontologies in size ranges
    size_slices_hash = {}
    size_slices_hash["< 100"] = 0
    size_slices_hash["< #{number_with_delimiter(1000, delimiter: " ")}"] = 0
    size_slices_hash["< #{number_with_delimiter(10000, delimiter: " ")}"] = 0
    size_slices_hash["< #{number_with_delimiter(100000, delimiter: " ")}"] = 0
    size_slices_hash["100k+"] = 0

    natural_language_hash = {}
    licenseProperty_hash = {}
    formalityProperty_hash = {}
    dataCatalog_count_hash = {}
    isOfTypeProperty_hash = {}

    prefLabelProperty_hash = {}
    synonymProperty_hash = {}
    definitionProperty_hash = {}
    authorProperty_hash = {}

    people_count_hash = {}
    people_count_emails = {}

    org_count_hash = {}

    ontology_relations_array = []

    ontologyFormatsCount = {"OWL" => 0, "SKOS" => 0, "UMLS" => 0, "OBO" => 0}

    data_catalog_values = {"https://biosharing.org/" => "BioSharing",
                           "http://aber-owl.net/ontology/" => "AberOWL",
                           "http://vest.agrisemantics.org/content/" => "VEST Registry",
                           "http://bioportal.bioontology.org/ontologies/" => "BioPortal",
                           "http://www.ontobee.org/ontology/" => "Ontobee",
                           "http://www.obofoundry.org/ontology/" => "The OBO Foundry",
                           "http://www.ebi.ac.uk/ols/ontologies/" => "EBI Ontology Lookup"}

    # Set all data_catalog count to 0
    data_catalog_values.map {|uri,name| dataCatalog_count_hash[name] = 0}

    @metrics_average = [{:attr => "numberOfClasses", :label => "Number of classes", :array => []},
                        {:attr => "numberOfIndividuals", :label => "Number of individuals", :array => []},
                        {:attr => "numberOfProperties", :label => "Number of properties", :array => []},
                        {:attr => "maxDepth", :label => "Max depth", :array => []},
                        {:attr => "maxChildCount", :label => "Max child count", :array => []},
                        {:attr => "averageChildCount", :label => "Average child count", :array => []},
                        {:attr => "classesWithOneChild", :label => "Classes with one child", :array => []},
                        {:attr => "classesWithMoreThan25Children", :label => "Classes with more than 25 children", :array => []},
                        {:attr => "classesWithNoDefinition", :label => "Classes with no definition	", :array => []},
                        {:attr => "numberOfAxioms", :label => "Number of axioms (triples)", :array => []}]

    # Attributes to include. To avoid to get everything and make it faster
    # They are also used to get the value of each property later in the controller
    # TODO: define here the attributes you want to retrieve to create visualization

    # Attributes that we need to retrieve to perform landscape
    sub_attributes = [:submissionId, :ontology, :group, :hasDomain, :hasOntologyLanguage, :naturalLanguage, :hasLicense, :hasFormalityLevel, :isOfType, :contact, :name, :email, :includedInDataCatalog]
    # TODO: if too slow do a different call for includedInDataCatalog (array with a lot of different value, so it trigger the SPARQL default when we retrieve multiple attr with multiple values in the array)

    pref_properties_attributes = [:prefLabelProperty, :synonymProperty, :definitionProperty, :authorProperty]

    contributors_attr_list = [:hasContributor, :hasCreator, :curatedBy]
    org_attr_list = [:fundedBy, :endorsedBy]

    @relations_array = ["omv:useImports", "door:isAlignedTo", "door:ontologyRelatedTo", "omv:isBackwardCompatibleWith", "omv:isIncompatibleWith", "door:comesFromTheSameDomain", "door:similarTo",
                        "door:explanationEvolution", "voaf:generalizes", "door:hasDisparateModelling", "dct:hasPart", "voaf:usedBy", "schema:workTranslation", "schema:translationOfWork"]
    # We need prefixes to display them, we remove them to call them in the include
    relations_attributes = @relations_array.map {|r| r.to_s.split(":")[1]}
    metrics_attributes = @metrics_average.map {|m| m[:attr]}

    # Concat all attributes array and generate a string separated with comma for include param
    all_attributes = sub_attributes.concat(contributors_attr_list).concat(org_attr_list)
                         .concat(relations_attributes).concat(metrics_attributes).concat(pref_properties_attributes).join(",")


    @submissions = LinkedData::Client::Models::OntologySubmission.all(include_status: "any", include_views: true, display_links: false, display_context: false, include: all_attributes)

    # Iterate ontologies to get the submissions with all metadata
    @submissions.each do |sub|
      ont = sub.ontology

      if !sub.nil?

        # Get hash of natural language use
        if !sub.naturalLanguage.nil? && !sub.naturalLanguage.empty?
          sub.naturalLanguage.each do |sub_lang|
            # replace lexvo URI by lexvo prefix
            prefixed_sub_lang = sub_lang
            if sub_lang.start_with?("http://lexvo.org/id/iso639-3/")
              prefixed_sub_lang = sub_lang.sub("http://lexvo.org/id/iso639-3/", "lexvo:")
            end
            # If lang already in hash then we increment the count of the lang in the hash
            if natural_language_hash.has_key?(prefixed_sub_lang.to_s)
              natural_language_hash[prefixed_sub_lang.to_s]["count"] = natural_language_hash[prefixed_sub_lang.to_s]["count"] + 1
            else
              natural_language_hash[prefixed_sub_lang.to_s] = {}
              natural_language_hash[prefixed_sub_lang.to_s]["count"] = 1
              natural_language_hash[prefixed_sub_lang.to_s]["uri"] = sub_lang
            end
          end
        end

        licenseProperty_hash = get_used_properties(sub.hasLicense, nil, licenseProperty_hash)

        formalityProperty_hash = get_used_properties(sub.hasFormalityLevel, nil, formalityProperty_hash)

        sub.includedInDataCatalog.each do |data_catalog|
          data_catalog_values.each do |uri, name|
            if data_catalog.start_with?(uri)
              dataCatalog_count_hash[name] += 1
            end
          end
        end

        isOfTypeProperty_hash = get_used_properties(sub.isOfType, nil, isOfTypeProperty_hash)

        # Get the prefLabelProperty used for OWL properties in a hash
        if sub.hasOntologyLanguage.eql?("OWL")
          prefLabelProperty_hash = get_used_properties(sub.prefLabelProperty, "http://www.w3.org/2004/02/skos/core#prefLabel", prefLabelProperty_hash)

          synonymProperty_hash = get_used_properties(sub.synonymProperty, "http://www.w3.org/2004/02/skos/core#altLabel", synonymProperty_hash)

          definitionProperty_hash = get_used_properties(sub.definitionProperty, "http://www.w3.org/2004/02/skos/core#definition", definitionProperty_hash)

          authorProperty_hash = get_used_properties(sub.authorProperty, "http://purl.org/dc/elements/1.1/creator", authorProperty_hash)
        end

        get_metrics_for_average(sub)

        # Count the number of classes (individuals for skos by ontologies) to get number of ontologies by slice of size
        if sub.hasOntologyLanguage.eql?("SKOS")
          ontology_size = sub.numberOfIndividuals
        else
          ontology_size = sub.numberOfClasses
        end
        if (!ontology_size.nil?)
          if (ontology_size >= 100000)
            size_slices_hash["100k+"] += 1
          else
            [100, 1000, 10000, 100000].each do |slice_size|
              if (ontology_size < slice_size)
                size_slices_hash["< #{number_with_delimiter(slice_size, delimiter: " ")}"] += 1
                break;
              end
            end
          end
        end

        # Get number of ontologies for each format (for horizontal bar chart)
        ontologyFormatsCount[sub.hasOntologyLanguage] += 1

        # Count number of ontologies for each group (bar chart)
        ont.group.each do |group|
          group_acro = group.to_s.split("/")[-1]
          if groups_count_hash.has_key?(group_acro)
            groups_count_hash[group_acro] += 1
          else
            groups_count_hash[group_acro] = 1
          end
        end

        # Count number of ontologies for each domain (bar chart)
        ont.hasDomain.each do |domain|
          domain_acro = domain.to_s.split("/")[-1]
          if domains_count_hash.has_key?(domain_acro)
            domains_count_hash[domain_acro] += 1
          else
            domains_count_hash[domain_acro] = 1
          end
        end

        # Get people that are mentioned as ontology actors (contact, contributors, creators, curator) to create a tag cloud
        # hasContributor hasCreator contact(explore,name) curatedBy
        contributors_attr_list.each do |contributor|
          contributor_label = sub.send(contributor.to_s).to_s
          if !contributor_label.nil?
            contributors_split = contributor_label.split(",")
            contributors_split.each do |contrib|
              if people_count_hash.has_key?(contrib)
                people_count_hash[contrib] += 1
              else
                people_count_hash[contrib] = 1
              end
            end
          end
        end
        sub.contact.each do |contact|
          contributor_label = contact.name
          if !contributor_label.nil?
            if people_count_hash.has_key?(contributor_label)
              people_count_hash[contributor_label] += 1
            else
              people_count_hash[contributor_label] = 1
            end
            people_count_emails[contributor_label] = contact.email if !contact.email.nil?
          end
        end

        org_attr_list.each do |attr|
          contributors_list = sub.send(attr.to_s)
          if !contributors_list.kind_of?(Array)
            contributors_list = [contributors_list]
          end

          contributors_list.each do |contributor_label|
            if !contributor_label.nil? &&
              contributors_split = contributor_label.split(",")
              contributors_split.each do |contrib|
                if org_count_hash.has_key?(contrib)
                  org_count_hash[contrib] += 1
                else
                  org_count_hash[contrib] = 1
                end
              end
            end
          end
        end

        # Get ontology relations between each other (ex: STY isAlignedTo GO)
        @relations_array.each do |relation_attr|
          relation_values = sub.send(relation_attr.to_s.split(":")[1])
          if !relation_values.nil? && !relation_values.empty?
            if !relation_values.kind_of?(Array)
              relation_values = [relation_values]
            end
            relation_values.each do |rel_value|
              # Use acronym if ontology in the portal
              target_ont = LinkedData::Client::Models::Ontology.find(rel_value)
              if target_ont
                rel_value = target_ont.acronym
              end
              ontology_relations_array.push({:source => ont.acronym, :target=> rel_value, :relation=> relation_attr.to_s})
            end
          end
        end
      end
    end

    # Add value of metrics to the @metrics_average hash
    @metrics_average.each do |metrics|
      metrics[:average] = (metrics[:array].sum / metrics[:array].size.to_f).round(2)
    end


    notes_people_count_hash = {}
    notes_ontologies_count_hash = {}

    # Retrieve user and ontologies from Reviews, Projects and Notes
    reviews = LinkedData::Client::Models::Review.all
    reviews.each do |review|
      notes_people_count_hash = notes_create_hash_entry(review.creator, :reviews, notes_people_count_hash)
      notes_ontologies_count_hash = notes_create_hash_entry(review.ontologyReviewed, :reviews, notes_ontologies_count_hash)
    end

    projects = LinkedData::Client::Models::Project.all
    projects.each do |project|
      project.creator.each do |creator|
        notes_people_count_hash = notes_create_hash_entry(creator, :projects, notes_people_count_hash)
      end
      project.ontologyUsed.each do |onto_used|
        notes_ontologies_count_hash = notes_create_hash_entry(onto_used, :projects, notes_ontologies_count_hash)
      end
    end

    notes = LinkedData::Client::Models::Note.all
    notes.each do |note|
      notes_people_count_hash = notes_create_hash_entry(note.creator, :notes, notes_people_count_hash)
      note.relatedOntology.each do |related_onto|
        notes_ontologies_count_hash = notes_create_hash_entry(related_onto, :notes, notes_ontologies_count_hash)
      end
    end

    # Build the array of hashes used to create the Tag cloud
    notes_ontologies_json_cloud = []
    notes_people_json_cloud = []

    notes_people_count_hash.each do |people,hash_counts|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      title_array = []
      total_count = 0
      if hash_counts.has_key?(:projects)
        title_array.push("#{hash_counts[:projects]} projects")
        total_count += hash_counts[:projects]
      end
      if hash_counts.has_key?(:notes)
        title_array.push("#{hash_counts[:notes]} notes")
        total_count += hash_counts[:notes]
      end
      if hash_counts.has_key?(:reviews)
        title_array.push("#{hash_counts[:reviews]} reviews")
        total_count += hash_counts[:reviews]
      end
      if total_count > 0
        notes_people_json_cloud.push({"text"=>people.to_s,"weight"=>total_count, "html" => {style: "color: ##{colour};", title: title_array.join(", ")}, "link" => hash_counts[:uri]})
      end
    end

    notes_ontologies_count_hash.each do |onto,hash_counts|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      title_array = []
      total_count = 0
      if hash_counts.has_key?(:projects)
        title_array.push("#{hash_counts[:projects]} projects")
        total_count += hash_counts[:projects]
      end
      if hash_counts.has_key?(:notes)
        title_array.push("#{hash_counts[:notes]} notes")
        total_count += hash_counts[:notes]
      end
      if hash_counts.has_key?(:reviews)
        title_array.push("#{hash_counts[:reviews]} reviews")
        total_count += hash_counts[:reviews]
      end
      if total_count > 0
        notes_ontologies_json_cloud.push({"text"=>onto.to_s,"weight"=>total_count, "html" => {style: "color: ##{colour};", title: title_array.join(", ")}, "link" => hash_counts[:uri]})
      end
    end



    # Get the different people and organizations to generate a tag cloud
    people_count_json_cloud = []
    org_count_json_cloud = []

    # Generate the JSON to put natural languages in the pie chart
    natural_language_json_pie = []
    licenseProperty_json_pie = []

    prefLabelProperty_json_pie = []
    synonymProperty_json_pie = []
    definitionProperty_json_pie = []
    authorProperty_json_pie = []

    people_count_hash.each do |people,no|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      if people_count_emails[people.to_s].nil?
        people_count_json_cloud.push({"text"=>people.to_s,"weight"=>no, "html" => {style: "color: ##{colour};", title: "#{no.to_s} mentions as a contributor."}})
      else
        people_count_json_cloud.push({"text"=>people.to_s,"weight"=>no, "html" => {style: "color: ##{colour};", title: "#{no.to_s} mentions as a contributor."}, "link" => "mailto:#{people_count_emails[people.to_s]}"})
      end
    end

    org_count_hash.each do |org,no|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      org_count_json_cloud.push({"text"=>org.to_s,"weight"=>no, "html" => {style: "color: ##{colour};", title: "#{no.to_s} ontologies endorsed or funded."}})
    end

    # Push the results in hash formatted for the Javascript lib that will be displaying it
    color_index = 0
    natural_language_hash.each do |lang,count_hash|
      natural_language_json_pie.push({"label"=>lang.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 1
    end

    color_index = 0
    licenseProperty_hash.each do |license,count_hash|
      licenseProperty_json_pie.push({"label"=>license.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 1
    end

    formalityLevelCount = {}
    formalityProperty_hash.each do |formality_level,count_hash|
      # Generate formalityLevel JSON used to get the bar charts
      formalityLevelCount[formality_level.to_s] = count_hash["count"]
    end

    isOfTypeCount = {}
    isOfTypeProperty_hash.each do |isOfType,count_hash|
      isOfTypeCount[isOfType.to_s] = count_hash["count"]
    end

    color_index = 0
    prefLabelProperty_hash.each do |pref_label,count_hash|
      prefLabelProperty_json_pie.push({"label"=>pref_label.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 2
    end
    color_index = 1
    synonymProperty_hash.each do |synonym,count_hash|
      synonymProperty_json_pie.push({"label"=>synonym.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 2
    end
    color_index = 0
    definitionProperty_hash.each do |definition,count_hash|
      definitionProperty_json_pie.push({"label"=>definition.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 2
    end
    color_index = 1
    authorProperty_hash.each do |author,count_hash|
      authorProperty_json_pie.push({"label"=>author.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 2
    end

    # Format the ontologyFormatsCount hash as the JSON needed to generate the chart
    ontologyFormatsChartJson = { :labels => ontologyFormatsCount.keys,
                                 :datasets => [{ :label => "Number of ontologies using this format",
                                                 :data => ontologyFormatsCount.values,
                                                 :backgroundColor => ["#669911", "#119966", "#66A2EB", "#FCCE56"]}] }

    isOfTypeChartJson = { :labels => isOfTypeCount.keys,
                          :datasets => [{ :label => "Number of ontologies of this ontology type",
                                          :data => isOfTypeCount.values,
                                          :backgroundColor => pie_colors_array}] }

    formalityLevelChartJson = { :labels => formalityLevelCount.keys,
                                :datasets => [{ :label => "Number of ontologies of this formality level",
                                                :data => formalityLevelCount.values,
                                                :backgroundColor => pie_colors_array}] }

    dataCatalogChartJson = { :labels => dataCatalog_count_hash.keys,
                             :datasets => [{ :label => "Number of ontologies in this catalog", :data => dataCatalog_count_hash.values,
                                                :backgroundColor => pie_colors_array}] }

    # Format the groupOntologiesCount hash as the JSON needed to generate the chart
    groupCountChartJson = { :labels => groups_count_hash.keys,
                            :datasets => [{ :label => "Number of ontologies", :data => groups_count_hash.values,
                                                  :backgroundColor => pie_colors_array}] }

    domainCountChartJson = { :labels => domains_count_hash.keys,
                             :datasets => [{ :label => "Number of ontologies", :data => domains_count_hash.values,
                                             :backgroundColor => pie_colors_array}] }

    # Format the groupOntologiesCount hash as the JSON needed to generate the chart
    sizeSlicesChartJson = { :labels => size_slices_hash.keys,
                            :datasets => [{ :label => "Number of ontologies with a class count in this range",
                                            :data => size_slices_hash.values,
                                            :backgroundColor => pie_colors_array}] }

    # Also pass groups and hasDomain name to resolve it and better label of bar charts
    groups = LinkedData::Client::Models::Group.all(include: "acronym,name,description")
    domains = LinkedData::Client::Models::Category.all(include: "acronym,name,description")

    groups_info_hash = {}
    groups.each do |group|
      groups_info_hash[group.acronym] = {}
      groups_info_hash[group.acronym][:id] = group.id
      groups_info_hash[group.acronym][:name] = group.name
      groups_info_hash[group.acronym][:description] = []
      # Slice the description in 6 words string to avoid too long sentence in the bar chart tooltip in js
      group.description.split(" ").each_slice(6) {|slice| groups_info_hash[group.acronym][:description].push(slice.join(" ")) }
    end

    domains_info_hash = {}
    domains.each do |domain|
      domains_info_hash[domain.acronym] = {}
      domains_info_hash[domain.acronym][:id] = domain.id
      domains_info_hash[domain.acronym][:name] = domain.name
      domains_info_hash[domain.acronym][:description] = []
      # Slice the description in 6 words string to avoid too long sentence in the bar chart tooltip in js
      domain.description.split(" ").each_slice(6) {|slice| domains_info_hash[domain.acronym][:description].push(slice.join(" ")) }
    end

    @landscape_data = {
        :people_count_json_cloud => people_count_json_cloud,
        :org_count_json_cloud => org_count_json_cloud,
        :notes_ontologies_json_cloud => notes_ontologies_json_cloud,
        :notes_people_json_cloud => notes_people_json_cloud,
        :natural_language_json_pie => natural_language_json_pie,
        :licenseProperty_json_pie => licenseProperty_json_pie,
        :ontology_relations_array => ontology_relations_array,
        :prefLabelProperty_json_pie => prefLabelProperty_json_pie,
        :synonymProperty_json_pie => synonymProperty_json_pie,
        :definitionProperty_json_pie => definitionProperty_json_pie,
        :authorProperty_json_pie => authorProperty_json_pie,
        :ontologyFormatsChartJson => ontologyFormatsChartJson,
        :isOfTypeChartJson => isOfTypeChartJson,
        :formalityLevelChartJson => formalityLevelChartJson,
        :dataCatalogChartJson => dataCatalogChartJson,
        :groupCountChartJson => groupCountChartJson,
        :groupsInfoHash => groups_info_hash,
        :domainCountChartJson => domainCountChartJson,
        :domainsInfoHash => domains_info_hash,
        :sizeSlicesChartJson => sizeSlicesChartJson
    }.to_json.html_safe

  end

  # For notes takes the hash and create the entry if not already existing
  # To create hash like this: {"user1": {"reviews": 3, "notes": 4, "projects": 4}}
  def notes_create_hash_entry(uri_id, notes_type, hash)
    id = uri_id.split('/').last
    if !hash.has_key?(id)
      hash[id] = {:uri => uri_id}
    end
    if !hash[id].has_key?(notes_type)
      hash[id][notes_type] = 1
    else
      hash[id][notes_type] += 1
    end
    return hash
  end


  ##
  # Add metrics metadata from the param sub to the @metrics_average var to get the average for each metrics
  def get_metrics_for_average(sub)
    # Adding metrics to their arrays

    @metrics_average.each do |metrics|
      if !sub.send(metrics[:attr]).nil?
        metrics[:array].push(sub.send(metrics[:attr]))
      end
    end
  end

  ##
  # Increment the hash entry for the property used by the submission for the given attribute
  # If null it increments the value for the default_property (for prefLabel prop or synonym prop for example)
  def get_used_properties(attr_value, default_property, property_hash)
    if attr_value.nil? || attr_value.empty?
      # if property null then we increment the default value
      if default_property.nil?
        return property_hash
      end
      attr_value = default_property
    else
      attr_value = attr_value.to_s
    end

    # Replace namespace by prefix (defined in application_controller.rb)
    prefixed_attr_value = attr_value
    RESOLVE_NAMESPACE.each do |prefix, namespace|
      if attr_value.start_with?(namespace)
        prefixed_attr_value = attr_value.sub(namespace, "#{prefix}:")
        break;
      end
    end

    # If attribute value property already in hash then we increment the count of the property in the hash
    if property_hash.has_key?(prefixed_attr_value)
      property_hash[prefixed_attr_value]["count"] += 1
    else
      property_hash[prefixed_attr_value] = {}
      property_hash[prefixed_attr_value]["count"] = 1
      property_hash[prefixed_attr_value]["uri"] = attr_value
    end
    return property_hash
  end
end
