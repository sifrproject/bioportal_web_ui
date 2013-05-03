class SyndicationController < ApplicationController

  def rss
    limit = params[:limit] || 20
    if params[:ontologies].nil? || params[:ontologies].eql?("all")
      events = EventItem.find(:all,:order=>"created_at desc",:limit=>limit)
    else
      events = EventItem.find(:all,:conditions=>{:ontology_id=>params[:ontologies].split(",")},:order=>"created_at desc",:limit=>limit)
    end
    feed_items=[]

    for event in events
      begin
        case event.event_type
          when "Ontology"
            ontology = DataAccess.getOntology(event.event_type_id)
            feed_items << {:title=>"Ontology added",:description=>"Ontology  #{ontology.displayLabel} version #{ontology.versionNumber} was added to the repository",:date=>event.created_at,:link=>"#{$UI_URL}/ontologies/#{ontology.id}"}
          when "Note"
            note = DataAccess.getNote(event.ontology_id, event.event_type_id, false, true)
            note_type = Class.new.extend(NotesHelper).get_note_type_text(note.type)
            note_url = Class.new.extend(NotesHelper).get_applies_to_url(note.createdInOntologyVersion, note.appliesTo['type'], note.appliesTo['id'])
            note_text = note.type.eql?("Comment") ? "Comment: #{note.body}" : "Reason for request: #{note.values[note.type]['reasonForChange']}"
            applies_to = note.appliesTo['type'].eql?("Ontology") ? "(#{note.ontology.displayLabel})" : "#{note.appliesTo['id']} in #{note.ontology.displayLabel}"

            feed_items << { :title => "#{note_type} added to #{note.appliesTo['type']} #{applies_to}", :description => note_text, :date => event.created_at, :link => "#{$UI_URL}#{note_url}" }
          when "Mapping"
            mapping = DataAccess.getMapping(event.event_type_id)
            feed_items << {:title=>"Mapping added in #{mapping.ontology.displayLabel}",:description=>"Mapping from #{mapping.source_name} to #{mapping.destination_name}",:date=>event.created_at,:link=>"#{$UI_URL}/visualize/#{mapping.source_version_id}/#{mapping.source_id}"}
        end
      rescue
        #Catches exceptions from backend discrepencies
      end
    end

    if params[:callback].nil?

      xml_feed = "<rss version=\"2.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
        <channel>
        <title>#{$SITE} Updates</title>
        <link>#{$UI_URL}</link>
        <description>Updates to the #{$ORG_SITE} Repository</description>
        <language>en-us</language>"

      for item in feed_items
        xml_feed <<"<item>"
        xml_feed <<"<title>#{item[:title]}</title>"
        xml_feed <<"<link>#{item[:link]}</link>"
        xml_feed <<"<description>#{item[:description]}</description>"
        xml_feed <<"<dc:creator>bioontology.org</dc:creator>"
        xml_feed <<"<dc:date>#{item[:date]}</dc:date>"
        xml_feed <<"</item>"
      end

      xml_feed <<"</channel>"
      xml_feed <<"</rss>"

      render :text=>xml_feed

    else
      json_response="#{params[:callback]}(["
      for item in feed_items
        json_response <<"{"
        json_response <<"title:'#{item[:title].split(" in ")[0]}',"
        json_response <<"link: '#{item[:link]}',"
        json_response <<"description:'#{item[:description].gsub(/\n/, "\\n")}',"
        json_response <<"date:'#{item[:date].strftime("%m/%d/%y")}'"
        json_response <<"}"
        unless item.eql?(feed_items.last)
          json_response<<","
        end
      end


      json_response << "])"

          #dont save it if its a test
  #  begin
    if !request.env['HTTP_REFERER'].nil? && !request.env["HTTP_REFERER"].downcase.include?("bioontology.org")
      widget_log = WidgetLog.find_or_initialize_by_referer_and_widget(request.env["HTTP_REFERER"],'feed')
      if widget_log.id.nil?
        widget_log.count=1
      else
        widget_log.count+=1
      end
      widget_log.save
    end

      render :text=>json_response
    end

  end

end
