GenomeSuite::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  ##Navigation
  root :to => "help#index"
  match '/faq' => 'help#faq', :as  => :faq
  match '/about' => 'help#about', :as  => :about
  match '/help' => 'help#index', :as  => :help
  match '/contact' => 'help#contact', :as  => :contact
  match 'sitemap' => 'help#sitemap', :as => :sitemap
  match 'intro' => 'help#index', :as => :intro

  ## biosql - both namespaced and simple urls direct to namespaced controllers
  ##
  # biosql namespaced helper, simple url
  scope :module => 'biosql', :as => 'biosql' do
    resources :bioentries do
      collection do
        get 'metadata'
        get 'track_data'
      end
    end
    resources :locations
    resources :seqfeature_qualifier_values
  end
  # biosql simple helper, simple url
  scope :module => 'biosql' do
    resources :bioentries do
      collection do
        get 'metadata'
        get 'track_data'
      end
    end
    resources :locations
    resources :seqfeature_qualifier_values
  end
  # feature namespaced helper, simple url
  scope :module => 'biosql/feature', :as => 'biosql_feature' do
    resources :seqfeatures do
      get 'details', :on => :collection
      member do
        get 'toggle_favorite'
        get 'feature_counts'
      end
    end
    resources :genes do
      collection do
        get 'details'
        get :autocomplete_bioentry_id
      end
    end
  end
  # feature simple helper, simple url
  scope :module => 'biosql/feature' do
    resources :seqfeatures do
      get 'details', :on => :collection
      member do
        get 'toggle_favorite'
        get 'feature_counts'
      end
    end
    resources :genes do
      collection do
        get 'details'
        get :autocomplete_bioentry_id
      end
    end
  end

  # Genome
  resources :assemblies do
    get 'concordance_sets', :on => :collection
  end
  resources :genomes
  resources :transcriptomes
  ##Browser
  resources :track_layouts
  resources :tracks
  match "fetchers/metadata"
  match "fetchers/base_counts"
  match "fetchers/gene_models"
  match "fetchers/genome"  
  match "generic_feature/gene_models"
  match "protein_sequence/genome"
  match "reads/track_data"
  
  ##Experiments
  resources :assets, :only => [:show]
  resources :chip_chips do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  resources :chip_seqs do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  resources :experiments do
    get 'asset_details', :on => :collection
  end
  resources :re_seqs do
    get 'details', :on => :collection
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  resources :rna_seqs do
    get 'details', :on => :collection
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  resources :synthetics do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  resources :variants do
    collection do
      get 'details'
      get 'track_data'
      post 'reload_assets'
    end
    member do
      get 'initialize_experiment'
      get 'graphics'
    end
  end
  
  ##Tools
  resources :tools do
    collection do
      get 'details'
      get 'smooth'
      post 'smooth'
    end
  end
  match "expression/viewer"
  match "expression/results"
  match "expression/advanced_viewer"
  match "expression/advanced_results"
  resources :blasts do
    post 'new', :on => :member
  end
  resources :blast_runs
  resources :blast_reports do
    get 'alignment', :on => :member
  end
  
  ##Accounts
  devise_for :users
  resources :user, :controller => 'user' do
    member do
      post 'update_track_node'
      get 'profile'
    end
  end
  resources :groups do
    get :autocomplete_user_login, :on => :collection
    get :remove_user, :on => :member
  end

  # Administrator
  namespace :admin do
    root :controller => "jobs", :action => "index"
    resources :users
    resources :roles
    resources :jobs do
      member do
        post 'retry'
      end
    end
    resources :blast_databases do
      get :autocomplete_taxon_name_taxon_id, :on => :collection
      get :autocomplete_group_id, :on => :collection
    end
    resources :blast_runs
    resources :ontologies
    resources :terms
  end
  
end
