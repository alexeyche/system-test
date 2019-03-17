# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
# encoding: utf-8
require 'indexed_search_test'

class MappedCharEncoding < IndexedSearchTest

  def setup
    set_owner("johansen")
    set_description("Test with normalization of accents")
    deploy_app(SearchApp.new.sd(SEARCH_DATA+"music.sd"))
    start
  end

  def test_mapped_char_encoding
    feed_and_wait_for_docs("music", 10000, :file => SEARCH_DATA+"music.10000.xml")

    field = "surl"
    puts "Query: Searching for 'walkuere'"
    assert_field("query=walkuere", selfdir+"walkure_u_mapped.result", field, true)

    puts "Query: Searching for 'walk?re'"
    assert_field("query=walk%c3%bcre", selfdir+"walkure_u_mapped.result", field, true)

    puts "Query: Searching for 'WALK?RE'"
    assert_field("query=WALK%C3%9CRE", selfdir+"walkure_u_mapped.result", field, true)

    puts "Query: Searching for 'espana'"
    assert_field("query=espana&hits=15", selfdir+"espana_n_mapped.result", field, true)

    puts "Query: Searching for 'espa?a'"
    assert_field("query=espa%c3%b1a&hits=15", selfdir+"espana_n_mapped.result", field, true)

    puts "Query: Searching for 'ESPA?A'"
    assert_field("query=ESPA%C3%91A&hits=15", selfdir+"espana_n_mapped.result", field, true)

    puts "Query: Searching for 'francois'"
    assert_field("query=francois&hits=15", selfdir+"francois_c_mapped.result", field, true)

    puts "Query: Searching for 'fran?ois'"
    assert_field("query=fran%c3%a7ois&hits=15", selfdir+"francois_c_mapped.result", field, true)

    puts "Query: Searching for 'FRAN?OIS'"
    assert_field("query=FRAN%C3%87OIS&hits=15", selfdir+"francois_c_mapped.result", field, true)

  end

  def teardown
    stop
  end

end
