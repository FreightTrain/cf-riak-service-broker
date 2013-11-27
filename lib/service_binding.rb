require "riak"

module RiakBroker
  class ServiceBinding
    def initialize(binding_id, service_id)
      @client = Riak::Client.new(nodes: [ { host: CONFIG["riak_hosts"].sample, http_port: 8098 } ])
      @service_bindings = @client.bucket("service_bindings")
      @binding_id = binding_id
      @service_id = service_id
    end

    def save
      object = @service_bindings.get_or_new(@binding_id)
      object.content_type = "application/json"
      object.data = { service_instance_id: @service_id }.to_json
      object.store({ returnbody: false })
    end

    def delete
      @service_bindings.delete(@binding_id)
    end

    def bound?
      @service_bindings.exist?(@binding_id)
    end

    def to_json
      {
        "credentials" => {
          "uris" => CONFIG["riak_hosts"].map { |host| "http://#{host}:8098/buckets/#{@service_id}" },
          "bucket" => @service_id,
          "port" => 8098,
          "hosts" => CONFIG["riak_hosts"]
        }
      }.to_json
    end
  end
end
