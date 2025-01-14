# Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'indexed_search_test'

class TensorConformanceTest < IndexedSearchTest

  def setup
    set_owner('arnej')
  end

  def test_tensor_evaluation
    set_description('Test tensor evaluation conformance in production implementations')
    deploy_app(SearchApp.new.sd(selfdir + 'dummy.sd'))
    searchnode = vespa.search['search'].first
    command="B=#{Environment.instance.vespa_home}/bin/ && " +
        '${B}vespa-tensor-conformance generate |' +
        '${B}vespa-evaluate-tensor-conformance.sh |' +
        '${B}vespa-tensor-conformance evaluate |' +
        '${B}vespa-tensor-conformance verify'
    (exitcode, output) = searchnode.execute(command, {:exitcode => true, :exceptiononfailure => false})
    puts "Exit code from vespa-tensor-conformance verify: #{exitcode}"
    assert_equal(0, exitcode.to_i)
  end

  def teardown
    stop
  end

end
