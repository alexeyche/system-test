# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'search_test'

class NoAdminInServices < SearchTest

  def setup
    set_owner("musum")
    set_description("Test that having no admin element in services.xml works")
  end

  def test_no_admin_search
    deploy(selfdir + "app-search", SEARCH_DATA + "music.sd")
    start_and_feed
  end

  def test_no_admin_content
    deploy(selfdir + "app-content", SEARCH_DATA + "music.sd")
    start_and_feed
  end

  def start_and_feed
    start
    feed(:file => SEARCH_DATA+"music.10.xml")
    wait_for_hitcount("query=sddocname:music", 10)
  end

  def teardown
    stop
  end

end
