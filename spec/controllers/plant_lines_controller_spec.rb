require 'rails_helper'

RSpec.describe PlantLinesController do
  context '#index' do
    it 'returns search results and provides PL id in the first element' do
      plns = create_list(:plant_line, 2).map(&:plant_line_name)
      get :index, format: :json, search: { plant_line_name: plns[0][1..-2] }
      expect(response.content_type).to eq 'application/json'
      json = JSON.parse(response.body)
      expect(json.size).to eq 1
      expect(json[0]['plant_line_name']).to eq plns[0]
    end
  end
end
