require 'rails_helper'

RSpec.describe PlantLine do
  it 'dropped genus species subtaxa columns' do
    pl = create(:plant_line)
    expect{ pl.genus }.to raise_error NoMethodError
    expect{ pl.species }.to raise_error NoMethodError
    expect{ pl.subtaxa }.to raise_error NoMethodError
  end


  describe '#filter' do
    before(:each) do
      create(:plant_line, common_name: 'cn', plant_line_name: 'pln')
    end

    it 'searches plant_line_name' do
      create(:plant_line, plant_line_name: 'pln pln')
      search = PlantLine.filter(search: { plant_line_name: 'n pl' })
      expect(search.count).to eq 1
      expect(search.first.plant_line_name).to eq 'pln pln'
    end

    it 'will only search by permitted params' do
      search = PlantLine.filter(search: { common_name: 'n' })
      expect(search.count).to eq 0
    end

    it 'will not get all when no param permitted' do
      # NOTE: means - strong params should prevent passing {} to where
      expect(PlantLine.filter(query: { common_name: 'cn' })).to be_empty
      expect(PlantLine.filter(query: {})).to be_empty
    end

    it 'will only query by permitted params' do
      plname = ('a'..'z').to_a.shuffle[0,8].join
      pl = create(:plant_line, common_name: 'nc', plant_line_name: plname)
      search = PlantLine.filter(
        query: { common_name: 'cn', id: pl.id }
      )
      expect(search.count).to eq 1
      expect(search.first.plant_line_name).to eq plname
    end

    context 'when associated with plant population' do
      before(:each) do
        @pls = create_list(:plant_line, 3)
        @pp = create(:plant_population)
        create(:plant_population_list, plant_population: @pp, plant_line: @pls[0])
        create(:plant_population_list, plant_population: @pp, plant_line: @pls[1])
      end

      it 'supports querying by associated objects' do
        search = PlantLine.filter(
          query: {
            'plant_populations.id' => @pp.id
          }
        )
        expect(search.count).to eq 2
        expect(search.map(&:plant_line_name)).
          to match_array [@pls[0].plant_line_name, @pls[1].plant_line_name]
      end

      it 'supports multi-criteria queries' do
        search = PlantLine.filter(
          query: {
            'plant_populations.id' => @pp.id,
            id: @pls[1].id
          }
        )
        expect(search.count).to eq 1
        expect(search[0].plant_line_name).to eq @pls[1].plant_line_name
      end

      it 'supports both search and query criteria combined' do
        search = PlantLine.filter(
          query: {
            'plant_populations.id' => @pp.id
          },
          search: { 'plant_lines.plant_line_name' => @pls[1].plant_line_name[1..-2] }
        )
        expect(search.count).to eq 1
        expect(search[0].plant_line_name).to eq @pls[1].plant_line_name
      end
    end
  end

  describe '#pluckable' do
    it 'gets proper data table columns' do
      tt = create(:taxonomy_term, name: 'tt')
      pv = create(:plant_variety, plant_variety_name: 'pvn')
      de = Date.today
      pl = create(:plant_line,
                  plant_line_name: 'pln',
                  taxonomy_term: tt,
                  common_name: 'cn',
                  previous_line_name: 'ppln',
                  date_entered: de,
                  data_owned_by: 'dob',
                  organisation: 'o',
                  plant_variety: pv)

      plucked = PlantLine.pluck_columns
      expect(plucked.count).to eq 1
      expect(plucked[0]).
        to eq ['pln', 'tt', 'cn', 'pvn', 'ppln', de, 'dob', 'o', pv.id, pl.id]
    end
  end

  describe '#table_data' do
    it 'returns empty result when no plant lines found' do
      expect(PlantLine.table_data(plant_line_names: 1)).to be_empty
    end

    # it 'orders plant lines by plant line name' do
    #   plids = create_list(:plant_line, 3).map(&:id)
    #   td = PlantLine.table_data(query: { id: plids })
    #   expect(td.map(&:first)).to eq plids.sort
    # end
  end
end
