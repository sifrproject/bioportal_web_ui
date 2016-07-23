BioportalWebUi::Application.routes.draw do


  root :to => 'home#index'

  resources :notes, constraints: { id: /.+/ }

  resources :projects

  resources :users, :path => :accounts, :requirements => { :id => /.+/ }

  resources :reviews

  get '/mappings/new_external' => 'mappings#new_external'
  resources :mappings

  resources :margin_notes

  resources :concepts

  resources :ontologies do
    resources :submissions
  end

  resources :login

  resources :admin, :only => [:index]

  resources :subscriptions

  resources :recommender

  resources :recommender_v1

  resources :annotator

  resources :ncbo_annotatorplus

  resources :landscape

  resources :virtual_appliance

  get '' => 'home#index'

  # Top-level pages
  match '/feedback', to: 'home#feedback', via: [:get, :post]
  get '/account' => 'home#account'
  get '/help' => 'home#help'
  get '/robots.txt' => 'home#robots'
  get '/site_config' => 'home#site_config'
  get '/validate_ontology_file' => 'home#validate_ontology_file_show'
  match '/validate_ontology_file' => 'home#validate_ontology_file', via: [:get, :post]
  get '/layout_partial/:partial' => 'home#render_layout_partial'

  # Error pages
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # Analytics endpoint
  get '/analytics' => 'analytics#track'

  # Ontologies
  get '/ontologies/view/edit/:id' => 'ontologies#edit_view', :constraints => { :id => /[^\/?]+/ }
  get '/ontologies/view/new/:id' => 'ontologies#new_view'
  get '/ontologies/virtual/:ontology' => 'ontologies#virtual', :as => :ontology_virtual
  get '/ontologies/success/:id' => 'ontologies#submit_success'
  match '/ontologies/:acronym' => 'ontologies#update', via: [:get, :post]
  match '/ontologies/:acronym/submissions/:id' => 'submissions#update', via: [:get, :post]
  get '/ontologies/:ontology_id/submissions/new' => 'submissions#new', :ontology_id => /.+/
  match '/ontologies/:ontology_id/submissions' => 'submissions#create', :ontology_id => /.+/, via: [:get, :post]
  get '/ontologies/:acronym/classes/:purl_conceptid' => 'ontologies#show', :purl_conceptid => 'root'
  get '/ontologies/:acronym/:purl_conceptid' => 'ontologies#show'
  match '/ontologies/:acronym/submissions/:id/edit_metadata' => 'submissions#edit_metadata', via: [:get, :post]

  # Analytics
  get '/analytics/:action' => 'analytics#(?-mix:search_result_clicked|user_intention_surveys)'

  # New Notes
  get 'ontologies/:ontology/notes/:noteid' => 'notes#virtual_show', :as => :note_virtual, :noteid => /.+/
  get 'notes/ajax/single/:ontology' => 'notes#show_single', :as => :note_ajax_single
  get 'notes/ajax/single_list/:ontology' => 'notes#show_single_list', :as => :note_ajax_single_list

  # Ajax
  get '/ajax/' => 'ajax_proxy#get', :as => :ajax
  get '/ajax_concepts/:ontology/' => 'concepts#show', :constraints => { :id => /[^\/?]+/ }
  get '/ajax/class_details' => 'concepts#details'
  get '/ajax/mappings/get_concept_table' => 'mappings#get_concept_table'
  get '/ajax/json_ontology' => 'ajax_proxy#json_ontology'
  get '/ajax/json_class' => 'ajax_proxy#json_class'
  get '/ajax/jsonp' => 'ajax_proxy#jsonp'
  get '/ajax/recaptcha' => 'ajax_proxy#recaptcha'
  get '/ajax/loading_spinner' => 'ajax_proxy#loading_spinner'
  get '/ajax/notes/delete' => 'notes#destroy'
  get '/ajax/notes/concept_list' => 'notes#show_concept_list'
  get '/ajax/classes/label' => 'concepts#show_label'
  get '/ajax/classes/definition' => 'concepts#show_definition'
  get '/ajax/classes/treeview' => 'concepts#show_tree'
  get '/ajax/properties/tree' => 'concepts#property_tree'
  get '/ajax/biomixer' => 'concepts#biomixer'

  # User
  get '/logout' => 'login#destroy', :as => :logout
  get '/lost_pass' => 'login#lost_password'
  get '/reset_password' => 'login#reset_password'
  post '/accounts/:id/custom_ontologies' => 'users#custom_ontologies', :as => :custom_ontologies
  get '/login_as/:login_as' => 'login#login_as'
  post '/login/send_pass', to: 'login#send_pass'

  # Resource Index
  get '/res_details/:id' => 'resources#details', :as => :obr_details
  get '/resources/:ontology/:id' => 'resources#show', :as => :obr
  get '/respage/' => 'resources#page', :as => :obrpage
  get '/resource_index/resources' => 'resource_index#index'
  get '/resource_index/resources/:resource_id' => 'resource_index#index'
  match '/resource_index/:action', to: 'resource_index#(?-mix:element_annotations|results_paginate|resources_table)', via: [:get, :post]
  get '/resource_index/search_classes' => 'resource_index#search_classes'
  resources :resource_index

  # History
  get '/tab/remove/:ontology' => 'history#remove', :as => :remove_tab
  get '/tab/update/:ontology/:concept' => 'history#update', :as => :update_tab

  get 'jambalaya/:ontology/:id' => 'visual#jam', :as => :jam

  # Admin
  match '/admin/clearcache' => 'admin#clearcache', via: [:post]
  match '/admin/resetcache' => 'admin#resetcache', via: [:post]
  match '/admin/clear_goo_cache' => 'admin#clear_goo_cache', via: [:post]
  match '/admin/clear_http_cache' => 'admin#clear_http_cache', via: [:post]
  match '/admin/ontologies_report' => 'admin#ontologies_report', via: [:get]
  match '/admin/refresh_ontologies_report' => 'admin#refresh_ontologies_report', via: [:post]
  match '/admin/ontologies' => 'admin#delete_ontologies', via: [:delete]
  match '/admin/ontologies' => 'admin#process_ontologies', via: [:put]
  match '/admin/ontologies/:acronym/submissions/:id' => 'admin#delete_submission', via: [:delete]
  match '/admin/ontologies/:acronym/submissions' => 'admin#submissions', via: [:get]
  match '/admin/ontologies/:acronym/log' => 'admin#parse_log', via: [:get]

  ###########################################################################################################
  # Install the default route as the lowest priority.
  get '/:controller(/:action(/:id))'
  ###########################################################################################################

  #####
  ## OLD ROUTES
  ## All of these should redirect to new addresses in the controller method or using the redirect controller
  #####

  # Redirects from old URL locations
  get '/annotate' => 'redirect#index', :url => '/annotator'
  get '/all_resources' => 'redirect#index', :url => '/resources'
  get '/resources' => 'redirect#index', :url => '/resource_index'
  get '/visconcepts/:ontology/' => 'redirect#index', :url => '/visualize/'
  get '/ajax/terms/label' => 'redirect#index', :url => '/ajax/classes/label'
  get '/ajax/terms/definition' => 'redirect#index', :url => '/ajax/classes/definition'
  get '/ajax/terms/treeview' => 'redirect#index', :url => '/ajax/classes/treeview'
  get '/ajax/term_details/:ontology' => 'redirect#index', :url => '/ajax/class_details'
  get '/ajax/json_term' => 'redirect#index', :url => '/ajax/json_class'

  # Visualize
  get '/visualize/virtual/:ontology' => 'concepts#virtual', :as => :virtual_visualize, :constraints => { :id => /[^\/?]+/, :conceptid => /[^\/?]+/ }
  get '/visualize/virtual/:ontology/:id' => 'concepts#virtual', :as => :virtual_uri, :constraints => { :id => /[^\/?]+/ }
  get '/visualize/:ontology' => 'ontologies#visualize', :as => :visualize, :constraints => { :ontology => /[^\/?]+/ }
  get '/visualize/:ontology/:conceptid' => 'ontologies#visualize', :as => :uri, :constraints => { :ontology => /[^\/?]+/, :conceptid => /[^\/?]+/ }
  get '/visualize' => 'ontologies#visualize', :as => :visualize_concept, :constraints => { :ontology => /[^\/?]+/, :id => /[^\/?]+/, :ontologyid => /[^\/?]+/, :conceptid => /[^\/?]+/ }

  get '/flexviz/:ontologyid' => 'concepts#flexviz', :as => :flexviz, :constraints => { :ontologyid => /[^\/?]+/ }
  get '/exhibit/:ontology/:id' => 'concepts#exhibit'

  # Virtual
  get '/virtual/:ontology' => 'concepts#virtual', :as => :virtual_ont, :constraints => { :ontology => /[^\/?]+/ }
  get '/virtual/:ontology/:conceptid' => 'concepts#virtual', :as => :virtual, :constraints => { :ontology => /[^\/?]+/, :conceptid => /[^\/?]+/ }
end
