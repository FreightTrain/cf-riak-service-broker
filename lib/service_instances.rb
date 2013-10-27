require "riak"

module RiakBroker
  class ServiceInstances < Sinatra::Base
    before do
      content_type "application/json"

      @client = Riak::Client.new(nodes: [ { host: CONFIG["riak_hosts"].sample, http_port: 8098 } ])
      @service_instances = @client.bucket("service_instances")
    end

    helpers do
      def set_backend(plan_id, bucket_uuid)
        bucket = @client.bucket(bucket_uuid)

        if plan_id == BITCASK_PLAN_ID
          bucket.properties = { "backend" => "bitcask_mult" }
        elsif plan_id == LEVELDB_PLAN_ID
          bucket.properties = { "backend" => "eleveldb_mult" }
        end
      end

      def add_service(service_id, plan_id)
        object = @service_instances.get_or_new(service_id)
        object.content_type = "application/json"
        object.data = { plan_id: plan_id }.to_json
        object.store({ returnbody: false })

        set_backend(plan_id, service_id)
      end

      def remove_service(service_id)
        @service_instances.delete(service_id)
      end

      def already_provisioned?(service_id)
        @service_instances.exist?(service_id)
      end
    end

    put "/:id" do
      service_id  = params[:id]
      plan_id     = JSON.parse(request.body.read)["plan_id"]

      unless already_provisioned?(service_id)
        add_service(service_id, plan_id)
        status 201

        {}.to_json
      else
        status 409
      end
    end

    delete "/:id" do
      service_id = params[:id]

      if already_provisioned?(service_id)
        remove_service(service_id)
        status 200
      else
        status 404
      end

      {}.to_json
    end
  end
end
