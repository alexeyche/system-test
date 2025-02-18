# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'search_test'

class IndexingDocproc < SearchTest

  def setup
    set_owner("bratseth")
    set_description("Check that it is possible to use an explicit indexing chain with additional docprocs.")
  end

  def test_indexing_docproc_explicit_cluster
    deploy_app(SearchApp.new.cluster(SearchCluster.new.sd(SEARCH_DATA+"music.sd").
                                             indexing("dpcluster1")).
               container(Container.new("dpcluster1").
                         search(Searching.new).
                         docproc(DocumentProcessing.new)))
    start
    feed_and_wait_for_docs("music", 10, :file => SEARCH_DATA+"music.10.xml")
  end

  def test_indexing_docproc_explicit_cluster_explicit_chain
    add_bundle(DOCPROC+"/WorstMusicDocProc.java")
    deploy_app(SearchApp.new.cluster(SearchCluster.new.sd(SEARCH_DATA+"music.sd").
                                             indexing("dpcluster1").
                                             indexing_chain("banana")).
               container(Container.new("dpcluster1").
                         search(Searching.new).
                         docproc(DocumentProcessing.new.chain(Chain.new("banana", "indexing").add(
                                    DocumentProcessor.new("com.yahoo.vespatest.WorstMusicDocProc", "indexingStart"))))))
    start
    feed_and_wait_for_docs("music", 10, :file => SEARCH_DATA+"music.10.xml")
    assert_result("query=sddocname:music",
                   selfdir+"music.10.result.json",
                   "surl")
  end

  def teardown
    stop
  end

end
