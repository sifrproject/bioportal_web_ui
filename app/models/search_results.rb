class SearchResults < Array
  attr_accessor :ontology_hit_counts
  attr_accessor :page_size
  attr_accessor :page_number
  attr_accessor :current_page_results
  attr_accessor :disaggregated_current_page_results
  attr_accessor :total_results
  attr_accessor :total_pages
  attr_accessor :results
  attr_accessor :total_hits

  # These are used in ranking search results
  attr_accessor :exact_results_by_ontology
  attr_accessor :non_exact_results_by_ontology
  attr_accessor :ranked_results
  attr_accessor :obsolete_results
  attr_accessor :ranked

  PREFERRED = "apreferredname"
  SYNONYM = "csynonym"

  def initialize(hash = nil, params = nil)
    self.ontology_hit_counts = {}
    self.exact_results_by_ontology = {}
    self.non_exact_results_by_ontology = ActiveSupport::OrderedHash.new
    self.obsolete_results = []
    self.ranked = false

    return if hash.nil?

    hash = hash["page"] if hash["page"]

    results = hash['contents']['searchResultList']
    unless results.nil? || results.length == 0
      results.values.each do |result|
        result['obsolete'] = result["isObsolete"].eql?("1")
        result["label_html"] = NodeWrapper.label_to_html(result["preferredName"], result['obsolete'])
      end
    end

    self.results = results.nil? || results.length == 0 ? Array.new : results.values
    self.ontology_hit_counts = Hash.new unless hash['contents']['ontologyHitList'].nil? || hash['contents']['ontologyHitList'].length == 0
    self.page_size = hash['pageSize'].to_i
    self.total_results = hash['numResultsTotal']
    self.page_number = hash['pageNum'].to_i
    self.current_page_results = hash['numResultsPage'].to_i
    self.total_pages = hash['numPages'].to_i
    self.total_hits = hash['contents']['numHitsTotal'].to_i

    # Populate hit list
    hash['contents']['ontologyHitList'].each do |hit|
      self.ontology_hit_counts[hit[1]['ontologyId'].to_i] = hit[1]
    end
  end

  def hash_for_serialization
    return {
      :ontology_hit_counts => self.ontology_hit_counts, :page_size => self.page_size,
      :page_number => self.page_number, :current_page_results => self.current_page_results,
      :disaggregated_current_page_results => self.disaggregated_current_page_results,
      :total_results => self.total_results, :total_pages => self.total_pages,
      :total_hits => self.total_hits, :results => self.results, :obsolete_results => self.obsolete_results
    }
  end

  # This will rank the results contained in this instance according to the OntologyRanker object
  # @param [Integer] How many of the results are exact, starting from the first item in the list.
  #                  You can get this from running a search with exact match and counting the results.
  def rank_results(exact_count)
    self.results.each_with_index do |result, index|
      self.sort_and_aggregate_result(result, index < exact_count)
    end

    # Disaggregate results
    preferred = []
    synonym = []
    self.exact_results_by_ontology.each do |ont_id, ont_results|
      preferred << ont_results[:preferred]
      synonym << ont_results[:synonym]

      # Deal with obsolete crap
      # Add results to an obsolete bucket if there are no other results for this ontology
      # Otherwise, stick it in additional results if there's already non-obsolete results for this ont
      unless ont_results[:obsolete].empty?
        if ont_results[:preferred].nil? && ont_results[:synonym].nil?
          # Make sure the ontology isn't in the non-exact match set
          if !self.non_exact_results_by_ontology[ont_id].nil?
            self.non_exact_results_by_ontology[ont_id]['additional_results_obsolete'] = ont_results[:obsolete]
          else
            # Add This to the obsolete bucket
            obsolete_result = ont_results[:obsolete].shift
            obsolete_result['additional_results'] = ont_results[:obsolete]
            self.obsolete_results << obsolete_result
            # We want to delete this from the normal search results
            self.exact_results_by_ontology.delete(ont_id)
          end
        else
          if !ont_results[:preferred].nil?
            ont_results[:preferred]['additional_results_obsolete'] = ont_results[:obsolete]
          else
            ont_results[:synonym]['additional_results_obsolete'] = ont_results[:obsolete]
          end
        end
      end
    end

    # Get rid of nil entries
    preferred.compact!
    synonym.compact!

    # Rank our result buckets
    preferred = OntologyRanker.rank(preferred, {:position => "ontologyId"})
    synonym = OntologyRanker.rank(synonym, {:position => "ontologyId"})

    # Put it all together
    self.ranked = true
    self.ranked_results = preferred.concat synonym.concat self.non_exact_results_by_ontology.values
  end

  def ranked?
    self.ranked
  end

  protected

  def sort_and_aggregate_result(result, exact = false)
    ont_id = result['ontologyId'].to_i
    self.exact_results_by_ontology[ont_id] = { :preferred => nil, :synonym => nil, :obsolete => [] } unless self.exact_results_by_ontology.key?(ont_id)
    ranked = self.exact_results_by_ontology[ont_id]

    # Obsolete results should never show up at the top, deal with them later
    if result['obsolete']
      ranked[:obsolete] << result
      return
    end

    if exact
      if result['recordType'].eql?(PREFERRED)
        if ranked[:preferred].nil?
          # This is the first preferred name exact match for this ontology
          # Add an array to store more results
          result['additional_results'] = []
          ranked[:preferred] = result
        else
          # We already have another match on preferred name (this shouldn't really happen, but to be safe)
          ranked[:preferred]['additional_results'] << result
        end
      elsif result['recordType'].eql?(SYNONYM)
        if !ranked[:preferred].nil?
          # We already have a better match for this ontology in the preferred name
          ranked[:preferred]['additional_results'] << result
        else
          # If we end up here, then the BEST result for this ontology is a match on a synonym,
          # which should rank lower than a preferred name so we put it in another bucket
          # Add an array to store more results
          result['additional_results'] = []
          ranked[:synonym] = result
        end
      else
        # Put matches into an existing ontology bucket if it exists
        # Exact matches made in anything other than preferred name or synonym rank lower
        if !ranked[:preferred].nil?
          # We already have a better match for this ontology in the preferred name
          ranked[:preferred]['additional_results'] << result
        elsif !ranked[:synonym].nil?
          ranked[:synonym]['additional_results'] << result
        else
          not_ranked = self.non_exact_results_by_ontology
          if not_ranked[ont_id].nil?
            not_ranked[ont_id] = result
          else
            not_ranked[ont_id]['additional_results'] = [] if not_ranked['additional_results'].nil?
            not_ranked[ont_id]['additional_results'] << result
          end
        end
      end
    else
      # Put matches into an existing ontology bucket if it exists
      # All non-exact matches get dumped in the lowest-ranking bucket
      if !ranked[:preferred].nil?
        # We already have a better match for this ontology in the preferred name
        ranked[:preferred]['additional_results'] << result
      elsif !ranked[:synonym].nil?
        ranked[:synonym]['additional_results'] << result
      else
        not_ranked = self.non_exact_results_by_ontology
        if not_ranked[ont_id].nil?
          not_ranked[ont_id] = result
        else
          not_ranked[ont_id]['additional_results'] = [] if not_ranked[ont_id]['additional_results'].nil?
          not_ranked[ont_id]['additional_results'] << result
        end
      end
    end
  end

end
