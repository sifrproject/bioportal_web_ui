module OntologiesHelper

  REST_URI = $REST_URL
  API_KEY = $API_KEY

  def additional_details
    return "" if $ADDITIONAL_ONTOLOGY_DETAILS.nil? || $ADDITIONAL_ONTOLOGY_DETAILS[@ontology.acronym].nil?
    details = $ADDITIONAL_ONTOLOGY_DETAILS[@ontology.acronym]
    html = []
    details.each do |title, value|
      html << content_tag(:tr) do
        concat(content_tag(:th, title))
        concat(content_tag(:td, raw(value)))
      end
    end
    html.join("")
  end

  # Add additional metadata as html for a submission
  def additional_metadata(sub)
    # Get the list of metadata attribute from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    metadata_list = {}
    # Get extracted metadata and put them in a hash with their label, if one, as value
    json_metadata.each do |metadata|
      if metadata["extracted"] == true
        metadata_list[metadata["attribute"]] = metadata["label"]
      end
    end

    html = []

    metadata_not_displayed = ["status", "description", "documentation", "publication", "homepage", "openSearchDescription", "dataDump"]

    begin

      metadata_list.each do |metadata, label|
        # Don't display documentation, publication, homepage, status and description, they are already in main details
        if !metadata_not_displayed.include?(metadata)
          # different html build if list or single value

          # METADATA ARRAY
          if sub.send(metadata).kind_of?(Array)
            if sub.send(metadata).any?
              if metadata.eql?("naturalLanguage")
                # Special treatment for naturalLanguage: we want the flags in a bootstrap box
                # UK is gb: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
                lang_codes = []
                sub.send(metadata).each do |lang|
                  if (lang.to_s.eql?("en") || lang.to_s.eql?("eng") || lang.to_s.eql?("http://lexvo.org/id/iso639-3/eng"))
                    # We consider en and eng as english
                    lang_codes << "gb"
                  elsif lang.start_with?("http://lexvo.org")
                    lang_codes << $LEXVO_TO_FLAG[lang]
                  else
                    lang_codes << lang
                  end
                end
                html << content_tag(:div, {:class => "col-md-2"}) do
                  concat(content_tag(:div, {:class => "panel panel-primary"}) do
                    concat(content_tag(:div, {:class => "panel-heading"}) do
                      concat(content_tag(:h3, "naturalLanguage", {:class => "panel-title"}))
                    end)
                    concat(content_tag(:div, {:class => "panel-body"}) do
                      concat(content_tag(:ul, {:class => "f32"}) do
                        lang_codes.each do |lang_code|
                          if lang_code.length == 2
                            concat(content_tag(:li, "", {:class => "flag #{lang_code}", :style => "margin-right: 0.5em;"}))
                          else
                            concat(content_tag(:li, lang_code))
                          end
                        end
                      end)
                    end)
                  end)
                end

              elsif (metadata.eql?("includedInDataCatalog"))
                # Buttons for data catalogs
                html << content_tag(:div, {:class => "col-md-4"}) do
                  concat(content_tag(:div, {:class => "panel panel-primary"}) do
                    concat(content_tag(:div, {:class => "panel-heading"}) do
                      concat(content_tag(:h3, "includedInDataCatalog", {:class => "panel-title"}))
                    end)
                    concat(content_tag(:div, {:class => "panel-body"}) do
                      sub.send(metadata).each do |catalog|
                        catalog_btn_label = catalog
                        $DATA_CATALOG_VALUES.each do |cat_uri, cat_label|
                          if catalog.start_with?(cat_uri)
                            catalog_btn_label = cat_label
                            break;
                          end
                        end
                        concat(content_tag(:a, catalog_btn_label, {:class => "btn btn-primary",
                                                                   :style => "margin-bottom: 1em; margin-right: 1em;", :href => catalog, :target => "_blank"}))
                      end
                    end)
                  end)
                end

              else
                html << content_tag(:tr) do
                  if label.nil?
                    concat(content_tag(:th, metadata.gsub(/(?=[A-Z])/, " ")))
                  else
                    concat(content_tag(:th, label))
                  end

                  metadata_array = []
                  sub.send(metadata).each do |metadata_value|

                    if metadata_value.to_s.start_with?("#{$REST_URL}/ontologies/")
                      # For URI that links to our ontologies we display a button with only the acronym. And redirect to the UI
                      # Warning! Redirection is done by removing "data." from the REST_URL. So might not work perfectly everywhere
                      if metadata_value.to_s.split("/").length < 6
                        # for ontologies/ACRONYM we redirect to the UI url
                        metadata_array.push("<a href=\"#{metadata_value.to_s.sub("data.", "")}\" class=\"btn btn-primary\" target=\"_blank\">#{metadata_value.to_s.split("/")[4..-1].join("/")}</a>")
                      else
                        metadata_array.push("<a href=\"#{metadata_value.to_s}\" class=\"btn btn-primary\" target=\"_blank\">#{metadata_value.to_s.split("/")[4..-1].join("/")}</a>")
                      end

                    elsif metadata_value.to_s =~ /\A#{URI::regexp(['http', 'https'])}\z/
                      # Don't create a link if it not an URI
                      metadata_array.push("<a href=\"#{metadata_value.to_s}\" target=\"_blank\">#{metadata_value.to_s}</a>")
                    else
                      metadata_array.push(metadata_value)
                    end
                  end
                  concat(content_tag(:td, raw(metadata_array.join(", "))))
                end
              end
            end
          else

            # SINGLE METADATA
            if !sub.send(metadata).nil?
              html << content_tag(:tr) do
                if label.nil?
                  concat(content_tag(:th, metadata.gsub(/(?=[A-Z])/, " ")))
                else
                  concat(content_tag(:th, label))
                end

                if (metadata.eql?("hasLicense"))
                  if (sub.send(metadata).start_with?("http://creativecommons.org/licenses") || sub.send(metadata).start_with?("https://creativecommons.org/licenses"))
                    concat(content_tag(:td) do
                      concat(content_tag(:a, {:rel => "license", :alt=>"Creative Commons License",
                                              :href => sub.send(metadata), :target => "_blank", :style=>"border-width:0", :title => sub.send(metadata),
                                              :src=>"https://i.creativecommons.org/l/by/4.0/88x31.png"}) do

                        concat(content_tag(:img, "",{:rel => "license", :alt=>"Creative Commons License", :title => sub.send(metadata),
                                                     :style=>"border-width:0", :src=>"https://i.creativecommons.org/l/by/4.0/88x31.png"}))
                      end)
                    end)

                elsif (sub.send(metadata).start_with?("http://opensource.org/licenses") || sub.send(metadata).start_with?("https://opensource.org/licenses"))
                  concat(content_tag(:td) do
                    concat(content_tag(:a, {:rel => "license", :alt=>"Open Source License",
                                            :href => sub.send(metadata), :title => sub.send(metadata),:target => "_blank", :style=>"border-width:0;",
                                            :src=>"https://opensource.org/files/osi_logo_bold_100X133_90ppi.png"}) do

                      concat(content_tag(:img, "",{:rel => "license", :alt=>"Open Source License", :title => sub.send(metadata),
                                                   :style=>"height: 80px; border-width:0;", :src=>"https://opensource.org/files/osi_logo_bold_100X133_90ppi.png"}))
                    end)
                  end)

                  else
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata), {:rel => "license", :href => sub.send(metadata), :target => "_blank"}))
                    end)
                  end

                elsif sub.send(metadata).start_with?("#{$REST_URL}/ontologies/")
                  # For URI that links to our ontologies we display a button with only the acronym. And redirect to the UI
                  # Warning! Redirection is done by removing "data." from the REST_URL. So might not work perfectly everywhere
                  if sub.send(metadata).to_s.split("/").length < 6
                    # for ontologies/ACRONYM we redirect to the UI url
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata).to_s.split("/")[4..-1].join("/"), {:class=>"btn btn-primary",
                                                                                                   :href => sub.send(metadata).sub("data.", ""), :target => "_blank", :title => sub.send(metadata)}))
                    end)
                  else
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata).to_s.split("/")[4..-1].join("/"), {:class=>"btn btn-primary",
                                                                                                   :href => sub.send(metadata), :target => "_blank", :title => sub.send(metadata)}))
                    end)
                  end

                else
                  if sub.send(metadata).to_s =~ /\A#{URI::regexp(['http', 'https'])}\z/
                    # Don't create a link if it not an URI
                    concat(content_tag(:td, raw("<a href=\"#{sub.send(metadata).to_s}\" target=\"_blank\">#{sub.send(metadata).to_s}</a>")))
                  else
                    concat(content_tag(:td, raw(sub.send(metadata).to_s)))
                  end
                end
              end
            end
          end
        end
      end
    rescue => e
      LOG.add :debug, "Unable to retrieve additional ontology metadata"
      LOG.add :debug, "error: #{e}"
      LOG.add :debug, "error message: #{e.message}"
    end
    html.join("")
  end

  def count_links(ont_acronym, page_name='summary', count=0)
    ont_url = "/ontologies/#{ont_acronym}"
    if count.nil? || count == 0
      return "0"
      #return "<a href='#{ont_url}/?p=summary'>0</a>"
    else
      return "<a href='#{ont_url}/?p=#{page_name}'>#{number_with_delimiter(count, :delimiter => ',')}</a>"
    end
  end

  def classes_link(ontology, count)
    return "0" if (ontology.summaryOnly || count.nil? || count == 0)
    return count_links(ontology.ontology.acronym, 'classes', count)
  end

  # Creates a link based on the status of an ontology submission
  def download_link(submission, ontology = nil)
    ontology ||= @ontology
    if ontology.summaryOnly
      if submission.homepage.nil?
        link = 'N/A'
      else
        uri = submission.homepage
        link = "<a href='#{uri}'>Home Page</a>"
      end
    else
      uri = submission.id + "/download?apikey=#{get_apikey}"
      link = "<a href='#{uri}'>#{submission.pretty_format}</a>"
      latest = ontology.explore.latest_submission({:include_status => 'ready'})
      if latest && latest.submissionId == submission.submissionId
        link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=csv'>CSV</a>"
        if !latest.hasOntologyLanguage.eql?("UMLS")
          link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=rdf'>RDF/XML</a>"
        end
      end
      unless submission.diffFilePath.nil?
        uri = submission.id + "/download_diff?apikey=#{get_apikey}"
        link = link + " | <a href='#{uri}'>Diff</a>"
      end
    end
    return link
  end

  def mappings_link(ontology, count)
    return "0" if (ontology.summaryOnly || count.nil? || count == 0)
    return count_links(ontology.ontology.acronym, 'mappings', count)
  end

  def notes_link(ontology, count)
    #count = 0 if ontology.summaryOnly
    return count_links(ontology.ontology.acronym, 'notes', count)
  end

  # Creates a link based on the status of an ontology submission
  def status_link(submission, sub_ontology=nil, latest=false, target="")
    version_text = submission.version.nil? || submission.version.length == 0 ? "unknown" : submission.version
    status_text = " <span class='ontology_submission_status'>" + submission_status2string(submission) + "</span>"
    if sub_ontology.nil?
      sub_ontology = submission.explore.ontology
    end
    if sub_ontology.summaryOnly || latest==false
      version_link = version_text
    else
      version_link = "<a href='/ontologies/#{sub_ontology.acronym}?p=classes' #{target.empty? ? "" : "target='#{target}'"}>#{version_text}</a>"
    end
    return version_link + status_text
  end

  def submission_status2string(sub)
    # Massage the submission status into a UI string
    #submission status values, from:
    # https://github.com/ncbo/ontologies_linked_data/blob/master/lib/ontologies_linked_data/models/submission_status.rb
    # "UPLOADED", "RDF", "RDF_LABELS", "INDEXED", "METRICS", "ANNOTATOR", "ARCHIVED"  and 'ERROR_*' for each.
    # Strip the URI prefix from the status codes (works even if they are not URIs)
    # The order of the codes must be assumed to be random, it is not an entirely
    # predictable sequence of ontology processing stages.
    codes = sub.submissionStatus.map {|s| s.split('/').last }
    errors = codes.select {|c| c.start_with? 'ERROR'}.map {|c| c.gsub("_", " ").split(/(\W)/).map(&:capitalize).join}.compact
    status = []
    status.push('Parsed') if (codes.include? 'RDF') && (codes.include? 'RDF_LABELS')
    # The order of this array imposes an oder on the UI status code string
    status_list = [ "INDEXED", "METRICS", "ANNOTATOR", "ARCHIVED" ]
    status_list.insert(0, 'UPLOADED') unless status.include?('Parsed')
    status_list.each do |c|
      status.push(c.capitalize) if codes.include? c
    end
    status.concat errors
    return '' if status.empty?
    return '(' + status.join(', ') + ')'
  end

  # Link for private/public/licensed ontologies
  def visibility_link(ontology)
    ont_url = "/ontologies/#{ontology.acronym}"  # 'ontology' is NOT a submission here
    page_name = 'summary'  # default ontology page view for visibility link
    link_name = 'Public'   # default ontology visibility
    if ontology.summaryOnly
      link_name = 'Summary Only'
    elsif ontology.private?
      link_name = 'Private'
    elsif ontology.licensed?
      link_name = 'Licensed'
    end
    return "<a href='#{ont_url}/?p=#{page_name}'>#{link_name}</a>"
  end

  def visits_data(ontology = nil)
    ontology ||= @ontology
    return nil unless @analytics && @analytics[ontology.acronym.to_sym]
    return @visits_data if @visits_data
    visits_data = {visits: [], labels: []}
    years = @analytics[ontology.acronym.to_sym].to_h.keys.map {|e| e.to_s.to_i}.select {|e| e > 0}.sort
    now = Time.now
    years.each do |year|
      months = @analytics[ontology.acronym.to_sym].to_h[year.to_s.to_sym].to_h.keys.map {|e| e.to_s.to_i}.select {|e| e > 0}.sort
      months.each do |month|
        next if now.year == year && now.month <= month || (year == 2013 && month < 10) # we don't have good data going back past Oct 2013
        visits_data[:visits] << @analytics[ontology.acronym.to_sym].to_h[year.to_s.to_sym][month.to_s.to_sym]
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    @visits_data = visits_data
  end

end
