# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'testcase'
require 'app_generator/search_app'
require 'search_apps'

class SearchTest < TestCase

  # Returns the modulename for this testcase superclass.
  # It is used by factory for categorizing tests.
  def modulename
    "search"
  end

  def can_share_configservers?(method_name=nil)
    true
  end

  def redeploy(app, cluster = "search")
    deploy_output = deploy_app(app)
    gen = get_generation(deploy_output).to_i
    vespa.storage[cluster].wait_until_content_nodes_have_config_generation(gen)
    return deploy_output
  end

  def stop_node_and_not_wait(cluster_name, node_idx)
    node = vespa.storage[cluster_name].storage[node_idx.to_s]
    puts "******** stop node and wait for node down(#{node.to_s}) ********"
    vespa.stop_content_node(cluster_name, node.index, 120)
    node.wait_for_current_node_state('d')
  end

  def stop_node_and_wait(cluster_name, node_idx)
    stop_node_and_not_wait(cluster_name, node_idx)
    puts "******** wait cluster up again ********"
    vespa.storage[cluster_name].wait_until_ready(120)
  end

  def start_node_and_wait(cluster_name, node_idx)
    node = vespa.storage[cluster_name].storage[node_idx.to_s]
    puts "******** start_node_and_wait for cluster up(#{node.to_s}) ********"
    vespa.start_content_node(cluster_name, node.index, 120)
    node.wait_for_current_node_state('u')
    vespa.storage[cluster_name].wait_until_ready(120)
  end

end
