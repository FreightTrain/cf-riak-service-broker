require "spec_helper"

describe RiakBroker::CatalogsController do
  def app
    @app ||= RiakBroker::CatalogsController
  end

  context "GET /" do
    before(:each) do
      get "/"
    end

    it "should include a list of services" do
      last_response.body.should have_json_path("services")
    end

    it "should include a service GUID" do
      last_response.body.should have_json_path("services/0/id")
    end

    it "should include a service name" do
      last_response.body.should have_json_path("services/0/name")
    end

    it "should include a service description" do
      last_response.body.should have_json_path("services/0/description")
    end

    it "should include two plans" do
      last_response.body.should have_json_size(2).at_path("services/0/plans")
    end

    it "should include a plan for Bitcask" do
      last_response.body.should have_json_path("services/0/plans/0/name")
      JSON.parse(last_response.body)["services"][0]["plans"][0]["name"].should == "bitcask"
    end

    it "should include a plan for LevelDB" do
      last_response.body.should have_json_path("services/0/plans/1/name")
      JSON.parse(last_response.body)["services"][0]["plans"][1]["name"].should == "leveldb"
    end
  end
end
