require 'rails_helper'

RSpec.describe MapPosition do
  describe '#filter' do
    it 'will query by permitted params' do
      mps = create_list(:map_position, 2)
      filtered = MapPosition.filter(
        query: { 'linkage_groups.id' => mps[0].linkage_group.id }
      )
      expect(filtered.count).to eq 1
      expect(filtered.first).to eq mps[0]
      filtered = MapPosition.filter(
        query: { 'population_loci.id' => mps[0].population_locus.id }
      )
      expect(filtered.count).to eq 1
      expect(filtered.first).to eq mps[0]
      filtered = MapPosition.filter(
        query: { 'id' => mps[0].id }
      )
      expect(filtered.count).to eq 1
      expect(filtered.first).to eq mps[0]
    end
  end

  describe '#table_data' do
    it 'gets proper data table columns' do
      mp = create(:map_position)
      create_list(:map_locus_hit, 2, map_position: mp)

      table_data = MapPosition.table_data
      expect(table_data.count).to eq 1
      expect(table_data[0]).to eq [
        mp.marker_assay.marker_assay_name,
        mp.map_position,
        mp.linkage_group.linkage_group_label,
        mp.population_locus.mapping_locus,
        2,
        mp.marker_assay.id,
        mp.linkage_group.id,
        mp.population_locus.id,
        mp.id
      ]
    end

    it 'retrieves published data only' do
      u = create(:user)
      mp1 = create(:map_position, user: u, published: true)
      mp2 = create(:map_position, user: u, published: false)

      mpd = MapPosition.table_data
      expect(mpd.count).to eq 1

      mpd = MapPosition.table_data(nil, u.id)
      expect(mpd.count).to eq 2
    end
  end
end
