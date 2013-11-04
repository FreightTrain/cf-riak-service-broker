require "riak"

module RiakBroker
  class ServiceBindings < Sinatra::Base
    before do
      content_type "application/json"

      @client = Riak::Client.new(nodes: [ { host: CONFIG["riak_hosts"].sample, http_port: 8098 } ])
      @service_bindings = @client.bucket("service_bindings")
    end

    helpers do
      def create_binding(binding_id, service_id)
        object = @service_bindings.get_or_new(binding_id)
        object.content_type = "application/json"
        object.data = { service_instance_id: service_id }.to_json
        object.store({ returnbody: false })
      end

      def destroy_binding(binding_id)
        @service_bindings.delete(binding_id)
      end
      def already_bound?(binding_id)
        @service_bindings.exists?(binding_id)
      end
    end

    put "/:id" do
      binding_id  = params[:id]
      service_id  = JSON.parse(request.body.read)["service_instance_id"]

      unless already_bound?(binding_id)
        create_binding(binding_id, service_id)
        status 201

        {
          "credentials" => {
            "uris" => CONFIG["riak_hosts"].map { |host| "http://#{host}:8098/buckets/#{service_id}" },
            "bucket" => service_id,
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
