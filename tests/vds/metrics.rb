# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'vds_test'

class VdsMetrics < VdsTest

  def setup
    @valgrind=false
    set_owner("vekterli")
  end

  def create_app
    default_app.admin_metrics(Metrics.new.
                              consumer(Consumer.new("log").
                                       metric(Metric.new("vds.datastored.disk0.docs", "foo")).
                                       metric(Metric.new("vds.datastored.disk1.bytes", "bar"))))
  end

  def assert_event_log(count, metric, value = nil)
    logline = "value/1 name=\"#{metric}\" value="
    if (value != nil)
      logline += value.to_s
    end
    puts "Looking for '#{logline}'.\n"
    if (count == 0)
      assert_log_not_matches(logline)
    else
      assert_equal(count, assert_log_matches(logline, 30))
    end
  end

  def feed_docs
    puts "\nFEEDING DOCS\n"
    10.times { |i|
      doc = Document.new("music", "id:storage_test:music::" + i.to_s).
        add_field("title", "title")
      vespa.document_api_v1.put(doc)
    }
  end

  def restart_vds_node(node)
    node.stop
    vespa.storage["storage"].wait_until_cluster_down
    node.start
    vespa.storage["storage"].wait_for_current_node_state("storage", node.index.to_i, 'u')
    puts "\nDONE RESTARTING NODE #{node.servicetype}.#{node.index}\n"
  end

  def get_last_metric(metrics, name)
    metric = metrics.get(name)
    if !metric.nil?
      return metric["last"]
    end
  end

  def assert_get_last_metric_loop(expval, node, name)
    puts "Waiting for metric #{name} to become #{expval}"
    metric = nil
    360.times do
      metrics = JSONMetrics.new(node.get_state_v1_metrics)
      metric = get_last_metric(metrics, name)
      break if expval == metric
      sleep 1
    end
    assert_equal(expval, metric)
  end

  def assert_doc_metrics(docs)
    storagenode = vespa.content_node("storage", 0)
    assert_get_last_metric_loop(docs, storagenode, "vds.datastored.alldisks.docs")
    distributornode = vespa.storage["storage"].distributor["0"]
    assert_get_last_metric_loop(docs, distributornode, "vds.distributor.docsstored")
  end

  # Test that doc counts and sizes are available via state v1 metrics API
  def test_state_v1_metrics_doc_counts
    deploy_app(create_app)
    start
    # At first startup, document counts should be zero
    assert_doc_metrics(0)
    feed_docs
    # After feeding, both nodes should report to have 10 docs
    assert_doc_metrics(10)

    restart_vds_node(vespa.content_node("storage", 0))
    restart_vds_node(vespa.storage["storage"].distributor["0"])

    # After restart, both nodes should report to have 10 docs
    assert_doc_metrics(10)
  end

  def teardown
    stop
  end
end

