# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'multi_provider_storage_test'

class Bug4069929 < MultiProviderStorageTest

  def setup
    set_owner("balder")
    set_description("Test for bug 4069929")

    deploy_app(default_app.sd(selfdir + "music.sd"))
    start
  end

  def test_bug4069929
    feedfile(selfdir+"feed.xml")
    vespa.adminserver.execute("vespa-visit -i")
  end

  def teardown
    stop
  end

end
