require "riak"

module RiakBroker
  class ServiceInstance
    def initialize(service_id)
      @client = Riak::Client.new(nodes: [ { host: CONFIG["riak_hosts"].sample, http_port: 8098 } ])
      @service_instances = @client.bucket("service_instances")
      @service_id = service_id
    end

    def save(plan_id)
      object = @service_instances.get_or_new(@service_id)
      object.content_type = "application/json"
      object.data = { plan_id: plan_id }.to_json
      object.store({ returnbody: false })

      set_backend(plan_id)
    end

    def delete
      @service_instances.delete(@service_id)
    end

    def provisioned?
      @service_instances.exist?(@service_id)
    end

    def limit_exceeded?
      instance_limit && @service_instances.keys.size >= instance_limit.to_i
    end

    def instance_limit
      CONFIG['service_instance_limit']
    end

    private

    def set_backend(plan_id)
      bucket = @client.bucket(@service_id)

      if plan_id == BITCASK_PLAN_ID
        bucket.properties = { "backend" => "bitcask_mult" }
      elsif plan_id == LEVELDB_PLAN_ID
        bucket.properties = { "backend" => "eleveldb_mult" }
      end
    end
  end
end
