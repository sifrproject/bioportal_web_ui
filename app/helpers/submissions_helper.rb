module SubmissionsHelper

  # Generate the HTML label for every attributes
  def generate_attribute_label(attr_label)
    # Get the attribute hash corresponding to the given attribute
    attr = @metadata.select{ |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first
    label_html = ''.html_safe

    if !attr["label"].nil?
      label_html << label_tag("submission_#{attr_label}", attr["label"])
    else
      label_html << label_tag("submission_#{attr_label}", attr_label.underscore.humanize)
    end

    if !attr["extracted"].nil? && attr["extracted"] == true
      label_html << content_tag(:span, '*', class: "extractedAsterix")
    end

    # Generate tooltip
    if !attr["namespace"].nil?
      help_text = "&lt;strong&gt;#{attr["namespace"]}:#{attr["attribute"]}&lt;/strong&gt;"
    else
      help_text = "&lt;strong&gt;bioportal:#{attr["attribute"]}&lt;/strong&gt;"
    end

    if (attr["metadataMappings"] != nil)
      help_text << " (#{attr["metadataMappings"].join(", ")})"
    end

    if (attr["helpText"] != nil)
      help_text << "&lt;br&gt;#{attr["helpText"]}"
    end

    label_html << help_tooltip(help_text, {:id => "tooltip#{attr["attribute"]}", :style => "opacity: inherit; display: inline;position: initial;margin-right: 0.5em;"}).html_safe
    return label_html
  end

  # Generate the HTML input for every attributes.
  def generate_attribute_input(attr_label, select_options = nil)
    input_html = ''.html_safe

    # Get the attribute hash corresponding to the given attribute
    attr = @metadata.select{ |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first

    if attr["enforce"].include?("integer")
      number_field :submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"])

    elsif attr["enforce"].include?("date_time")
      if @submission.send(attr["attribute"]).nil?
        date_value = nil
      else
        date_value = DateTime.parse(@submission.send(attr["attribute"])).to_date.to_s
      end
      text_field(:submission, attr["attribute"].to_s.to_sym, :class => "datepicker", value: "#{date_value}")

    elsif attr["enforce"].include?("textarea")
      text_area(:submission, attr["attribute"].to_s.to_sym, rows: 3, value: @submission.send(attr["attribute"]))

    # Create select dropdown when asked
    # TODO: elsif attr["enforce"].include?("selectOther")
    elsif attr["attribute"].eql?("hasOntologySyntax")
      metadata_values = @submission.send(attr["attribute"])
      select_values = select_options.collect{ |k, v| [v,k]}
      # Add in the select ontologies that are not in the portal but are in the values
      if metadata_values.kind_of?(Array)
        metadata_values.map do |metadata|
          if !select_values.flatten.include?(metadata)
            select_values << metadata
          end
        end
      else
        if !select_values.flatten.include?(metadata_values)
          select_values << metadata_values
        end
      end
      select_values << ["None", "none"]
      select_values << ["Other", "other"]

      if attr["enforce"].include?("list")
        input_html << select_tag("submission[#{attr_label}][]", options_for_select(select_values, metadata_values), :multiple => 'true',
                                 "data-placeholder".to_sym => "Select ontologies", :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology")

      else
        #input_html << select_tag("submission[#{attr_label}]", options_for_select(select_values, metadata_values), "data-placeholder".to_sym => "Select ontology", :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology", :include_blank => true)

        input_html << select("submission", attr["attribute"], select_values, { :selected => metadata_values}, {:class => "form-control", :id => "select_#{attr["attribute"]}", :style=> "margin-bottom: 1em;"})
      end
      # Button and field to add new value (not in the select)
      # TODO: hide this. On affiche si other est sélectionné

      input_html << text_field_tag("add_#{attr["attribute"].to_s}", nil, :style => "margin-left: 1em; margin-right: 1em;width: 16em;display: none;", :placeholder => "Or provide the value")
      input_html << button_tag("Add new value", :id => "btnAdd#{attr["attribute"]}", :style => "margin-bottom: 2em;margin-top: 1em;display: none;vertical-align: baseline;",
                               :type => "button", :class => "btn btn-info btn-sm", :onclick => "addValueToSelect('#{attr["attribute"]}')")

      # To show/hide textbox when other option is selected or not
      input_html << javascript_tag("$(function() {
        $('#select_#{attr["attribute"]}').change(function() {
          if ($('#select_#{attr["attribute"]}').val() == 'other') {
            $('#add_#{attr["attribute"].to_s}').val("");
            $('#btnAdd#{attr["attribute"]}').show();
            $('#add_#{attr["attribute"].to_s}').show();
          } else {
            $('#btnAdd#{attr["attribute"]}').hide();
            $('#add_#{attr["attribute"].to_s}').hide();
          }
        });
      })")

      # To link text field with button (allowing enter in text field to submit button)
      input_html << javascript_tag("$('#add_#{attr["attribute"]}').keyup(function(event){
        if(event.keyCode == 13){
            addValueToSelect('#{attr["attribute"]}')
        }
        });")

      return input_html


    elsif attr["enforce"].include?("isOntology")
      metadata_values = @submission.send(attr["attribute"])
      select_values = @ontologies_for_select.dup
      # Add in the select ontologies that are not in the portal but are in the values
      if metadata_values.kind_of?(Array)
        metadata_values.map do |metadata|
          if !select_values.flatten.include?(metadata)
            select_values << metadata
          end
        end
      else

        if !select_values.flatten.include?(metadata_values)
          select_values << metadata_values
        end
      end

      if attr["enforce"].include?("list")
        input_html << select_tag("submission[#{attr_label}][]", options_for_select(select_values, metadata_values), :multiple => 'true',
            "data-placeholder".to_sym => "Select ontologies", :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology")

      else
        input_html << select_tag("submission[#{attr_label}]", options_for_select(select_values, metadata_values), "data-placeholder".to_sym => "Select ontology",
                   :style => "margin-bottom: 15px; width: 100%;", :id => "select_#{attr["attribute"]}", :class => "selectOntology", :include_blank => true)
      end
      # Button and field to add new value (not in the select)
      input_html << tag(:br)
      input_html << text_field_tag("add_#{attr["attribute"]}", nil, :style => "margin-left: 1em; margin-right: 1em;vertical-align: super;width: 16em;", :placeholder => "Ontology outside of the Portal")
      input_html << button_tag("Add new ontology", :id => "btnAdd#{attr["attribute"]}", :style => "margin-bottom: 2em;margin-top: 1em;",
                               :type => "button", :class => "btn btn-info btn-sm", :onclick => "addOntoToSelect('#{attr["attribute"]}')")

      input_html << javascript_tag("$('#add_#{attr["attribute"]}').keyup(function(event){
        if(event.keyCode == 13){
            addOntoToSelect('#{attr["attribute"]}')
        }
        });")

      return input_html

    elsif attr["enforce"].include?("uri")
      if @submission.send(attr["attribute"]).nil?
        uri_value = ""
      else
        uri_value = @submission.send(attr["attribute"])
      end

      if attr["enforce"].include?("list")
        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}", :style => "margin-bottom: 0.5em;margin-top: 0.5em;margin-left: 0.5em;",
                                 :type => "button", :class => "btn btn-info btn-sm", :onclick => "addInput('#{attr["attribute"]}', 'url')")
        input_html << url_field_tag("submission[#{attr["attribute"].to_s}][]", uri_value[0], :id => attr["attribute"].to_s, class: "metadataInput")
        # Add field if list of URI
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
            if index != 0
              input_html << url_field_tag("submission[#{attr["attribute"].to_s}][]", metadata_val, :id => "submission_#{attr["attribute"].to_s}", class: "metadataInput")
            end
          end
        end
        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")

      else
        # if single value
        input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: uri_value, class: "metadataInput")
      end
      return input_html

    elsif attr["enforce"].include?("boolean")
      select("submission", attr["attribute"].to_s, ["none", "true", "false"], { :selected => @submission.send(attr["attribute"])},
             {:class => "form-control", :style => "margin-top: 0.5em; margin-bottom: 0.5em;"})

    else
      # If input a simple text

      if attr["enforce"].include?("list")
        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}", :style => "margin-bottom: 0.5em;margin-top: 0.5em;",
                                 :type => "button", :class => "btn btn-info btn-sm", :onclick => "addInput('#{attr["attribute"]}', 'text')")
        firstVal = ""
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          firstVal = @submission.send(attr["attribute"])[0]
        end
        input_html << text_field_tag("submission[#{attr["attribute"].to_s}][]", firstVal, :id => attr["attribute"].to_s, class: "metadataInput")

        # Add field if list of metadata
        if !@submission.send(attr["attribute"]).nil? && @submission.send(attr["attribute"]).any?
          @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
            if index != 0
              input_html << text_field_tag("submission[#{attr["attribute"].to_s}][]", metadata_val, :id => "submission_#{attr["attribute"].to_s}", class: "metadataInput")
            end
          end
        end

        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")

      else
        # if single value text
        # TODO: For some reason @submission.send("URI") FAILS... I don't know why... so I need to call it manually
        if attr["attribute"].to_s.eql?("URI")
          input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.URI,class: "metadataInput")
        else
          input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]), class: "metadataInput")
        end
      end
      return input_html
    end
  end

end