# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'docproc_test'

class InstallNewDocprocDocproc < DocprocTest

  def setup
    set_owner("gjoranv")
    add_bundle(DOCPROC + "WorstMusicDocProc.java")
    deploy(selfdir+"setup-1x1-worst", DOCPROC + "data/worst.sd")
    start
  end

  def test_install_new_docproc
    feed_and_wait_for_docs("worst", 4, :file => DOCPROC + "data/worst-input.xml")
    assert_result("query=sddocname:worst", DOCPROC + "data/worst-processed.json")

    #So far, so good...

    #new config with new chain, "terrible"
    clear_bundles()
    add_bundle(DOCPROC + "WorstMusicDocProc.java")
    add_bundle(DOCPROC + "TerribleMusicDocProc.java")
    deploy(selfdir+"/setup-1x1-terrible", DOCPROC + "data/worst.sd")

    # we should still get the same 10 results through the default chain
    feed_and_wait_for_docs("worst", 0, {:file => DOCPROC + "data/worst-remove.xml"})
    feed_and_wait_for_docs("worst", 4, {:file => DOCPROC + "data/worst-input.xml"})
    assert_result("query=sddocname:worst", DOCPROC + "data/worst-processed.json")

    #we should get other results if feeding through "terrible" chain
    feed_and_wait_for_docs("worst", 0, {:file => DOCPROC + "data/worst-remove.xml"})
    feed_and_wait_for_docs("worst", 4, {:file => DOCPROC + "data/worst-input.xml", :route => "\"container/chain.terrible indexing\""})
    assert_result("query=sddocname:worst", selfdir+"terrible.result.json")
  end

  def teardown
    stop
  end

end
