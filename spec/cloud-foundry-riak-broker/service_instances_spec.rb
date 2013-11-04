require "spec_helper"

describe RiakBroker::ServiceInstancesController do
  let(:service_uuid) { SecureRandom.uuid }
  let(:plan_uuid) { SecureRandom.uuid }
  let(:binding_uuid) { SecureRandom.uuid }

  def app
    @app ||= RiakBroker::ServiceInstancesController
  end

  context "PUT /:id" do
    before(:each) do
      RiakBroker::ServiceInstance.any_instance.stub(:provisioned?).and_return(false)
      RiakBroker::ServiceInstance.any_instance.stub(:save)

      put(
        "/#{service_uuid}",
        { "plan_id" => plan_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
    end

    it "should include a 201 status code" do
      last_response.status.should == 201
    end

    it "should include an empty JSON object" do
      last_response.body.should be_json_eql("{}")
    end

    it "should include a 409 status code" do
      RiakBroker::ServiceInstance.any_instance.stub(:provisioned?).and_return(true)
      put(
        "/#{service_uuid}",
        { "plan_id" => plan_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
      last_response.status.should == 409
    end
  end

  context "DELETE /:id" do
    before(:each) do
      RiakBroker::ServiceInstance.any_instance.stub(:provisioned?).and_return(true)
      RiakBroker::ServiceInstance.any_instance.stub(:delete)

      put(
        "/#{service_uuid}",
        { "plan_id" => plan_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
      delete "/#{service_uuid}"
    end

    it "should include a 200 status code" do
      last_response.status.should == 200
    end

    it "should include a 404 status code" do
      RiakBroker::ServiceInstance.any_instance.stub(:provisioned?).and_return(false)

      delete "/#{SecureRandom.uuid}"
      last_response.status.should == 404
    end

    it "should include an empty JSON object" do
      last_response.body.should be_json_eql("{}")
    end
  end

  context "PUT /:instance_id/service_bindings/:id" do
    before(:each) do
      RiakBroker::ServiceBinding.any_instance.stub(:bound?).and_return(false)
      RiakBroker::ServiceBinding.any_instance.stub(:save)

      put(
        "/#{service_uuid}/service_bindings/#{binding_uuid}",
        { "service_instance_id" => service_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
    end

    it "should include a credentials listing" do
      last_response.body.should have_json_path("credentials")
    end

    it "should include URIs" do
      last_response.body.should have_json_path("credentials/uris")
    end

    it "should include hosts" do
      last_response.body.should have_json_path("credentials/hosts")
    end

    it "should include a port" do
      last_response.body.should have_json_path("credentials/port")
    end

    it "should include a unique bucket name" do
      last_response.body.should have_json_path("credentials/bucket")
    end

    it "should include a 409 status code" do
      RiakBroker::ServiceBinding.any_instance.stub(:bound?).and_return(true)

      put(
        "/#{service_uuid}/service_bindings/#{binding_uuid}",
        { "service_instance_id" => service_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )

      last_response.status.should == 409
    end
  end

  context "DELETE /:instance_id/service_bindings/:id" do
    before(:each) do
      RiakBroker::ServiceBinding.any_instance.stub(:bound?).and_return(true)
      RiakBroker::ServiceBinding.any_instance.stub(:delete)

      put(
        "/#{service_uuid}/service_bindings/#{binding_uuid}",
        { "service_instance_id" => service_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
      delete "/#{service_uuid}/service_bindings/#{binding_uuid}"
    end

    it "should include a 200 status code" do
      last_response.status.should == 200
    end

    it "should include a 404 status code" do
      RiakBroker::ServiceBinding.any_instance.stub(:bound?).and_return(false)

      delete "/#{service_uuid}/service_bindings/#{SecureRandom.uuid}"
      last_response.status.should == 404
    end

    it "should include an empty JSON object" do
      last_response.body.should be_json_eql("{}")
    end
  end
end
