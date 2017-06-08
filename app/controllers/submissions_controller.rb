class SubmissionsController < ApplicationController

  layout 'ontology'
  before_action :authorize_and_redirect, :only=>[:edit, :update, :create, :new]

  # When getting "Add submission" form to display
  def new
    @ontology = LinkedData::Client::Models::Ontology.get(CGI.unescape(params[:ontology_id])) rescue nil
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first unless @ontology
    @submission = @ontology.explore.latest_submission
    @submission ||= LinkedData::Client::Models::OntologySubmission.new

    @ontologies_for_select = []
    LinkedData::Client::Models::Ontology.all.each do |onto|
      @ontologies_for_select << ["#{onto.name} (#{onto.acronym})", onto.id]
    end

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
  end

  # Called when form to "Add submission" is submitted
  def create
    # Make the contacts an array
    params[:submission][:contact] = params[:submission][:contact].values

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
    # Convert metadata that needs to be integer to int
    @metadata.map do |hash|
      if hash["enforce"].include?("integer")
        if !params[:submission][hash["attribute"]].nil? && !params[:submission][hash["attribute"]].eql?("")
          params[:submission][hash["attribute"].to_s.to_sym] = Integer(params[:submission][hash["attribute"].to_s.to_sym])
        end
      end
      if hash["enforce"].include?("boolean") && !params[:submission][hash["attribute"]].nil?
        if params[:submission][hash["attribute"]].eql?("true")
          params[:submission][hash["attribute"].to_s.to_sym] = true
        elsif params[:submission][hash["attribute"]].eql?("false")
          params[:submission][hash["attribute"].to_s.to_sym] = false
        else
          params[:submission][hash["attribute"].to_s.to_sym] = nil
        end
      end
    end

    @submission = LinkedData::Client::Models::OntologySubmission.new(values: params[:submission])
    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])
    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.save(cache_refresh_all: false)
    @submission_saved = @submission.save(cache_refresh_all: false)
    #@submission_saved = @submission.save(cache_refresh_all: false)

    if !@submission_saved || @submission_saved.errors
      @errors = response_errors(@submission_saved) # see application_controller::response_errors
      if @errors[:error].is_a?(Hash)
        if @errors[:error][:uploadFilePath] && @errors[:error][:uploadFilePath].first[:options]
          @masterFileOptions = @errors[:error][:uploadFilePath].first[:options]
          @errors = ["Please select a main ontology file from your uploaded zip"]
        else
          redirect_to "/ontologies/success/#{@ontology.acronym}"
        end
      end
      #Rails.logger.warn "ERRROR: #{@errors}"
      # TODO: ERROR HERE
      render "new"
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  # Called when form to "Edit submission" is submitted
  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first

    #submissions = @ontology.explore.submissions
    # Trying to get all submissions to get the latest. Useless and too long.
    #@submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first
    @submission = @ontology.explore.latest_submission

    @ontologies_for_select = []
    LinkedData::Client::Models::Ontology.all.each do |onto|
      @ontologies_for_select << ["#{onto.name} (#{onto.acronym})", onto.id]
    end

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
  end

  # When editing a submission (called when submit "Edit submission information" form)
  def update
    # Make the contacts an array
    params[:submission][:contact] = params[:submission][:contact].values if !params[:submission][:contact].nil?

    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])

    #submissions = @ontology.explore.submissions
    #@submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first
    @submission = @ontology.explore.latest_submission

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
    # Convert metadata that needs to be integer to int
    @metadata.map do |hash|
      if hash["enforce"].include?("integer")
        if !params[:submission][hash["attribute"]].nil? && !params[:submission][hash["attribute"]].eql?("")
          params[:submission][hash["attribute"].to_s.to_sym] = Integer(params[:submission][hash["attribute"].to_s.to_sym])
        end
      end
      if hash["enforce"].include?("boolean") && !params[:submission][hash["attribute"]].nil?
        if params[:submission][hash["attribute"]].eql?("true")
          params[:submission][hash["attribute"].to_s.to_sym] = true
        elsif params[:submission][hash["attribute"]].eql?("false")
          params[:submission][hash["attribute"].to_s.to_sym] = false
        else
          params[:submission][hash["attribute"].to_s.to_sym] = nil
        end
      end
    end

    @submission.update_from_params(params[:submission])
    #binding.pry

    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.save
    # TODO: really slow!:
    error_response = @submission.update(cache_refresh_all: false)

    if error_response
      @errors = response_errors(error_response) # see application_controller::response_errors
    else
      redirect_to "/ontologies/#{@ontology.acronym}"
    end
  end

end
