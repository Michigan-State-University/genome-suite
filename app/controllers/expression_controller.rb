class ExpressionController < ApplicationController
  before_filter :setup_form_data, :only => [:viewer]
  before_filter :setup_results_data, :only => [:results,:advanced_results,:parallel_graph]
  # display the selection form for samples and matrix or ratio results
  def viewer
    params[:fmt]||='viewer'
  end
   
  # display the matrix results
  def results
    begin
    # Lookup the Experiments - Intersect with accessible experiments
    @experiments = (params[:experiments]||[]).map{|e|Experiment.find(e)}.compact & @experiment_options
    respond_to do |format|
      # Base html query
      format.html{
        @search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@experiments,params) do |s|
          s.paginate(:page => params[:page], :per_page => params[:per_page])
        end
        # Check for seqfeature update
        check_xhr
      }
      format.csv{
        # Use the initial query to get total pages
        search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@experiments,params) do |s|
          s.paginate(:page => 1, :per_page => 1000)
        end
        current_page = 1
        total_pages = search.hits.total_pages
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          # Add the header
          out.write (['Locus','Definition']+@blast_runs.map(&:name)+@experiments.map(&:name)+['Sum']).to_csv
          # Write the first page
          out.write Biosql::Feature::Seqfeature.matrix_search_to_csv(search,@experiments,@blast_runs,params)
          # Write any additional pages
          while(current_page < total_pages)
            current_page+=1
            search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@experiments,params) do |s|
              s.paginate(:page => current_page, :per_page => 1000)
            end
            out.write Biosql::Feature::Seqfeature.matrix_search_to_csv(search,@experiments,@blast_runs,params)
          end
        }
      }
    end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'
      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started, or not the correct version? 'rake sunspot:solr:start'")
      @search = nil
      @experiments||=[]
    end
  end
  
  # display the ratio results
  def advanced_results
    begin
    # Lookup the Experiments and intersect with accessible experiments
    @a_experiments = params[:a_experiments].map{|e|Experiment.find(e)}.compact &  @experiment_options
    @b_experiments = params[:b_experiments].map{|e|Experiment.find(e)}.compact &  @experiment_options
    respond_to do |format|
      # Base html query
      format.html{
        @search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_experiments,@b_experiments,params) do |s|
          s.paginate(:page => params[:page], :per_page => params[:per_page])
        end
        # Check for seqfeature update
        check_xhr
      }
      # Streaming csv render
      format.csv{
        # Use the initial query to get total pages
        search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_experiments,@b_experiments,params) do |s|
          s.paginate(:page => 1, :per_page => 1000)
        end
        current_page = 1
        total_pages = search.hits.total_pages
        # use custom proc for response body
        # NOTE: change to streaming Enumerator for rails 3.2
        self.response_body = proc {|resp, out|
          # Add the header
          out.write (['Locus','Definition']+@blast_runs.map(&:name)+['Set A','Set B','A / B']).to_csv
          # Write the first page
          out.write Biosql::Feature::Seqfeature.ratio_search_to_csv(search,@a_experiments,@b_experiments,@blast_runs,params)
          # Write any additional pages
          while(current_page < total_pages)
            current_page+=1
            search = Biosql::Feature::Seqfeature.ratio_search(current_ability,@assembly.id,@type_term_id,@a_experiments,@b_experiments,params) do |s|
              s.paginate(:page => current_page, :per_page => 1000)
            end
            out.write Biosql::Feature::Seqfeature.ratio_search_to_csv(search,@a_experiments,@b_experiments,@blast_runs,params)
          end
        }
      }
    end
    rescue => e
      flash.now[:warning]='Whoops! Looks like this search isn\'t working. <br/> The administrator has been notified.'
      server_error(e,"Error performing search in tools/expression_results. \n\tPerhaps Sunspot is not started? 'rake sunspot:solr:start'")
      @search = nil
      @a_experiments||=[]
      @b_experiments||=[]
    end
  end
  
  def parallel_graph
    # Lookup the Experiments - Intersect with accessible experiments
    @experiments = params[:experiments].map{|e|Experiment.find(e)}.compact & @experiment_options
    @search = Biosql::Feature::Seqfeature.matrix_search(current_ability,@assembly.id,@type_term_id,@experiments,params) do |s|
      s.paginate(:page => params[:page], :per_page => 100)
    end
  end
  
  private
  # Sets assembly and feature type options for viewer form
  def setup_form_data
    # lookup all accessible taxon versions
    # Collect from accessible experiments to avoid displaying accessible sequence that has rna_seq but none accessible to the current user
    @assemblies = RnaSeq.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).order("taxon_name.name ASC").map(&:assembly).uniq || []
    # set the current assembly
    @assembly = @assemblies.find{|t_version| t_version.try(:id)==params[:assembly_id].to_i} || @assemblies.first
    # lookup the extra taxon data
    get_assembly_data if @assembly
    # get all expression features
    @feature_types = Biosql::Feature::Seqfeature.facet_types_with_expression_and_assembly_id(@assembly.id) if @assembly
    # setup default type_term if not supplied in params
    @type_term_id ||=@feature_types.facet(:type_term_id).rows.first.try(:value) if @feature_types
  end
  # Sets assembly, experiments and selection dropdowns for search results displays
  def setup_results_data
    # lookup taxon versionand redirect if none available
    @assembly = Assembly.accessible_by(current_ability).where(:id => params[:assembly_id]).first
    unless @assembly
      redirect_to expression_viewer_path
      return
    end
    # lookup the extra taxon data
    get_assembly_data
    # set default search parameters
    setup_defaults
  end
  #returns rna_seq,features with expression,and blast_runs associated with this taxon version
  def get_assembly_data
    begin
      # set the type_term_id
      @type_term_id = params[:type_term_id]
      # get the experiments
      @experiment_options = @assembly.rna_seqs.accessible_by(current_ability).order('experiments.name')
      # find any blasts
      @blast_runs = @assembly.blast_runs
    rescue => e
      logger.info "\n***Error: Could not build version and features in expression controller:\n#{e}\n"
      server_error(e,"Could not build version and features")
    end
  end
  # defaults
  def setup_defaults
    # search params
    params[:per_page]||=50
    params[:definition_type]||= @assembly.default_feature_definition
    params[:value_type]||='normalized_counts'
    @value_options = {'Normalized Counts' => 'normalized_counts', 'Raw Counts' => 'counts'}
    # Setup the quick select box
    @group_select_options = {
      #'Combined' => [['Description','description'],['Everything','full_description']],
      "Blast Reports" => @blast_runs.collect{|run|[run.name,"blast_#{run.id}"]},
      'Annotation' => [['Description','description']]
    }
    # TODO: Replace with Faceted search for speed and numbered results, would require term and/or ontology index
    # Get all the annotations in use by an assembly feature.
    anno_terms = Biosql::Term.select('distinct term.term_id, term.name')
      .joins(:ontology,[:qualifiers => [:seqfeature => :bioentry]])
      .where{ bioentry.assembly_id == my{@assembly.id} }
      .where{ ontology_id == Biosql::Term.ano_tag_ont_id }
      .where{lower(term.name).in(['ec_number','function','gene','gene_synonym','product','protein_id','transcript_id','locus_tag'])}
    # Add to the list
    @group_select_options['Annotation'].concat anno_terms.map{|term| [term.name.humanize,term.name]}
    # Get all the custom terms in use
    custom_terms = Biosql::Term.select('distinct term.term_id, term.name, term.ontology_id')
      .joins(:ontology,[:qualifiers => [:seqfeature => :bioentry]])
      .where{ seqfeature.type_term_id == my{@type_term_id} }
      .where{ bioentry.assembly_id == my{@assembly.id} }
      .where{ ontology_id.in(Biosql::Term.custom_ontologies) }
    custom_terms.each do |term|
      @group_select_options[term.ontology.name] ||= []
      @group_select_options[term.ontology.name] << [term.name, "term_#{term.id}"]
    end
  end
  
  # Check XHR
  # we are assuming all xhr search results with a seqfeature_id are requests for an in place update
  # if there is a result, only render the first
  def check_xhr
    if params[:seqfeature_id] and request.xhr?
      if @search.total == 0
        render :text => 'not found..'
      else
        @search.each_hit_with_result do |hit,feature|
          render :partial => 'hit_definition', :locals => {:hit => hit, :feature => feature, :definition_type => params[:definition_type], :multi_definition_type => params[:multi_definition_type]}
          break
        end
      end
      return
    end
  end

end