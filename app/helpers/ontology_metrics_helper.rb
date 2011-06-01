module OntologyMetricsHelper
  
  def class_list_info(metrics, metric, message, title)
    if metrics.send("#{metric}").nil?
      return
    end
    
    # Check to see if all properties are missing
    if metrics.send(:"#{metric}All") == true
      message = metrics.send(:"#{metric}_all")
      return "#{metrics.numberOfClasses} <span id='#{metric}_help' style='display: none;'>#{message}</span>"
    end
    
    markup = ""
    
    # Below we will use the 'send' method to call setters/getters based on the metric name we're looking for
    if metrics.send(:"#{metric}LimitPassed") != false
      class_list_length = metrics.send(:"#{metric}LimitPassed")
      markup << "#{class_list_length}"
      # Return here to avoid creating the 'details' link 
      return markup
    else
      class_list_length = metrics.send(:"#{metric}").length rescue 0 # Count empty arrays as zero
      markup << "<a class='thickbox' href='#TB_inline?height=600&width=800&inlineId=%metric%'>#{class_list_length}</a>".gsub("%title%", title).gsub("%metric%", metric)
    end
    
    markup << '<div id="%metric%" style="display: none;"><div class="metrics">'.gsub("%metric%", metric)
    
    # Message indicating why there are no details
    if metrics.send(:"#{metric}LimitPassed") == true
      markup << ""
    else
      markup << "<h2>#{title}</h2><p>"
      metrics.send(:"#{metric}").each do | class_name, count | 
        # TODO: Eventually we should link to the concept
        #markup << "<a href=\"/visualize/#{ontology.id}/?conceptid=#{class_name}\">#{class_name}<\/a>"
        markup << class_name
        if count
          markup << " (#{count} subclasses)"
        end
        markup << "<br />"
      end 
      markup << "</p></div>"
    end
      
    markup << "</div>"
    
    return markup    
  end
  
end