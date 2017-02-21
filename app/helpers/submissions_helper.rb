module SubmissionsHelper

  # Generate the HTML input for every attributes
  def generate_attribute_input(attr)
    input_html = ''.html_safe

    if attr["enforce"].include?("integer")
      number_field :submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"])

    elsif attr["enforce"].include?("date_time")
      if @submission.send(attr["attribute"]).nil?
        date_value = nil
      else
        date_value = DateTime.parse(@submission.send(attr["attribute"])).to_date.to_s
      end
      text_field :submission, attr["attribute"].to_s.to_sym, :class => "datepicker", value: "#{date_value}"

    elsif attr["enforce"].include?("uri")
      if @submission.send(attr["attribute"]).nil?
        uri_value = ""
      else
        uri_value = @submission.send(attr["attribute"])
      end

      if attr["enforce"].include?("list")
        input_html << url_field(:submission, attr["attribute"].to_s.to_sym, value: uri_value[0], :style => "margin-bottom: 0.3em;")
        # Add field if list of URI
        @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
          if index != 0
            input_html << url_field_tag("added" + attr["attribute"].to_s + "[]", metadata_val, :id => "added" + attr["attribute"].to_s, :style => "margin-bottom: 0.3em;")
          end
        end
        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}", :style => "margin-bottom: 0.5em;margin-top: 0.5em;",
                                 :type => "button", :class => "btn btn-info", :onclick => "addInput('#{attr["attribute"]}', 'url')")
        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")

      else
        # if single value
        input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: uri_value)
      end
      return input_html

    elsif attr["enforce"].include?("boolean")
      select("submission", attr["attribute"].to_s, ["none", "true", "false"], { :selected => @submission.send(attr["attribute"])})

    else
      # If a simple text
      if attr["enforce"].include?("list")
        input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"])[0], :style => "margin-bottom: 0.3em;")
        # Add field if list of metadata
        @submission.send(attr["attribute"]).each_with_index do |metadata_val, index|
          if index != 0
            input_html << text_field_tag("added" + attr["attribute"].to_s + "[]", metadata_val, :id => "added" + attr["attribute"].to_s, :style => "margin-bottom: 0.3em;")
          end
        end

        input_html << button_tag("Add new value", :id => "add#{attr["attribute"]}", :style => "margin-bottom: 0.5em;margin-top: 0.5em;",
                                 :type => "button", :class => "btn btn-info", :onclick => "addInput('#{attr["attribute"]}', 'text')")
        input_html << content_tag(:div, "", id: "#{attr["attribute"]}Div")

      else
        # if single value
        input_html << text_field(:submission, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]))
      end
      return input_html
    end
  end

end