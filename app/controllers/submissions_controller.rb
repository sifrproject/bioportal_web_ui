class SubmissionsController < ApplicationController

  layout 'ontology'
  before_action :authorize_and_redirect, :only=>[:edit, :update, :create, :new, :edit_metadata]

  def new
    @ontology = LinkedData::Client::Models::Ontology.get(CGI.unescape(params[:ontology_id])) rescue nil
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first unless @ontology
    @submission = @ontology.explore.latest_submission
    @submission ||= LinkedData::Client::Models::OntologySubmission.new
  end

  def create
    # Make the contacts an array
    params[:submission][:contact] = params[:submission][:contact].values
    # Update also hasOntologySyntax and hasFormalityLevel that are in select tag and cant be in params[:submission]
    params[:submission][:hasOntologySyntax] = params[:hasOntologySyntax] if params[:hasOntologySyntax] != "none"
    params[:submission][:hasFormalityLevel] = params[:hasFormalityLevel] if params[:hasFormalityLevel] != "none"

    @submission = LinkedData::Client::Models::OntologySubmission.new(values: params[:submission])
    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])
    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.update
    @submission_saved = @submission.save
    if !@submission_saved || @submission_saved.errors
      @errors = response_errors(@submission_saved) # see application_controller::response_errors
      if @errors[:error][:uploadFilePath] && @errors[:error][:uploadFilePath].first[:options]
        @masterFileOptions = @errors[:error][:uploadFilePath].first[:options]
        @errors = ["Please select a main ontology file from your uploaded zip"]
      else
        redirect_to "/ontologies/success/#{@ontology.acronym}"
      end
      render "new"
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    submissions = @ontology.explore.submissions
    @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first
  end

  # When editing a submission (called when submit "Edit submission information" form)
  def update
    # Make the contacts an array
    params[:submission][:contact] = params[:submission][:contact].values
    # Update also hasOntologySyntax and hasFormalityLevel that are in select tag and cant be in params[:submission]
    params[:submission][:hasOntologySyntax] = params[:hasOntologySyntax] if params[:hasOntologySyntax] != "none"
    params[:submission][:hasFormalityLevel] = params[:hasFormalityLevel] if params[:hasFormalityLevel] != "none"
    params[:submission][:hasLicense] = params[:submission][:hasLicense] if params[:submission][:hasLicense] != "none"

    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])
    submissions = @ontology.explore.submissions
    @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first

    # Add new language to naturalLanguage list
    natural_languages = @submission.naturalLanguage
    natural_languages = [] if natural_languages.nil?
    natural_languages.push(params[:submission][:naturalLanguage]) if params[:submission][:naturalLanguage] != "none"
    params[:submission][:naturalLanguage] = natural_languages

    @submission.update_from_params(params[:submission])
    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.update
    # TODO: really slow!
    error_response = @submission.update

    if error_response
      @errors = response_errors(error_response) # see application_controller::response_errors
    else
      redirect_to "/ontologies/#{@ontology.acronym}"
    end
  end

  ###
  # Controller of views/submission/edit_metadata.html.haml
  # When GET: retrieve metadata infos to display form
  # When POST: edit the submission metadata
  def edit_metadata

    if request.get?
      @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
      submissions = @ontology.explore.submissions
      @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first
      # Get the submission metadata from the REST API
      json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
      @metadata = json_metadata

    elsif request.post?
      @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
      submissions = @ontology.explore.submissions
      @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first

      puts "submission #{@submission.to_s}"

      # Get the list of extracted metadata
      json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
      extracted_metadata_array = []
      boolean_metadata_array = []
      int_metadata_array = []
      list_metadata_array = []
      json_metadata.each do |metadata|
        extracted_metadata_array << metadata["attribute"] if metadata["extracted"]
        boolean_metadata_array << metadata["attribute"] if metadata["enforce"].include?("boolean")
        int_metadata_array << metadata["attribute"] if metadata["enforce"].include?("integer")
        list_metadata_array << metadata["attribute"] if metadata["enforce"].include?("list")
      end

      # We need to initialize ontology param to get the update working...
      new_values = {"ontology"=>params[:acronym]}
      # For the moment just print in console and redirect to the same page
      params.each do |param|
        # param is an array with 2 values: [metadata attribute, metadata value]
        if extracted_metadata_array.include?(param[0])
          if param.length > 0 && !param[1].nil? && !param[1].eql?("")
            attr = param[0]
            attr_value = param[1]
            if list_metadata_array.include?(attr.to_s)
              if new_values[attr.to_s].nil?
                new_values[attr.to_s] = []
              end
            end

            if boolean_metadata_array.include?(attr.to_s)
              # If the attribute is a boolean
              if attr_value.to_s.downcase.eql?("true")
                new_values[attr.to_s] = true
              elsif attr_value.to_s.downcase.eql?("false")
                new_values[attr.to_s] = false
              end
            elsif int_metadata_array.include?(attr.to_s)
              # If the attribute is an integer
              if list_metadata_array.include?(attr.to_s)
                new_values[attr.to_s] << Integer(attr_value)
              else
                new_values[attr.to_s] = Integer(attr_value)
              end
            else
              if list_metadata_array.include?(attr.to_s)
                # If metadata is a list then we also get value from input 1 and 2 (see views/submissions/edit_metadata.html.haml)
                new_values[attr.to_s] << attr_value
                new_values[attr.to_s] << params[attr + "1"]
                new_values[attr.to_s] << params[attr + "2"]
              else
                new_values[attr.to_s] = attr_value
              end
            end
          end
        end
      end
      
      @submission.update_from_params(new_values)
      error_response = @submission.update

      if error_response
        @errors = response_errors(error_response) # see application_controller::response_errors
      else
        redirect_to "/ontologies/#{@ontology.acronym}"
      end
    end
  end


end
