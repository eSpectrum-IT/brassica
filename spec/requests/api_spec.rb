require 'rails_helper'

RSpec.describe "API V1" do

  Brassica::Api.readable_models.each do |model_klass|
    describe model_klass do
      it_behaves_like "API-readable resource", model_klass
    end
  end

  Brassica::Api.writable_models.each do |model_klass|
    describe model_klass do
      it_behaves_like "API-writable resource", model_klass
    end
  end

end
