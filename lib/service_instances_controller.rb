module RiakBroker
  class ServiceInstancesController < Sinatra::Base

    Riak.disable_list_keys_warnings = true
    I18n.enforce_available_locales = false

    before do
      content_type "application/json"
    end

    put "/:id" do
      service_id = params[:id]
      plan_id = JSON.parse(request.body.read)["plan_id"]

      service_instance = RiakBroker::ServiceInstance.new(service_id)

      halt 409 if service_instance.provisioned?
      halt 503 if service_instance.limit_exceeded?
      service_instance.save(plan_id)
      status 201
      {}.to_json
    end

    delete "/:id" do
      service_id = params[:id]

      service_instance = RiakBroker::ServiceInstance.new(service_id)

      if service_instance.provisioned?
        service_instance.delete
        status 200
      else
        status 404
      end

      {}.to_json
    end

    put "/:instance_id/service_bindings/:id" do
      service_id  = params[:instance_id]
      binding_id  = params[:id]

      service_binding = RiakBroker::ServiceBinding.new(binding_id, service_id)

      unless service_binding.bound?
        service_binding.save
        status 201

        service_binding.to_json
      else
        status 409
      end
    end

    delete "/:instance_id/service_bindings/:id" do
      service_id  = params[:instance_id]
      binding_id = params[:id]

      service_binding = RiakBroker::ServiceBinding.new(binding_id, service_id)

      if service_binding.bound?
        service_binding.delete
        status 200
      else
        status 404
      end

      {}.to_json
    end
  end
end
