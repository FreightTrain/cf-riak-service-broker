require "catalog"

module RiakBroker
  class CatalogsController < Sinatra::Base
    before do
      content_type "application/json"
    end

    get "/" do
      RiakBroker::Catalog.new.to_json
    end
  end
end
