# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'indexed_search_test'
require 'app_generator/http'

class VespaApplication < IndexedSearchTest

  def setup
    set_owner("gjoranv")
    set_description("Test that application packages work, including config.xml and templates")
    app = SearchApp.new.sd(selfdir+"music.sd").
            config(ConfigOverride.new("vespa.config.search.summary.juniperrc").
              add("prefix", false).
              add(ArrayConfig.new("override").
                add(0, ConfigValue.new("fieldname", "song")).
                add(0, ConfigValue.new("max_matches", 4)).
                add(0, ConfigValue.new("min_length", 90)).
                add(0, ConfigValue.new("length", 120)))).
            config(ConfigOverride.new("prelude.cluster.qr-monitor").
              add("requesttimeout", 5000)).
        container(Container.new.
                      search(Searching.new).
                      docproc(DocumentProcessing.new).
                      http(Http.new.server(Server.new("node1", 16666))))

    deploy_app(app)
    start
  end

  def http_get(uri_str)
    uri = URI.parse(uri_str)
    response = https_client.get(uri.host, uri.port, uri.path, query: uri.query)
    assert(response.code == "200", "HTTP GET to #{uri_str} returned response code #{response.code}. Expected code was 200.")
  end

  def send_query(uri_str, query)
    http_get(uri_str+"search/?query="+query)
  end

  def test_vespa_application
    feed_and_wait_for_docs("music", 2, :file => selfdir+"input.xml")

    wait_for_hitcount("query=metallica", 1, 60, 0)

    hostname = vespa.adminserver.name
    qrs0 = "http://#{hostname}:16666/"

    puts "Details: Running query to see that qrs.0 listens at correct port"
    send_query(qrs0, "metallica")

    puts "Run a query to test custom juniper config"
    feed_and_wait_for_docs("music", 779, :file => SEARCH_DATA+"music.777.xml")
    assert_result("query=english+band+major", selfdir + "junipertest.json", nil, ["song"])
  end

  def teardown
    stop
  end

end
