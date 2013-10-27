# Riak Service Broker for Cloud Foundry [![Build Status](https://travis-ci.org/hectcastro/cf-riak-service-broker.png)](https://travis-ci.org/hectcastro/cf-riak-service-broker)

_This code works, but it's new. Proceed with caution and please tell us when it breaks._

This is a Riak service broker for the Cloud Foundry [v2 services](https://github.com/cloudfoundry/cf-docs/tree/services_v2) API. Documentation for the v2 services API can be found [here](https://docs.google.com/document/d/1qXnEI0pfTs_nUq4w4iMr3RHknLYgFDTYvOe76hugg28/edit#heading=h.1ov8gjl5iza6).

The Riak service broker provides a Riak endpoint, in the form of a bucket, to your Cloud Foundry application. In other words, it lets you use Riak through Cloud Foundry. 

### Why use Riak on Cloud Foundry?

[Riak](http://docs.basho.com/docs.basho.com/riak/latest/) is a scalable, distributed database. It's a powerful storage platform for building realtime applications that can't go down. It's data model is focused around keys and values, but we also offer full-text indexing, MapReduce, Secondary indexing, and data types like counters, sets, maps, and registers. 

In production Riak stresses operational simplicity. Adding and removing nodes is dead simple, and Riak is masterless, meaning no node is special and can take down your cluster. There's no need for arbiters, shards, keepers of Zoos, etc. 

Riak gives organizations using Cloud Foundry the ability to use a scalable, distributed database when building applications. 
  
### How, specifically, does this work?

At a high level, the Riak service broker provides CF applications with access to a Riak cluster.

Applications you're running on Cloud Foundry talk to a Riak service broker via the [Cloud Controller](http://docs.cloudfoundry.com/docs/running/architecture/cloud-controller.html) (CC). Using the v2 API, the controller registers the Riak service which in turn responds with its catalog. Once this is complete, applications can use pieces of the catalog. Catalogs have specific services, and each of these services can offer any number of plans.  Our [catalog](https://github.com/hectcastro/cf-riak-service-broker/blob/develop/lib/catalog.rb) currently has one Riak service with two options (plans): Bitcask and LevelDB.

Bitcask and LevelDB are both [backend storage options](http://docs.basho.com/riak/latest/ops/building/planning/backends/) for Riak, and they are built for different use cases. Thus, exposing each of these as separate plans lets people test Riak for different use cases. 

### Prerequisites 

* **A Bosh Environment** - We used [bosh-lite](https://github.com/cloudfoundry/bosh-lite) for our local development environment. [Nise BOSH](https://github.com/nttlabs/nise_bosh) is another option. Regardless, be patient. CF is powerful software but there are still some rough edges with getting a dev environment up and running. 
* **CF CLI** - You'll also need the Cloud Foundry [cli, cf](http://docs.cloudfoundry.com/docs/using/managing-apps/cf/). This is needed for deploying applications and services in CF environments. 
* **Riak cluster** - Lastly, you'll need a running Riak cluster with `multi_backend` enabled. This is lets you run more than one backend type in the same Riak cluster, and, for our purposes, lets us offer both the LevelDB and Bitcask plans via the service broker. Specifically, you need to make sure that you add the `multi_backend` parameter to your [app.config](http://docs.basho.com/riak/latest/ops/advanced/configs/configuration-files/#app-config) and that you specify both `bitcask_mult` and `eleveldb_mult` as the specific backends before Riak gets started up. The [Riak docs on this](http://docs.basho.com/riak/latest/ops/advanced/backends/multi/#Configuring-Multiple-Backends) will walk you through it. 

For reference, here are the snippets you'll need to add the `riak_kv` section of you `app.config` (as described in the above-linked docs):



``` erlang 
{riak_kv, [
    %% ...
    %% Use the Multi Backend
    {storage_backend, riak_kv_multi_backend},
    {multi_backend_default, <<"bitcask_mult">>},
    {multi_backend, [
        %% Here's where you set the individual multiplexed backends
        {<<"bitcask_mult">>,  riak_kv_bitcask_backend, [
        ]},
        {<<"eleveldb_mult">>, riak_kv_eleveldb_backend, [
        ]}
    ]},
    %% ...
]},
```

### Usage 

The [broker.yml.sample](https://github.com/hectcastro/cf-riak-service-broker/blob/develop/config/broker.yml.sample) files provides a template for your broker configuration. Copy it, rename it to `broker.yml`, and make changes accordingly. `riak_hosts` should mirror your Riak environment.


After this is done, we need to start the Riak Service Broker. Clone this repo (if you've not done so already):

```
$ git clone https://github.com/hectcastro/cf-riak-service-broker
$ cd cf-riak-service-broker
$ bundle
$ bundle exec rackup
```

Now that we've got our service broker started we're going to add it to CF. The url option needs to be the location of your running service broker. 

```
$ cf add-service-broker --name riak --username admin --password admin --url http://10.84.17.214.xip.io:9292
.
Adding service broker Riak... OK
```

### Example with Sample App

Pop open a new terminal and clone our [simple cf sample broker app](https://github.com/hectcastro/cf-riak-service-broker-sample-app) and get it set up. This will be the application you deploy on Cloud Foundry that speaks to your Riak cluster with the help of the service broker. 

```
$ git clone https://github.com/hectcastro/cf-riak-service-broker-sample-app.git
$ cd cf-riak-service-broker-sample-app
$ bundle 
```

We're now going to use `cf push` which will deploy our application. This will spit out a series of options. Follow the instructions provided. The full output will look something like this:

```
$ cf push
Name> sample

Instances> 1

1: 128M
2: 256M
3: 512M
4: 1G
Memory Limit> 256M

Creating sample... OK

1: sample
2: none
Subdomain> sample

1: 10.244.0.22.xip.io
2: none
Domain> 10.244.0.22.xip.io

Binding sample.10.244.0.22.xip.io to sample... OK

Create services for application?> y

1: riak , via
2: user-provided , via
What kind?> 1

Name?> riak-e7e2c

1: bitcask: A bucket using the Bitcask backend.
2: leveldb: A bucket using the LevelDB backend.
Which plan?> 1

Creating service riak-e7e2c... OK
Binding riak-e7e2c to sample... OK
Create another service?> n

Bind other services to application?> n

Save configuration?> y

Saving to manifest.yml... OK
Uploading sample... OK
Preparing to start sample... OK

[ Snip ]
[ Snip ]
[ Snip ]

Checking status of app 'sample'...
  1 of 1 instances running (1 running)
Push successful! App 'sample' available at http://sample.10.244.0.22.xip.io
````

For reference, you should see similar output to this from the broker application upon executing `cf push` :

```
[2013-10-17 15:28:10] INFO  WEBrick 1.3.1
[2013-10-17 15:28:10] INFO  ruby 1.9.3 (2013-06-27) [x86_64-darwin12.4.0]
[2013-10-17 15:28:10] INFO  WEBrick::HTTPServer#start: pid=16496 port=9292
10.84.18.22 - admin [17/Oct/2013 15:28:17] "GET /v2/catalog HTTP/1.1" 200 391 0.0267
10.84.18.22 - admin [17/Oct/2013 15:28:34] "PUT /v2/service_instances/77168267-a4e4-4ff2-9185-e0b4832d9c60 HTTP/1.1" 201 2 0.0025
10.84.18.22 - admin [17/Oct/2013 15:28:34] "PUT /v2/service_bindings/f6ee27cb-ce7e-4c68-af55-cce502499ec0 HTTP/1.1" 201 581 0.0024
```

Now we can hit the application using `curl` and `python -mjson.tool` to pretty-up our output. The response is a dump of `VCAP_SERVICES` exposed to the application. 


```
curl -s http://sample.10.244.0.22.xip.io | python -mjson.tool
{
  "riak": [
    {
      "name": "riak-174e8",
      "label": "riak",
      "tags": [],
      "plan": "bitcask",
      "credentials": {
        "uris": [
          "http://riak1.example.com:8098/buckets/a643f12f-fcbf-4c58-bd7b-22650b2167a0",
          "http://riak2.example.com:8098/buckets/a643f12f-fcbf-4c58-bd7b-22650b2167a0",
          "http://riak3.example.com:8098/buckets/a643f12f-fcbf-4c58-bd7b-22650b2167a0",
          "http://riak4.example.com:8098/buckets/a643f12f-fcbf-4c58-bd7b-22650b2167a0",
          "http://riak5.example.com:8098/buckets/a643f12f-fcbf-4c58-bd7b-22650b2167a0"
        ],
        "bucket": "a643f12f-fcbf-4c58-bd7b-22650b2167a0",
        "port": 8098,
        "hosts": [
          "riak1.example.com",
          "riak2.example.com",
          "riak3.example.com",
          "riak4.example.com",
          "riak5.example.com"
        ]
      }
    }
  ]
}
```


### TODO 

* Add ability to talk to Riak via PB API.
