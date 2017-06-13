class Brapi::V1::StudiesController < Brapi::BaseController


  attr_accessor :request_params, :user

  rescue_from ActionController::ParameterMissing do |exception|
    render json: { errors: { attribute: exception.param, message: exception.message } }, status: 422
  end


  def search
    # accepted params: studyType, studyNames, studyLocations, programNames, germplasmDbIds
    # observationVariableDbIds, active, sortBy, sortOrder
    # pageSize, page

    # At least one implemented search parameter should be provided
    if !params['studyType'].present? && !params['studyNames'].present? && !params['studyLocations'].present? && 
        !params['programNames'].present? && !params['germplasmDbIds'].present? && 
        !params['observationVariableDbIds'].present? && !params['active'].present? && 
        !params['sortBy'].present? && !params['sortOrder'].present?
      raise ActionController::ParameterMissing.new('Not Found')
    else 
      studies_queries = Brapi::V1::StudiesQueries.instance
      page = get_page
      page_size = get_page_size 
          
      result_object = studies_queries.studies_search_query(
        params['studyType'], params['studyNames'], params['studyLocations'], params['programNames'],
        params['germplasmDbIds'], params['observationVariableDbIds'], params['active'],
        params['sortBy'], params['sortOrder'], page, page_size, false)
      
      records = result_object.values
     
      if records.nil? || records.size ==0
        render json: { reason: 'Resource not found' }, status: :not_found  # 404
      else
        json_result_array = []
        
        # any programmatic data manipulation can be done here
        result_object.each do |row|
          row[:seasons] = [row["seasons"]]
          
          # To check authentication and ownership when ORCID is supported by BrAPI
          # We currently only retrieve public records. This is already done at query level
          #if (!row[:user_id] || row[:published] )
          json_result_array << row
          #end
        end
        
        # pagination data returned
        
        result_count_object = studies_queries.studies_search_query(
          params['studyType'], params['studyNames'], params['studyLocations'], params['programNames'],
          params['germplasmDbIds'], params['observationVariableDbIds'], params['active'],
          params['sortBy'], params['sortOrder'], page, page_size, true)
        
        total_count = result_count_object.values.first[0].to_i
        total_pages = (total_count/page_size.to_f).ceil
        
        json_response = { 
          metadata: json_metadata(page_size, page, total_count, total_pages),
          result: {
            data: json_result_array
          }
        }
       
        render json: json_response, except: ["id", "user_id", "created_at", "updated_at", "total_entries_count"]
      end
    
    end
  end


  def show
    # accepted params: id

    if !params['id'].present? 
      raise ActionController::ParameterMissing.new('Not Found')
    else 
      studies_queries = Brapi::V1::StudiesQueries.instance
          
      result_object = studies_queries.studies_get_query(params['id'])
      
      records = result_object.values
     
      if records.nil? || records.size == 0
        render json: { reason: 'Resource not found' }, status: :not_found  # 404
      else
        json_result_array = []
        
        # any programmatic data manipulation can be done here
        result_object.each do |row|          
          row[:seasons] = [row["seasons"]]
          
          location_hash = row.extract!("locationDbId", "name", "countryCode", "countryName", "latitude", 
            "longitude", "altitude")
          location_hash[:additional_info] = row.extract!("terrain", "soil_type")
          row[:location] = [location_hash]
          
          contact1_hash = row.extract!("email")
          contact2_hash = {email: row["entered_by_whom_email"], type: "data_introducer"}
          row.delete("entered_by_whom_email")
          row[:contacts] = [contact1_hash, contact2_hash]
          
          additional_info_hash = row.extract!("studyDescription", "dataProvenance", "dataOwnedBy")
          row[:additionalInfo] = additional_info_hash
          
          # To check authentication and ownership when ORCID is supported by BrAPI
          # We currently only retrieve public records. This is already done at query level
          #if (!row[:user_id] || row[:published] )
          json_result_array << row
          #end
        end
        
        json_response = { 
          metadata: json_metadata(0, 0, records.size, 0),
          result: json_result_array
        }
       
        render json: json_response, except: ["id", "user_id", "created_at", "updated_at", "total_entries_count"]
      end
    
    end
    
  end


  private

  
  def get_page
    return (params[:page].to_i != 0)?params[:page].to_i : 1
  end
  
  def get_page_size
    return (params[:pageSize].to_i != 0)?params[:pageSize].to_i : 1000 
  end
  
  def json_metadata(page_size, current_page, total_count, total_pages)
    json_metadata = {
      status: [],
      datafiles: [],
      pagination: {
        pageSize: page_size, # like 'per_page' in CollectionDecorator
        currentPage: current_page, # like old 'page' in CollectionDecorator
        totalCount: total_count, # like 'total_count'  in CollectionDecorator
        totalPages: total_pages 
      }
    }
  end
  

end