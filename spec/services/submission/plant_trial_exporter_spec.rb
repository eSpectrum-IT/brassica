require "rails_helper"

RSpec.describe Submission::PlantTrialExporter do
  let(:submission) { create(:finalized_submission, :trial, published: true) }
  let(:plant_trial) { submission.submitted_object }
  let(:plant_line) { create(:plant_line, plant_variety: create(:plant_variety)) }
  subject { described_class.new(submission) }

  describe "#documents" do
    it 'produces properly formatted all trial submission CSV documents' do
      psus = [
        create(:plant_scoring_unit,
               plant_trial: plant_trial,
               plant_accession: create(:plant_accession, plant_line: plant_line)),
        create(:plant_scoring_unit,
               plant_trial: plant_trial,
               plant_accession: create(:plant_accession, :with_variety)),
        create(:plant_scoring_unit,
               plant_trial: plant_trial,
               plant_accession: create(:plant_accession, plant_line: create(:plant_line)))
      ]
      tds = create_list(:trait_descriptor, 2).sort_by(&:id)
      ts1 = create(:trait_score, plant_scoring_unit: psus[0], trait_descriptor: tds[0])
      ts2 = create(:trait_score, plant_scoring_unit: psus[1], trait_descriptor: tds[0], technical_replicate_number: 2)
      ts3 = create(:trait_score, plant_scoring_unit: psus[1], trait_descriptor: tds[1])

      documents = subject.documents

      expect(documents.size).to eq 3
      expect(documents[:plant_trial].lines.size).to eq 2
      expect(documents[:plant_trial].lines[1].split(',')[0]).
        to eq plant_trial.plant_trial_name

      expect(documents[:trait_descriptors].lines.size).to eq 3
      expect(documents[:trait_descriptors].lines[1,2].map{ |l| l.split(',')[1] }).
        to match_array tds.map(&:trait_name)

      expect(documents[:trait_scoring].lines.size).to eq 4
      expect(documents[:trait_scoring].lines[0].strip.split(',')[13,3]).
        to eq ["#{tds[0].trait_name} rep1", "#{tds[0].trait_name} rep2", tds[1].trait_name]

      generated_scores = CSV.parse(documents[:trait_scoring]).map{ |row| row[13,3] }
      sample_ids = documents[:trait_scoring].lines[1,3].map{ |l| l.split(',')[0] }
      expect(sample_ids).to match_array psus.map(&:scoring_unit_name)
      expect(generated_scores[0]).to eq [tds[0].trait.name + ' rep1', tds[0].trait.name + ' rep2', tds[1].trait.name]
      expect(generated_scores[sample_ids.index(psus[0].scoring_unit_name) + 1]).
        to eq [ts1.score_value, '-', '-']
      expect(generated_scores[sample_ids.index(psus[1].scoring_unit_name) + 1]).
        to eq ['-', ts2.score_value, ts3.score_value]
      expect(generated_scores[sample_ids.index(psus[2].scoring_unit_name) + 1]).
        to eq ['-', '-', '-']

      expect(documents[:trait_scoring].lines[1,3].map{ |l| l.split(',')[3] }).
        to match_array [
          psus[0].plant_accession.plant_line.plant_variety.plant_variety_name,
          psus[1].plant_accession.plant_variety.plant_variety_name,
          '' # A case of PA -> PL with no PV in PL
        ]
    end

    it 'produces no documents for no-data cases' do
      documents = subject.documents
      expect(documents.size).to eq 1
    end

    it 'handles commas appropriately' do
      plant_trial.update_attribute(:plant_trial_name, 'With,comma')
      documents = subject.documents
      expect(documents.size).to eq 1
      expect(documents[:plant_trial].lines.size).to eq 2
      expect(documents[:plant_trial].lines[1]).
        to include '"With,comma"'
    end

    it 'uses localized column headers' do
      psu = create(:plant_scoring_unit, plant_trial: plant_trial)
      create(:trait_score, plant_scoring_unit: psu)

      documents = subject.documents

      expect(documents.size).to eq 3
      expect(documents[:trait_scoring].lines[0].split(',')[0,13]).
        to eq [
          I18n.t('tables.plant_scoring_units.scoring_unit_name'),
          I18n.t('tables.plant_accessions.plant_accession'),
          I18n.t('tables.plant_lines.plant_line_name'),
          I18n.t('tables.plant_varieties.plant_variety_name'),
          I18n.t('tables.plant_accessions.plant_accession_derivation'),
          I18n.t('tables.plant_accessions.originating_organisation'),
          I18n.t('tables.plant_accessions.year_produced'),
          I18n.t('tables.plant_accessions.date_harvested'),
          I18n.t('tables.plant_scoring_units.number_units_scored'),
          I18n.t('tables.plant_scoring_units.scoring_unit_sample_size'),
          I18n.t('tables.plant_scoring_units.scoring_unit_frame_size'),
          I18n.t('tables.design_factors.design_factors'),
          I18n.t('tables.plant_scoring_units.date_planted')
        ]

      expect(documents[:trait_descriptors].lines[0].strip.split(',')).
        to eq [
          I18n.t('tables.trait_descriptors.descriptor_label'),
          I18n.t('tables.traits.name'),
          I18n.t('tables.trait_descriptors.units_of_measurements'),
          I18n.t('tables.trait_descriptors.scoring_method'),
          I18n.t('tables.trait_descriptors.materials'),
          I18n.t('tables.plant_parts.plant_part')
        ]

      expect(documents[:plant_trial].lines[0].strip.split(',')).
        to eq [
          I18n.t('tables.plant_trials.plant_trial_name'),
          I18n.t('tables.plant_trials.plant_trial_description'),
          I18n.t('tables.plant_trials.project_descriptor'),
          I18n.t('tables.plant_populations.name'),
          I18n.t('tables.plant_trials.trial_year'),
          I18n.t('tables.plant_trials.trial_location_site_name'),
          I18n.t('tables.countries.country_name'),
          I18n.t('tables.plant_trials.institute_id')
        ]
    end
  end
end
