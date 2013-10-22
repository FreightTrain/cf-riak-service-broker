#!/usr/bin/env rackup

require File.expand_path("../config/boot.rb", __FILE__)

unless CONFIG["username"].nil? || CONFIG["password"].nil?
  use Rack::Auth::Basic, "Cloud Foundry Riak Service Broker" do |username, password|
    [ username, password ] == [ CONFIG["username"], CONFIG["password"] ]
  end
end

run Rack::URLMap.new({
  "/v2/catalog"            => RiakBroker::Catalog,
  "/v2/service_instances"  => RiakBroker::ServiceInstances,
  "/v2/service_bindings"   => RiakBroker::ServiceBindings
})
