# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'test/unit'
require 'generator'

class GeneratorTest < Test::Unit::TestCase

  def test_digest
    generator = Generator.new
    digest_command = generator.digest_command(command: 'echo "one two two three three three"', cutoff: 1)
    assert_equal("3 three\n2 two\n",
                 `#{digest_command}`)
  end

  def test_feed
    generator = Generator.new
    doc = '{"id":"id:ns:type::$seq()", "text":"$words(2)", "chars": "$chars(2)", "ints": [$ints(2, 2)], "floats": $floats(), "filter": [$filter(10, 90)]}'
    feed_command = generator.feed_command(template: doc, count: 1, data: 'echo "1 one"')
    assert_equal("[\n{\"id\":\"id:ns:type::0\", \"text\":\"one one\", \"chars\": \"on\", \"ints\": [1,1], \"floats\": 0.6007954689329611, \"filter\": [90]}\n]\n",
                 `#{feed_command}`)
  end

  def test_query
    generator = Generator.new
    query = 'sddocname:test foo:$words() bar:$words() baz:$pick(2, "one", "two", "three")'
    query_command = generator.query_command(template: query, count: 2, parameters: {:a => 'b'})
    assert_equal("/search/?query=sddocname%3Atest+foo%3Ared+bar%3Atwitter+baz%3A%22one%22%2C%22two%22&a=b\n" +
                 "/search/?query=sddocname%3Atest+foo%3Adefensive+bar%3Abosses+baz%3A%22two%22%2C%22one%22&a=b\n",
                 `#{query_command}`)
  end

  def test_url
    generator = Generator.new
    path = '/document/v1/ns/type/docid/'
    url_command = generator.url_command(template: '$seq(2)$include(0.99, x)', count: 1, path: path, parameters: {'%' => '%', :c => :d}, data: ':')
    assert_equal("/document/v1/ns/type/docid/2x?%25=%25&c=d\n",
                `#{url_command}`)
  end

end

