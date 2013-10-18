module RiakBroker
  class ServiceBindings < Sinatra::Base
    SERVICE_BINDINGS = { }

    before do
      content_type "application/json"
    end

    helpers do
      def create_binding(binding_id, service_id)
        SERVICE_BINDINGS[binding_id] = service_id
      end

      def destroy_binding(binding_id)
        SERVICE_BINDINGS.delete(binding_id)
      end
      def already_bound?(binding_id)
        SERVICE_BINDINGS.member?(binding_id)
      end
    end

    put "/:id" do
      binding_id = params[:id]
      service_id = JSON.parse(request.body.read)[:service_instance_id]

      unless already_bound?(binding_id)
        bucket_uuid = SecureRandom.uuid

        create_binding(binding_id, service_id)
        status 201

        {
          "credentials" => {
            "uris" => CONFIG["riak_hosts"].map { |host| "http://#{host}:8098/buckets/#{bucket_uuid}" },
            "bucket" => bucket_uuid,
            "port" => 8098,
            "hosts" => CONFIG["riak_hosts"]
          }
        }.to_json
      else
        status 409
      end
    end

    delete "/:id" do
      binding_id = params[:id]

      if already_bound?(binding_id)
        destroy_binding(binding_id)
        status 200
      else
        status 404
      end

      {}.to_json
    end
  end
end