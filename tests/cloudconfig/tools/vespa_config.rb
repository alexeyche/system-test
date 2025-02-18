# Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'cloudconfig_test'
require 'app_generator/search_app'
require 'environment'

class VespaConfig < CloudConfigTest

  def setup
    set_owner("musum")
    set_description("Tests vespa-config.pl")
    @node = vespa.nodeproxies.first[1]
  end

  def test_vespa_config
    app_gen = SearchApp.new.sd(SEARCH_DATA+"music.sd")
    deploy_app(app_gen)
    @node = vespa.adminserver
    @hostname = @node.hostname

    run_configsource_test
    run_configserver_port_test
    run_empty_port_test
  end

  def run_configsource_test
    output = call_vespa_config_script("-configsources")
    assert_equal("tcp/" + @hostname + ":19070", output.strip)
  end

  def run_configserver_port_test
    output = call_vespa_config_script("-configserverport")
    assert_equal("19070", output.strip)
  end

  def run_empty_port_test
    set_port_configserver_rpc(@node)
    output = call_vespa_config_script("-confighttpsources")
    assert_equal("http://#{@hostname}:19071", output.strip)
  end

  def call_vespa_config_script(option, noexception=false)
    command = Environment.instance.vespa_home + "/libexec/vespa/vespa-config.pl #{option} 2>/dev/null"
    if noexception
      @node.execute(command, {:exitcode => true, :exceptiononfailure => false})
    else
      @node.execute(command)
    end
  end

  def teardown
    stop
  end

end
