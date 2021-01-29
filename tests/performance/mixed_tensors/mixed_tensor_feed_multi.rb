# Copyright Verizon Media. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require_relative 'mixed_tensor_base'

class MixedTensorFeedMultiPerfTest < MixedTensorPerfTestBase

  def test_multi_model_vec_256
    set_description("Test feed performance (put, assign, add) for multi-model mixed tensor with vector size 256")
    set_owner("geirst")
    @graphs = get_graphs_vec_256
    deploy_and_compile("vec_256")

    @num_docs = 30000
    warmup_feed("-d 1 -o #{@num_docs/5} -f models")
    # Tensor cells data is: 10 (model) * 3 (cat) * 256 * 4 = 30k
    feed_and_profile_cases("-d 3 -o #{@num_docs} -f models")
  end

  def get_graphs_vec_256
    [
      get_all_feed_throughput_graphs,
      get_feed_throughput_graph(PUTS, NUMBER, 510, 600),
      get_feed_throughput_graph(PUTS, STRING, 510, 600),
      get_feed_throughput_graph(UPDATES_ASSIGN, NUMBER, 530, 600),
      get_feed_throughput_graph(UPDATES_ASSIGN, STRING, 530, 600),
      get_feed_throughput_graph(UPDATES_ADD, NUMBER, 3650, 4250),
      get_feed_throughput_graph(UPDATES_ADD, STRING, 3650, 4250),
      get_feed_throughput_graph(UPDATES_REMOVE, NUMBER, 9200, 10900),
      get_feed_throughput_graph(UPDATES_REMOVE, STRING, 9200, 10900)
    ]
  end

  def test_multi_model_vec_32
    set_description("Test feed performance (put, assign, add) for multi-model mixed tensor with vector size 32")
    set_owner("geirst")
    @graphs = get_graphs_vec_32
    deploy_and_compile("vec_32")

    @num_docs = 10000
    warmup_feed("-d 1 -v 32 -o #{@num_docs/2} -f models")
    # Tensor cells data is: 10 (model) * 80 (cat) * 32 * 4 = 100k
    feed_and_profile_cases("-c 1000 -d 80 -v 32 -o #{@num_docs} -f models")
  end

  def get_graphs_vec_32
    [
      get_all_feed_throughput_graphs,
      get_feed_throughput_graph(PUTS, NUMBER, 135, 160),
      get_feed_throughput_graph(PUTS, STRING, 135, 160),
      get_feed_throughput_graph(UPDATES_ASSIGN, NUMBER, 140, 160),
      get_feed_throughput_graph(UPDATES_ASSIGN, STRING, 140, 160),
      get_feed_throughput_graph(UPDATES_ADD, NUMBER, 1000, 1300),
      get_feed_throughput_graph(UPDATES_ADD, STRING, 1000, 1300),
      get_feed_throughput_graph(UPDATES_REMOVE, NUMBER, 3100, 4100),
      get_feed_throughput_graph(UPDATES_REMOVE, STRING, 3100, 4100)
    ]
  end

  def teardown
    super
  end

end
