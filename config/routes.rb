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
  
  # The priority is based upon order of creation: first created -> highest priority.
  
  # You can have the root of your site routed by hooking up '' 
  map.connect '', :controller => "home"

  # Top-level pages
  map.connect '/feedback', :controller => 'home', :action => 'feedback'
  map.connect '/annotator', :controller => 'home', :action => 'annotate'
  map.connect '/resources', :controller => 'home', :action => 'all_resources'
  map.connect '/recommender', :controller => 'home', :action => 'recommender'
  map.connect '/account', :controller => 'home', :action => 'account'

  # Ontologies
  map.connect '/exhibit/:ontology/:id', :controller => 'concepts', :action=>'exhibit'
  map.connect '/ontologies/view/edit/:id', :controller => 'ontologies', :action => 'edit_view', :requirements => { :id => %r([^/?]+) }
  map.connect '/ontologies/view/new/:id', :controller => 'ontologies', :action => 'new_view'
  map.ontology_virtual '/ontologies/virtual/:ontology', :controller => 'ontologies', :action => 'virtual'
  
  # Mappings
  map.upload_mappings '/upload/mapping', :controller => 'mappings', :action=>'upload'
  map.process_mappings '/process/mapping', :controller => 'mappings', :action=>'process_mappings'
  map.mapping_count '/mappings/count/:ontology', :controller => 'mappings', :action => 'count'
  map.mapping '/mappings/service/:ontology/:id', :controller => 'mappings', :action => 'service'
  
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

  # Resource Index
  map.obr_details '/res_details/:id', :controller => 'resources', :action => 'details'
  map.obr '/resources/:ontology/:id', :controller => 'resources', :action => 'show'
  map.obrpage '/respage/', :controller => 'resources', :action => 'page'

  # Ajax
  map.ajax '/ajax/', :controller => 'ajax_proxy', :action => 'get'
  map.connect '/ajax_concepts/:ontology/', :controller => 'concepts', :action => 'show', :requirements => { :id => %r([^/?]+) }
  map.connect '/ajax/term_details/:ontology', :controller => 'concepts', :action => 'details'

  # User
  map.logout '/logout', :controller => 'login',:action => 'destroy'
  map.lost_pass '/lost_pass', :controller => 'login', :action => 'lost_password'
  
  # Visualize
  map.virtual_visualize '/visualize/virtual/:ontology', :controller => 'concepts', :action => 'virtual', :requirements => { :id => %r([^/?]+), :conceptid => %r([^/?]+) }
  map.virtual_uri '/visualize/virtual/:ontology/:id', :controller => 'concepts', :action => 'virtual', :requirements => { :id => %r([^/?]+) }
  map.visualize '/visualize/:ontology', :controller => 'ontologies', :action =>'visualize', :requirements => { :ontology => %r([^/?]+) }
  map.uri '/visualize/:ontology/:conceptid', :controller => 'concepts', :action => 'show', :requirements => { :ontology => %r([^/?]+), :conceptid => %r([^/?]+) }
  map.visualize_concept '/visualize', :controller => 'ontologies', :action => 'visualize', :requirements => { :ontology => %r([^/?]+), :id => %r([^/?]+),
                                                                                                              :ontologyid => %r([^/?]+), :conceptid => %r([^/?]+) }
  # Virtual
  map.virtual_ont '/virtual/:ontology', :controller => 'concepts', :action => 'virtual', :requirements => { :ontology => %r([^/?]+) }
  map.virtual '/virtual/:ontology/:id', :controller => 'concepts', :action => 'virtual', :requirements => { :ontology => %r([^/?]+), :id => %r([^/?]+) }
  
  # History
  map.remove_tab '/tab/remove/:ontology',:controller => 'history', :action => 'remove'
  map.update_tab '/tab/update/:ontology/:concept', :controller => 'history', :action=>'update'

  # Redirects from old URL locations
  map.connect '/annotate', :controller => 'redirect', :url=>'/annotator'
  map.connect '/all_resources', :controller =>'redirect', :url=>'/resources'
  map.connect '/visconcepts/:ontology/', :controller => 'redirect', :url=>'/visualize/'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  map.jam 'jambalaya/:ontology/:id', :controller => 'visual', :action => 'jam'
end
