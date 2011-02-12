# Methods added to this helper will be available to all templates in the application.

require 'uri'
require 'cgi'

module ApplicationHelper
  
  def isOwner?(id)
    unless session[:user].nil?
      if session[:user].admin?
        return true        
      elsif session[:user].id.eql?(id)
        return true
      else
        return false
      end
    end
  end
  
  def encode_param(string)
    return URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
  
  def clean(string)
    string = string.gsub("\"",'\'')
    return string.gsub("\n",'')
  end
  
  def clean_id(string)
    new_string = string.gsub(":","").gsub("-","_").gsub(".","_")
    return new_string
  end
  
  def to_param(string)
     "#{encode_param(string.gsub(" ","_"))}"
  end
  
  # Notes-related helpers that could be useful elsewhere
  
  def convert_java_time(time_in_millis)
    time_in_millis.to_i / 1000
  end
  
  def time_from_java(java_time)
    Time.at(convert_java_time(java_time.to_i))
  end
  
  def time_formatted_from_java(java_time)
    time_from_java(java_time).strftime("%m/%d/%Y")
  end

  def get_username(user_id)
    user = DataAccess.getUser(user_id) rescue nil
    username = user.nil? ? user_id : user.username
    username
  end
  
  # end Notes-related helpers
  
  def remove_owl_notation(string)
    unless string.nil?
      strings = string.split(":")
      if strings.size<2
        return string.titleize
      else  
        return strings[1].titleize
      end
    end
  end
  
  def draw_note_tree(notes,key)
    output = ""
    draw_note_tree_leaves(notes,0,output,key)
    return output
  end
  
  def draw_note_tree_leaves(notes,level,output,key)
    for note in notes
      name="Anonymous"
      unless note.user.nil?
        name=note.user.username
      end
      headertext=""
      notetext=""
      if note.note_type.eql?(5)
        headertext<< "<div class=\"header\" onclick=\"toggleHide('note_body#{note.id}','');compare('#{note.id}')\">"
        notetext << " <input type=\"hidden\" id=\"note_value#{note.id}\" value=\"#{note.comment}\"> 
                  <span class=\"message\" id=\"note_text#{note.id}\">#{note.comment}</span>"
      else
        headertext<< "<div onclick=\"toggleHide('note_body#{note.id}','')\">"
        
        notetext<< "<span class=\"message\" id=\"note_text#{note.id}\">#{simple_format(note.comment)}</span>"
      end
      
      
      output << "
        <div style=\"clear:both;margin-left:#{level*20}px;\">
        <div  style=\"float:left;width:100%\">  
          #{headertext}
              <div>
                <span class=\"sender\" style=\"float:right\">#{name} at #{note.created_at.strftime('%m/%d/%y %H:%M')}</span>
                <div class=\"header\"><span class=\"notetype\">#{note.type_label.titleize}:</span> #{note.subject}</div>
                              <div style=\"clear:both\"></div>
              </div>

          </div>
        
          <div name=\"hiddenNote\" id=\"note_body#{note.id}\" >
          <div class=\"messages\">
            <div>
              <div>
               #{notetext}"
      if session[:user].nil?
        output << "<div id=\"insert\"><a href=\"\/login?redirect=/visualize/#{@ontology.to_param}/?conceptid=#{@concept.id}#notes\">Reply</a></div>"
      else
        if @modal
          output << "<div id=\"insert\"><a href=\"#\"  onclick =\"document.getElementById('m_noteParent').value='#{note.id}';document.getElementById('m_note_subject#{key}').value='RE:#{note.subject}';jQuery('#modal_form').html(jQuery('#modal_comment').html());return false;\">Reply</a></div>"                
        else
          output << "<div id=\"insert\"><a href=\"#TB_inline?height=400&width=600&inlineId=commentForm\" class=\"thickbox\" onclick =\"document.getElementById('noteParent').value='#{note.id}';document.getElementById('note_subject#{key}').value='RE:#{note.subject}';\">Reply</a></div>"
        end
      end
      output << "</div>
            </div>
          </div>

          </div>
        </div>
        </div>"
      if(!note.children.nil? && note.children.size>0)
        draw_note_tree_leaves(note.children,level+1,output,key)
      end
    end
  end
  
  def draw_tree(root, id=nil,type="Menu")
    string =""  
    if id.nil?
      id = root.children.first.id
    end
    
    build_tree(root,nil,string,id)
    
    return string
  end
  
  def build_tree(node,parent,string,id)
    if parent.nil?
      draw_root = ''
    else
      draw_root = ""
    end
    
    unless node.children.nil? || node.children.length < 1
      for child in node.children
        icons = ""
        if child.note_icon
          icons << "<img src='/images/notes_icon.png'style='vertical-align:bottom;'height='15px' title='Term Has Margin Notes'>"
        end
        
        if child.map_icon
          icons << "<img src='/images/map_icon.png' style='vertical-align:bottom;' height='15px' title='Term Has Mappings'>"
        end
        
        active_style =""
        if child.id.eql?(id)
          active_style="class='active'"
        end

        open = ""
        if child.expanded
          open = "class='open'"
        end
        
        relation = child.relation_icon
        
        string << "<li #{open} #{draw_root}  id=\"#{child.id}\"><span #{active_style}> #{relation} #{child.label} #{icons}</span>"
        
        if child.child_size > 0 && !child.expanded
          string << "<ul class='ajax'><li id='#{child.id}'>{url:/ajax_concepts/#{child.ontology_id}/?conceptid=#{CGI.escape(child.id)}&callback=children}</li></ul>"
	    elsif child.expanded
    	  string << "<ul>"
    	  build_tree(child,"child",string,id)
    	  string << "</ul>"
        end
    		    
    	string <<"</li>"
      end
    end
  end
end
