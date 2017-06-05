require 'rails_helper'

RSpec.describe "BRAPI V1 studies calls" do
  let(:user) { create(:user) }
  let(:api_key) { user.api_key }
  let(:parsed_response) { JSON.parse(response.body) }


  context 'studies-search' do
    
    let!(:co) { create(:country, country_code: "CHN", country_name: "China") }
    
    let!(:pa) { create(:plant_accession, plant_accession: "hzau2003_TN077_a03") }
    let!(:pt) { create(:plant_trial, plant_trial_name: "hzau_2003_Wuhan_02", country: co) }
    let!(:psu) { create(:plant_scoring_unit, plant_accession: pa, plant_trial: pt) }

    let!(:pa2) { create(:plant_accession, plant_accession: "hzau2004_TN038_a02") }
    let!(:pt2) { create(:plant_trial, plant_trial_name: "hzau_2004_Weinan_03", country: co) }
    let!(:psu2) { create(:plant_scoring_unit, plant_accession: pa, plant_trial: pt2) }
  

    it 'studies-search requires at least one valid param to work' do
      
      headers = { 
        "CONTENT_TYPE" => "application/json"
      }
      
      post '/brapi/v1/studies-search', {
        wrongParameter: 'hzau_2003_Wuhan_02'
      }.to_json, headers
      expect(response.status).to eq 422
      
      post '/brapi/v1/studies-search', {
        studyNames: 'hzau_2003_Wuhan_02'
      }.to_json, headers
      expect(response.status).to eq 200
      
      post '/brapi/v1/studies-search', {
        germplasmDbIds: 'hzau2003_TN077_a03'
      }.to_json, headers
      expect(response.status).to eq 200
      
      post '/brapi/v1/studies-search', {
        germplasmDbIds: 'hzau2003_TN077_a03',
        studyNames: 'oneNotValid'
      }.to_json, headers
      expect(response.status).to eq 404   
    end
    
    it 'studies-search cheking query by germplasmDbId = hzau2003_TN077_a03 returns exactly 1 result' do
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        germplasmDbIds: 'hzau2003_TN077_a03'
      }.to_json, headers
      expect(response.status).to eq 200
      expect(parsed_response['result'].size).to eq 1
    end
    
    it 'studies-search cheking query by germplasmDbId = [hzau2003_TN077_a03, hzau2004_TN038_a02] returns exactly 2 results' do
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        germplasmDbIds: ['hzau2003_TN077_a03','hzau2004_TN038_a02']
      }.to_json, headers
      expect(response.status).to eq 200
      expect(parsed_response['result']['data'].size).to eq 2
    end
    
    it 'studies-search cheking query by germplasmDbId = [hzau2003_TN077_a03, hzau2004_TN038_a02] 
    and studyLocations: [China] returns exactly 2 results' do
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        germplasmDbIds: ['hzau2003_TN077_a03','hzau2004_TN038_a02'],
        studyLocations: ['China']
      }.to_json, headers
      expect(response.status).to eq 200
      expect(parsed_response['result']['data'].size).to eq 2
    end
  
    it 'studies-search cheking ordering: query by germplasmDbId = [hzau2003_TN077_a03, hzau2004_TN038_a02], 
    sortBy: name and sortOrder: asc,  returns first hzau2003_TN077_a03' do
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        germplasmDbIds: ['hzau2003_TN077_a03','hzau2004_TN038_a02'],
        sortBy: "name", 
        sortOrder: "asc"
      }.to_json, headers
      expect(response.status).to eq 200
      expect(parsed_response['result']['data'][0]['trialName']).to eq "hzau_2003_Wuhan_02"
    end
    
    it 'studies-search cheking ordering: query by germplasmDbId = [hzau2003_TN077_a03, hzau2004_TN038_a02], 
    sortBy: name and sortOrder: desc,  returns first hzau2004_TN038_a02' do
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        germplasmDbIds: ['hzau2003_TN077_a03','hzau2004_TN038_a02'],
        sortBy: "name", 
        sortOrder: "desc"
      }.to_json, headers
      expect(response.status).to eq 200
      expect(parsed_response['result']['data'][0]['trialName']).to eq "hzau_2004_Weinan_03"
    end
 
    it 'cheking format' do        
      headers = { 
        "CONTENT_TYPE" => "application/json",
        "X-BIP-Api-Key" => api_key.token 
      }
      post '/brapi/v1/studies-search', {
        studyNames: 'hzau_2003_Wuhan_02'
      }.to_json, headers
      expect(response.status).to eq 200
      expect(response.header['Content-Type']).to include 'application/json'
      result = parsed_response['result']
      expect(result['data'][0]['studyDbId']).to be_nil.or(be_a String)
      expect(result['data'][0]['name']).to be_nil.or(be_a String)
      expect(result['data'][0]['trialDbId']).to be_nil.or(be_a String)
      expect(result['data'][0]['trialName']).to be_nil.or(be_a String)
      expect(result['data'][0]['seasons']).to be_nil.or(be_a Array)
      expect(result['data'][0]['locationDbId']).to be_nil.or(be_a String)
      expect(result['data'][0]['locationName']).to be_nil.or(be_a String)
      expect(result['data'][0]['programName']).to be_nil.or(be_a String)
      
    end     
    
  end
  
  
  
  context 'studies-show' do
    let!(:co) { create(:country, country_code: "CHN", country_name: "China") }
    let!(:pa) { create(:plant_accession, plant_accession: "hzau2003_TN077_a03") }
    let!(:pt) { create(:plant_trial, plant_trial_name: "hzau_2003_Wuhan_02", country: co) }
    let!(:psu) { create(:plant_scoring_unit, plant_accession: pa, plant_trial: pt) }


    it 'show requires one valid param to work, id' do
      headers = { 
        "CONTENT_TYPE" => "application/json"
      }
      
      get '/brapi/v1/studies', {}, headers
      expect(response.status).to eq 422
      
      get '/brapi/v1/studies/'+pt.id.to_s, {}, headers
      expect(response.status).to eq 200
      
      get '/brapi/v1/studies/9999999', {}, headers
      expect(response.status).to eq 404
    end
    
    it 'cheking format' do        
      headers = { 
        "CONTENT_TYPE" => "application/json"
      }
      get '/brapi/v1/studies/'+pt.id.to_s, {}, headers
      expect(response.status).to eq 200
      expect(response.header['Content-Type']).to include 'application/json'
      
      results = parsed_response['result']
      
      result = results[0]
      
      expect(result['studyDbId']).to be_nil.or(be_a String)
      expect(result['name']).to be_nil.or(be_a String)
      expect(result['seasons']).to be_nil.or(be_a Array)
      expect(result['trialDbId']).to be_nil.or(be_a String)
      expect(result['trialName']).to be_nil.or(be_a String)
      expect(result['location']).to be_nil.or(be_a Array)
      if (result['location'].is_a? Array)
        location = result['location'][0]
        expect(location['locationDbId']).to be_nil.or(be_a String)
        expect(location['name']).to be_nil.or(be_a String)
        expect(location['countryCode']).to be_nil.or(be_a String)
        expect(location['countryName']).to be_nil.or(be_a String)
        expect(location['latitude']).to be_nil.or(be_a String)
        expect(location['longitude']).to be_nil.or(be_a String)
        expect(location['altitude']).to be_nil.or(be_a String)
        expect(location['additional_info']).to be_nil.or(be_a Hash)
        if (location['additional_info'].is_a? Hash)
          location_addinfo = location['additional_info']
          location_addinfo.each do |key, array|
            expect(location_addinfo['terrain']).to be_nil.or(be_a String)
            expect(location_addinfo['soil_type']).to be_nil.or(be_a String)
          end
        end
      else
        raise_error('Response has an empty location property')
      end
      
      expect(result['contacts']).to be_nil.or(be_a Array)
      if (result['contacts'].is_a? Array)
        contacts = result['contacts']
        contacts.each do |contact|
          expect(contact).to be_nil.or(be_a Hash)
          contact.keys.each do |key|
            if (['email','type'].include? key)
              expect(contact[key]).to be_nil.or(be_a String)
            else
              raise_error('Unexpected property name: contacts['+key+']')
            end
          end  
        end
        
      end
      
      expect(result['additionalInfo']).to be_nil.or(be_a Hash)
      if (result['additionalInfo'].is_a? Hash)
        addInfo = result['additionalInfo']
        addInfo.keys.each do |key|
          if (['studyDescription','dataProvenance','dataOwnedBy'].include? key)
            expect(addInfo[key]).to be_nil.or(be_a String)
          else
            raise_error('Unexpected property name: additionalInfo['+key+']')
          end
        end
      end
      
    end    
    
    
  end  

end
