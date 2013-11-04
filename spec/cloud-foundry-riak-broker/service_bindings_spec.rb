require "spec_helper"

describe RiakBroker::ServiceBindings do
  let(:binding_uuid) { SecureRandom.uuid }
  let(:service_instance_uuid) { SecureRandom.uuid }
  let(:bucket_uuid) { SecureRandom.uuid }

  def app
    @app ||= RiakBroker::ServiceBindings
  end

  context "PUT /:id" do
    before(:each) do
      app.any_instance.stub(:already_bound?).and_return(false)
      app.any_instance.stub(:create_binding)

      put(
        "/#{binding_uuid}",
        { "service_instance_id" => service_instance_uuid }.to_json,
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
      app.any_instance.stub(:already_bound?).and_return(true)

      put(
        "/#{binding_uuid}",
        { "service_instance_id" => service_instance_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )

      last_response.status.should == 409
    end
  end

  context "DELETE /:id" do
    before(:each) do
      app.any_instance.stub(:already_bound?).and_return(true)
      app.any_instance.stub(:destroy_binding)

      put(
        "/#{binding_uuid}",
        { "service_instance_id" => service_instance_uuid }.to_json,
        { "CONTENT_TYPE" => "application/json" }
      )
      delete "/#{binding_uuid}"
    end

    it "should include a 200 status code" do
      last_response.status.should == 200
    end

    it "should include a 404 status code" do
      app.any_instance.stub(:already_bound?).and_return(false)

      delete "/#{SecureRandom.uuid}"
      last_response.status.should == 404
    end

    it "should include an empty JSON object" do
      last_response.body.should be_json_eql("{}")
    end
  end
end
