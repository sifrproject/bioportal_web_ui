ActionController::Routing::Routes.draw do |map|
  map.resources :notes

  map.resources :projects

  map.resources :users, :as => :accounts

  map.resources :users

  map.resources :reviews

  map.resources :mappings

  map.resources :margin_notes

  map.resources :concepts

  map.resources :ontologies

  map.resources :login

  map.resources :admin

  map.resources :subscriptions

  map.resources :recommender

  map.resources :annotator

  map.resources :virtual_appliance

  # The priority is based upon order of creation: first created -> highest priority.

  # You can have the root of your site routed by hooking up ''
  map.connect '', :controller => "home"

  # Top-level pages
  map.connect '/feedback', :controller => 'home', :action => 'feedback'
  map.connect '/account', :controller => 'home', :action => 'account'
  map.connect '/help', :controller => 'home', :action => 'help'
  map.connect '/robots.txt', :controller => 'home', :action => 'robots'

  # Analytics endpoint
  map.connect '/analytics', :controller => 'analytics', :action => 'track'

  # Ontologies
  map.connect '/exhibit/:ontology/:id', :controller => 'concepts', :action=>'exhibit'
  map.connect '/ontologies/view/edit/:id', :controller => 'ontologies', :action => 'edit_view', :requirements => { :id => %r([^/?]+) }
  map.connect '/ontologies/view/new/:id', :controller => 'ontologies', :action => 'new_view'
  map.ontology_virtual '/ontologies/virtual/:ontology', :controller => 'ontologies', :action => 'virtual'
  map.connect '/ontologies/success/:id', :controller => 'ontologies', :action => 'submit_success'

  # Services
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Old Notes
  map.notes_ont 'notes/ont/:ontology/:id', :controller => 'margin_notes', :action => 'ont_service'
  map.notes_ver 'notes/ver/:ontology/:id', :controller => 'margin_notes', :action => 'ver_service'

  # New Notes
  map.notes_ontology 'ontologies/notes/virtual/:ontology', :controller => 'notes', :action => 'show_for_ontology'
  #map.note 'notes/:ontology', :controller => 'notes', :action => 'show'
  map.note_virtual 'notes/virtual/:ontology', :controller => 'notes', :action => 'virtual_show'
  map.note_ajax_single 'notes/ajax/single/:ontology', :controller => 'notes', :action => 'show_single'
  map.note_ajax_single_list 'notes/ajax/single_list/:ontology', :controller => 'notes', :action => 'show_single_list'

  # Ajax
  map.ajax '/ajax/', :controller => 'ajax_proxy', :action => 'get'
  map.connect '/ajax_concepts/:ontology/', :controller => 'concepts', :action => 'show', :requirements => { :id => %r([^/?]+) }
  map.connect '/ajax/term_details/:ontology', :controller => 'concepts', :action => 'details'
  map.connect "/ajax/mappings/get_concept_table", :controller => "mappings", :action => "get_concept_table"
  map.connect "/ajax/json_term", :controller => "ajax_proxy", :action => "json_term"
  map.connect "/ajax/jsonp", :controller => "ajax_proxy", :action => "jsonp"
  map.connect "/ajax/recaptcha", :controller => "ajax_proxy", :action => "recaptcha"
  map.connect "/ajax/loading_spinner", :controller => "ajax_proxy", :action => "loading_spinner"
  map.connect "/ajax/notes/delete", :controller => "notes", :action => "destroy"

  # User
  map.logout '/logout', :controller => 'login', :action => 'destroy'
  map.lost_pass '/lost_pass', :controller => 'login', :action => 'lost_password'
  map.custom_ontologies '/accounts/:id/custom_ontologies', :controller => 'users', :action => 'custom_ontologies'
  map.connect '/login_as/:login_as', :controller => 'login', :action => 'login_as'

  # Visualize
  map.virtual_visualize '/visualize/virtual/:ontology', :controller => 'concepts', :action => 'virtual', :requirements => { :id => %r([^/?]+), :conceptid => %r([^/?]+) }
  map.virtual_uri '/visualize/virtual/:ontology/:id', :controller => 'concepts', :action => 'virtual', :requirements => { :id => %r([^/?]+) }
  map.visualize '/visualize/:ontology', :controller => 'ontologies', :action =>'visualize', :requirements => { :ontology => %r([^/?]+) }
  map.uri '/visualize/:ontology/:conceptid', :controller => 'ontologies', :action => 'visualize', :requirements => { :ontology => %r([^/?]+), :conceptid => %r([^/?]+) }
  map.visualize_concept '/visualize', :controller => 'ontologies', :action => 'visualize', :requirements => { :ontology => %r([^/?]+), :id => %r([^/?]+),
                                                                                                              :ontologyid => %r([^/?]+), :conceptid => %r([^/?]+) }
  map.flexviz '/flexviz/:ontologyid', :controller => 'concepts', :action => 'flexviz', :requirements => { :ontologyid => %r([^/?]+) }

  # Virtual
  map.virtual_ont '/virtual/:ontology', :controller => 'concepts', :action => 'virtual', :requirements => { :ontology => %r([^/?]+) }
  map.virtual '/virtual/:ontology/:id', :controller => 'concepts', :action => 'virtual', :requirements => { :ontology => %r([^/?]+), :id => %r([^/?]+) }

  # Resource Index
  map.obr_details '/res_details/:id', :controller => 'resources', :action => 'details'
  map.obr '/resources/:ontology/:id', :controller => 'resources', :action => 'show'
  map.obrpage '/respage/', :controller => 'resources', :action => 'page'
  map.connect '/resource_index/resources', :controller => 'resource_index', :action => 'index'
  map.connect '/resource_index/resources/:resource_id', :controller => 'resource_index', :action => 'index'
  map.connect '/resource_index/:action', :controller => "resource_index", :action => /element_annotations|results_paginate|resources_table/
  map.resources :resource_index

  # History
  map.remove_tab '/tab/remove/:ontology',:controller => 'history', :action => 'remove'
  map.update_tab '/tab/update/:ontology/:concept', :controller => 'history', :action=>'update'

  # Redirects from old URL locations
  map.connect '/annotate', :controller => 'redirect', :url=>'/annotator'
  map.connect '/all_resources', :controller =>'redirect', :url=>'/resources'
  map.connect '/resources', :controller =>'redirect', :url=>'/resource_index'
  map.connect '/visconcepts/:ontology/', :controller => 'redirect', :url=>'/visualize/'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  map.jam 'jambalaya/:ontology/:id', :controller => 'visual', :action => 'jam'
end
