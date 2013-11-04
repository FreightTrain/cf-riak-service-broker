module RiakBroker
  RIAK_SERVICE_ID = "084d6148-3b0e-4c36-a229-401d9b8982bd"
  BITCASK_PLAN_ID = "dc97f6e9-799f-4c33-9a9a-0336fb056068"
  LEVELDB_PLAN_ID = "4d077f64-c0a6-40d8-928d-fe4014acb044"

  class Catalog
    def to_json
      {
        "services" => [
          "id" => RIAK_SERVICE_ID,
          "name" => "riak",
          "description" => "An open source, distributed key/value store.",
          "bindable" => true,
          "plans" => [
            {
              "id" => BITCASK_PLAN_ID,
              "name" => "bitcask",
              "description" => "A bucket using the Bitcask backend."
            },
            {
              "id" => LEVELDB_PLAN_ID,
              "name" => "leveldb",
              "description" => "A bucket using the LevelDB backend."
            }
          ]
        ]
      }.to_json
    end
  end
end
