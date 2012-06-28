require 'open-uri'
require 'net/http'
require 'uri'
require 'cgi'

class AjaxProxyController < ApplicationController
  
  
  def get
    
    page = open(params[:url])
    content =  page.read
    render :text => content
    
  end

  def jsonp
  	if params[:apikey].nil? || params[:apikey].empty?
  		render_json '{ "error": "Must supply apikey" }'
  		return
  	end

  	if params[:path].nil? || params[:path].empty?
	  	render_json '{ "error": "Must supply path" }'
	  	return
  	end

  	url = URI.parse($REST_URL + params[:path])
  	url.port = $REST_PORT
  	full_path = (url.query.blank?) ? url.path : "#{url.path}?#{url.query}"
    full_path = full_path.include?("?") ? full_path + "&apikey=#{params[:apikey]}&userapikey=#{params[:userapikey]}" : full_path + "?apikey=#{params[:apikey]}&userapikey=#{params[:userapikey]}"
  	http = Net::HTTP.new(url.host, url.port)
  	headers = { "Accept" => "application/json" }
  	res = http.get(full_path, headers)
  	response = res.code.to_i == 404 ? '{ "error": "page not found" }' : res.body
    render_json response, {:status => res.code}
  end

  def json_term
    max_children = params[:max_children] ||= 0
    no_relations = params[:no_relations] ||= true
    render_json DataAccess.getLightNode(DataAccess.getOntology(params[:ontologyid]).id, params[:conceptid], max_children, no_relations).to_json
  end
  
  def loading_spinner
    render :partial => "loading_spinner"
  end

  private

  def render_json(json, options={})  
    callback, variable = params[:callback], params[:variable]  
  	response = begin  
  	  if callback && variable  
  	    "var #{variable} = #{json};\n#{callback}(#{variable});"  
  	  elsif variable  
  	    "var #{variable} = #{json};"  
  	  elsif callback  
  	    "#{callback}(#{json});"  
  	  else  
  	    json  
  	  end  
  	end  
    render({:content_type => :js, :text => response}.merge(options))
  end

end
