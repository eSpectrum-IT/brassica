class PlantTrial < ActiveRecord::Base
  include ActiveModel::Validations

  belongs_to :plant_population, counter_cache: true
  belongs_to :country
  belongs_to :user

  has_many :plant_scoring_units, dependent: :destroy
  has_many :processed_trait_datasets

  validates :plant_trial_name, presence: true, uniqueness: true
  validates :project_descriptor, presence: true
  validates :latitude, allow_blank: true, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90
  }
  validates :longitude, allow_blank: true, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180
  }

  validates_with PublicationValidator

  include Relatable
  include Filterable
  include Pluckable
  include Searchable
  include AttributeValues
  include Publishable

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.order(:trial_year).pluck_columns
  end

  # NOTE: this one works per-trial and provides data for so-called 'pivot' trial scoring table
  def scoring_table_data(trait_descriptor_ids)
    all_scores = TraitScore.
      includes(:plant_scoring_unit).
      includes(:trait_descriptor).
      where(plant_scoring_units: { plant_trial_id: self.id }).
      order('plant_scoring_units.scoring_unit_name asc, trait_descriptors.id asc').
      group_by(&:plant_scoring_unit)

    plant_scoring_units.order('scoring_unit_name asc').map do |unit|
      scores = all_scores[unit] || []
      [unit.scoring_unit_name] + trait_descriptor_ids.map do |td_id|
        ts = scores.detect{ |s| s.trait_descriptor_id == td_id.to_i}
        ts ? ts.score_value : '-'
      end
    end
  end

  def self.table_columns
    [
      'plant_trial_name',
      'plant_trial_description',
      'project_descriptor',
      'plant_populations.name',
      'trial_year',
      'trial_location_site_name',
      'countries.country_name',
      'institute_id',
      'id'
    ]
  end

  def self.count_columns
    [
      'plant_scoring_units_count'
    ]
  end

  def self.permitted_params
    [
      :fetch,
      query: params_for_filter(table_columns) +
        [
          'project_descriptor',
          'plant_populations.id',
          'id'
        ]
    ]
  end

  def self.ref_columns
    [
      'plant_population_id',
      'pubmed_id'
    ]
  end

  def self.json_options
    { include: [:country] }
  end

  include Annotable
end
