# Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'indexed_search_test'

class RealtimeSorting < IndexedSearchTest

  def setup
    set_owner("yngve")
    set_description("Tests the sorting feature of Realtime Mode with two slots")
    deploy_app(SearchApp.new.sd(selfdir+"base.sd"))
    start
  end

  def test_realtimesorting
    feed_and_wait_for_docs("base", 10, :file => selfdir+"1-10.xml")

    filter = /<field name="date">/
    query= "query=title:title&sorting=%2ddate&hits=10&nocache"
    puts "Detail: " + query
    assert_result(query,selfdir+"1-10.result.json", nil, [ 'date' ])

    feed_and_wait_for_docs("base", 20, :file => selfdir+"11-20.xml")
    puts "Detail: " + query
    assert_result(query,selfdir+"11-20.result.json", nil, [ 'date' ])

    query= "query=title:title&sorting=%2ddate&hits=15&nocache"
    puts "Detail: " + query
    assert_result(query,selfdir+"6-20.result.json", nil, [ 'date' ])
  end

  def teardown
    stop
  end

end
