require 'rails_helper'

RSpec.describe PlantTrial do
  describe '#filter' do
    it 'allow queries by project_descriptor' do
      pts = create_list(:plant_trial, 2)
      search = PlantTrial.filter(
          query: { project_descriptor: pts[0].project_descriptor }
      )
      expect(search.count).to eq 1
      expect(search.first).to eq pts[0]
    end

    it 'will only search by permitted params' do
      create(:plant_trial, plant_trial_name: 'ptn')
      search = PlantLine.filter(
          query: { plant_trial_name: 'ptn' }
      )
      expect(search.count).to eq 0
    end
  end

  describe '#pluck_columns' do
    it 'gets proper data table columns' do
      pt = create(:plant_trial)
      plucked = PlantTrial.pluck_columns
      expect(plucked.count).to eq 1
      expect(plucked[0]).
        to eq [
          pt.plant_trial_name,
          pt.plant_trial_description,
          pt.project_descriptor,
          pt.plant_population.name,
          pt.trial_year,
          pt.trial_location_site_name,
          pt.country.country_name,
          pt.institute_id,
          pt.id,
          pt.plant_scoring_units.count,
          pt.plant_population.id,
          pt.pubmed_id,
          pt.id
        ]
    end
  end

  describe '#table_data' do
    it 'orders plant trials by trial year' do
      ptyears = create_list(:plant_trial, 3).map(&:trial_year)
      table_data = PlantTrial.table_data
      expect(table_data.map{ |pt| pt[4] }).to eq ptyears.sort
    end
  end

  describe '.scoring_table_data' do
    it 'returns empty table when no TD ids are provided' do
      expect(subject.scoring_table_data([])).to eq []
    end

    context 'when there are PSUs inside the trial' do
      let(:plant_trial) { create(:plant_trial) }
      before(:each) { create_list(:plant_scoring_unit, 3, plant_trial: plant_trial) }

      it 'returns all plant scoring units' do
        scoring_table = plant_trial.scoring_table_data([])
        expect(scoring_table).
          to eq plant_trial.plant_scoring_units.map{ |psu| [psu.scoring_unit_name] }.sort
      end

      context 'and they have trait scores recorded' do
        let(:psus) { plant_trial.plant_scoring_units.order('scoring_unit_name asc') }
        let(:tds) { create_list(:trait_descriptor, 2) }
        before(:each) do
          create(:trait_score, trait_descriptor: tds[0], plant_scoring_unit: psus[0])
          create(:trait_score, trait_descriptor: tds[1], plant_scoring_unit: psus[0])
          create(:trait_score, trait_descriptor: tds[1], plant_scoring_unit: psus[2])
        end

        it 'provides scores in correct TD order' do
          scoring_table = plant_trial.scoring_table_data(tds.map(&:id))
          expect(scoring_table[0][1]).to eq tds[0].trait_scores[0].score_value
          expect(tds[1].trait_scores.map(&:score_value)).to include scoring_table[2][2]
        end

        it 'properly treats sparse data' do
          scoring_table = plant_trial.scoring_table_data(tds.map(&:id))
          expect(scoring_table[1][1]).to eq '-'
          expect(scoring_table[1][2]).to eq '-'
          expect(scoring_table[2][1]).to eq '-'
        end
      end
    end
  end

  it 'destroys plant scoring units when parent object is destroyed' do
    psu = create(:plant_scoring_unit)
    ptr = create(:plant_trial, plant_scoring_units: [psu])
    expect { ptr.destroy }.to change { PlantScoringUnit.count }.by(-1)
  end
end
