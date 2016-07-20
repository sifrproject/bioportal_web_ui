class LandscapeController < ApplicationController
  layout 'ontology'

  def index
    @ontologies = LinkedData::Client::Models::Ontology.all(include_views: false)
    #@submissions = LinkedData::Client::Models::OntologySubmission.all(values: params[:submission])

    # Array with color codes for the pie charts. iterate color_index to change color
    pie_colors_array = ["#2484c1", "#0c6197", "#4daa4b", "#90c469", "#daca61", "#e4a14b", "#e98125", "#cb2121", "#830909", "#923e99", "#ae83d5", "#bf273e", "#ce2aeb", "#bca44a", "#618d1b", "#1ee67b", "#b0ec44", "#a4a0c9", "#322849", "#86f71a", "#d1c87f", "#7d9058", "#44b9b0", "#7c37c0", "#cc9fb1", "#e65414", "#8b6834", "#248838"];
    color_index = 0

    # A hash with the language label and the number of time it appears in sub.naturalLanguage
    natural_language_hash = {}
    prefLabelProperty_hash = {}
    synonymProperty_hash = {}
    definitionProperty_hash = {}
    authorProperty_hash = {}

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

    # Iterate ontologies to get the submissions with all metadata
    @ontologies.each do |ont|
      sub = ont.explore.latest_submission

      if !sub.nil?

        # Get hash of natural language use
        if !sub.naturalLanguage.nil? && !sub.naturalLanguage.empty?
          sub.naturalLanguage.each do |sub_lang|
            # replace lexvo URI by lexvo prefix
            if sub_lang.start_with?("http://lexvo.org/id/iso639-3/")
              sub_lang = sub_lang.sub("http://lexvo.org/id/iso639-3/", "lexvo:")
            end
            # If lang already in hash then we increment the count of the lang in the hash
            if natural_language_hash.has_key?(sub_lang.to_s)
              natural_language_hash[sub_lang.to_s] = natural_language_hash[sub_lang.to_s] + 1
            else
              natural_language_hash[sub_lang.to_s] = 1
            end
          end
        end

        # Get the prefLabelProperty used for OWL properties in a hash
        if sub.hasOntologyLanguage.eql?("OWL")
          prefLabelProperty_hash = get_used_properties(sub.prefLabelProperty, "http://www.w3.org/2004/02/skos/core#prefLabel", prefLabelProperty_hash)

          synonymProperty_hash = get_used_properties(sub.synonymProperty, "http://www.w3.org/2004/02/skos/core#altLabel", synonymProperty_hash)

          definitionProperty_hash = get_used_properties(sub.definitionProperty, "http://www.w3.org/2004/02/skos/core#definition", definitionProperty_hash)

          authorProperty_hash = get_used_properties(sub.authorProperty, "http://purl.org/dc/elements/1.1/creator", authorProperty_hash)
        end

        get_metrics_for_average(sub)

      end
    end

    # Add value of metrics to the @metrics_average hash
    @metrics_average.each do |metrics|
      metrics[:average] = (metrics[:array].sum / metrics[:array].size.to_f).round(2)
    end

    # Generate the JSON to put natural languages in the pie chart
    @natural_language_json_pie = []
    # Get the different naturalLanguage of submissions to generate a tag cloud
    @natural_language_json_cloud = []
    # Generate the JSON to put natural languages in the pie chart
    @prefLabelProperty_json_pie = []
    @synonymProperty_json_pie = []
    @definitionProperty_json_pie = []
    @authorProperty_json_pie = []

    natural_language_hash.each do |lang,no|
      @natural_language_json_cloud.push({"text"=>lang.to_s,"size"=>no*5, "color"=>pie_colors_array[color_index]})

      @natural_language_json_pie.push({"label"=>lang.to_s,"value"=>no, "color"=>pie_colors_array[color_index]})
      color_index += 1
    end

    prefLabelProperty_hash.each do |pref_label,no|
      @prefLabelProperty_json_pie.push({"label"=>pref_label.to_s,"value"=>no, "color"=>pie_colors_array[color_index]})
      color_index += 1
    end
    synonymProperty_hash.each do |synonym,no|
      @synonymProperty_json_pie.push({"label"=>synonym.to_s,"value"=>no, "color"=>pie_colors_array[color_index]})
      color_index += 1
    end
    definitionProperty_hash.each do |definition,no|
      @definitionProperty_json_pie.push({"label"=>definition.to_s,"value"=>no, "color"=>pie_colors_array[color_index]})
      color_index += 1
    end
    authorProperty_hash.each do |author,no|
      @authorProperty_json_pie.push({"label"=>author.to_s,"value"=>no, "color"=>pie_colors_array[color_index]})
      color_index += 1
    end

    @natural_language_json_cloud = @natural_language_json_cloud.to_json.html_safe
    @natural_language_json_pie = @natural_language_json_pie.to_json.html_safe

    # used properties pie charts html safe formatting
    @prefLabelProperty_json_pie = @prefLabelProperty_json_pie.to_json.html_safe
    @synonymProperty_json_pie = @synonymProperty_json_pie.to_json.html_safe
    @definitionProperty_json_pie = @definitionProperty_json_pie.to_json.html_safe
    @authorProperty_json_pie = @authorProperty_json_pie.to_json.html_safe

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
      attr_value = default_property
    else
      attr_value = attr_value.to_s
    end

    # If attribute value property already in hash then we increment the count of the property in the hash
    if property_hash.has_key?(attr_value)
      property_hash[attr_value] = property_hash[attr_value] + 1
    else
      property_hash[attr_value] = 1
    end
    return property_hash
  end
end
