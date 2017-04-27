require 'action_view'
include ActionView::Helpers::NumberHelper

class LandscapeController < ApplicationController
  layout 'ontology'

  def index
    @ontologies = LinkedData::Client::Models::Ontology.all(include_views: false)
    #@submissions = LinkedData::Client::Models::OntologySubmission.all(values: params[:submission])

    # Array with color codes for the pie charts. iterate color_index to change color
    pie_colors_array = ["#2484c1", "#0c6197", "#4daa4b", "#90c469", "#daca61", "#e4a14b", "#e98125", "#cb2121", "#830909", "#923e99", "#ae83d5", "#bf273e", "#ce2aeb", "#bca44a", "#618d1b", "#1ee67b", "#b0ec44", "#a4a0c9", "#322849", "#86f71a", "#d1c87f", "#7d9058", "#44b9b0", "#7c37c0", "#cc9fb1", "#e65414", "#8b6834", "#248838"];

    groups_hash = {}
    domains_hash = {}
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

    prefLabelProperty_hash = {}
    synonymProperty_hash = {}
    definitionProperty_hash = {}
    authorProperty_hash = {}

    people_count_hash = {}
    people_count_emails = {}
    notes_people_count_hash = {}
    notes_ontologies_count_hash = {}

    org_count_hash = {}

    ontology_relations_array = []

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

    ontologyFormatsCount = {"OWL" => 0, "SKOS" => 0, "UMLS" => 0, "OBO" => 0}

    # Iterate ontologies to get the submissions with all metadata
    @ontologies.each do |ont|
      sub = ont.explore.latest_submission

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
        ont.explore.groups.each do |group|
          if groups_hash.has_key?(group.acronym.to_s)
            groups_hash[group.acronym.to_s] += 1
          else
            groups_hash[group.acronym.to_s] = 1
          end
        end

        # Count number of ontologies for each domain (bar chart)
        ont.explore.categories.each do |domain|
          if domains_hash.has_key?(domain.acronym.to_s)
            domains_hash[domain.acronym.to_s] += 1
          else
            domains_hash[domain.acronym.to_s] = 1
          end
        end

        # Get people that are mentioned as ontology actors (contact, contributors, creators, curator) to create a tag cloud
        # hasContributor hasCreator contact(explore,name) curatedBy
        contributors_attr_list = [:hasContributor, :hasCreator, :curatedBy]
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

        org_attr_list = [:fundedBy, :endorsedBy]
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

        notes_count = 0
        # Get people that are mentioned as ontology actors (contact, contributors, creators, curator) to create a tag cloud
        # hasContributor hasCreator contact(explore,name) curatedBy
        notes_attr_list = [:notes, :reviews, :projects]
        notes_attr_list.each do |note_attr|
          notes_obj = ont.explore.send(note_attr.to_s)
          if !notes_obj.nil?
            notes_obj.each do |note|
              notes_count += 1
              users = note.creator
              if !users.kind_of?(Array)
                users = [users]
              end
              users.each do |user_id|
                #user = LinkedData::Client::Models::User.find(user_id)
                username = user_id.split('/').last
                if notes_people_count_hash.has_key?(username)
                  notes_people_count_hash[username] += 1
                else
                  notes_people_count_hash[username] = 1
                end
                #people_count_emails[user.username] = user.email if !user.email.nil?
              end
            end
          end
        end

        notes_ontologies_count_hash[ont.acronym] = notes_count


        # Get ontology relations between each other (ex: STY isAlignedTo GO)
        @relations_array = ["omv:useImports", "door:isAlignedTo", "door:ontologyRelatedTo", "omv:isBackwardCompatibleWith", "omv:isIncompatibleWith", "door:comesFromTheSameDomain", "door:similarTo",
         "door:explanationEvolution", "voaf:generalizes", "door:hasDisparateModelling", "dct:hasPart", "voaf:usedBy", "schema:workTranslation", "schema:translationOfWork"]
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

    # Get the different people and organizations to generate a tag cloud
    people_count_json_cloud = []
    org_count_json_cloud = []
    notes_ontologies_json_cloud = []
    notes_people_json_cloud = []

    # Generate the JSON to put natural languages in the pie chart
    natural_language_json_pie = []
    licenseProperty_json_pie = []
    formalityProperty_json_pie = []

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

    notes_people_count_hash.each do |people,no|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      notes_people_json_cloud.push({"text"=>people.to_s,"weight"=>no, "html" => {style: "color: ##{colour};", title: "#{no.to_s} notes, reviews or projects."}})
    end

    notes_ontologies_count_hash.each do |onto,no|
      # Random color for each word in the cloud
      colour = "%06x" % (rand * 0xffffff)
      notes_ontologies_json_cloud.push({"text"=>onto.to_s,"weight"=>no, "html" => {style: "color: ##{colour};", title: "#{no.to_s} notes, reviews or projects."}})
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

    color_index = 0
    formalityProperty_hash.each do |formality_level,count_hash|
      formalityProperty_json_pie.push({"label"=>formality_level.to_s,"value"=>count_hash["count"], "color"=>pie_colors_array[color_index], "uri"=>count_hash["uri"]})
      color_index += 1
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
        :datasets => [{ :label => "Number of ontologies using each format", :data => ontologyFormatsCount.values,
                       :backgroundColor => ["#669911", "#119966", "#66A2EB", "#FCCE56"],
                       :hoverBackgroundColor => ["#66A2EB", "#FCCE56", "#669911", "#119966"]}] }

    # Format the groupOntologiesCount hash as the JSON needed to generate the chart
    groupCountChartJson = { :labels => groups_hash.keys,
                                  :datasets => [{ :label => "Number of ontologies in each group", :data => groups_hash.values,
                                                  :backgroundColor => pie_colors_array,
                                                  :hoverBackgroundColor => pie_colors_array.reverse}] }

    domainCountChartJson = { :labels => domains_hash.keys,
                             :datasets => [{ :label => "Number of ontologies in each domain", :data => domains_hash.values,
                                             :backgroundColor => pie_colors_array,
                                             :hoverBackgroundColor => pie_colors_array.reverse}] }

    # Format the groupOntologiesCount hash as the JSON needed to generate the chart
    sizeSlicesChartJson = { :labels => size_slices_hash.keys,
                             :datasets => [{ :label => "Number of ontologies with a class count in the given range", :data => size_slices_hash.values,
                                             :backgroundColor => pie_colors_array,
                                             :hoverBackgroundColor => pie_colors_array.reverse}] }

    @landscape_data = {
        :people_count_json_cloud => people_count_json_cloud,
        :org_count_json_cloud => org_count_json_cloud,
        :notes_ontologies_json_cloud => notes_ontologies_json_cloud,
        :notes_people_json_cloud => notes_people_json_cloud,
        :natural_language_json_pie => natural_language_json_pie,
        :licenseProperty_json_pie => licenseProperty_json_pie,
        :formalityProperty_json_pie => formalityProperty_json_pie,
        :ontology_relations_array => ontology_relations_array,
        :prefLabelProperty_json_pie => prefLabelProperty_json_pie,
        :synonymProperty_json_pie => synonymProperty_json_pie,
        :definitionProperty_json_pie => definitionProperty_json_pie,
        :authorProperty_json_pie => authorProperty_json_pie,
        :ontologyFormatsChartJson => ontologyFormatsChartJson,
        :groupCountChartJson => groupCountChartJson,
        :domainCountChartJson => domainCountChartJson,
        :sizeSlicesChartJson => sizeSlicesChartJson
    }.to_json.html_safe

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
