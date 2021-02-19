# Copyright Verizon Media. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'performance/tensor_eval/tensor_eval'

class TensorEvalMatchPerfTest < TensorEvalPerfTest

  def setup
    super
    set_owner("geirst")
  end

  def test_tensor_evaluation_match
    set_description("Test performance of various expensive tensor matching use cases")
    @graphs = get_graphs_match
    deploy_and_feed(5000)

    [5,10,25].each do |dim_size|
      run_fbench_helper(MATCH, TENSOR_MATCH_25X25, dim_size, "queries.tensor.sparse.y.#{dim_size}.txt")
    end

    [5,10,25,50].each do |dim_size|
      run_fbench_helper(MATCH, TENSOR_MATCH_50X50, dim_size, "queries.tensor.sparse.y.#{dim_size}.txt")
    end

    [5,10,25,50,100].each do |dim_size|
      run_fbench_helper(MATCH, TENSOR_MATCH_100X100, dim_size, "queries.tensor.sparse.y.#{dim_size}.txt")
    end
  end

  def get_graphs_match
    [
      get_latency_graphs_for_rank_profile(TENSOR_MATCH_25X25),
      get_latency_graphs_for_rank_profile(TENSOR_MATCH_50X50),
      get_latency_graphs_for_rank_profile(TENSOR_MATCH_100X100),
      get_latency_graph_for_rank_profile(TENSOR_MATCH_50X50, 50, 70, 85)
    ]
  end

  def teardown
    super
  end

end
