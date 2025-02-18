# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'cloudconfig_test'
require 'environment'

class MultiEnvironment < CloudConfigTest

  def initialize(*args)
    super(*args)
  end

  def setup
    set_description("Test multi environment application packages")
    set_owner("musum")
    @node = vespa.nodeproxies.values.first
  end

  def test_multiple_environments
    set_env_and_region(@node, "dev", "default")
    deploy("#{selfdir}/multienv", nil, {:environment=>"dev"})
    assert_logd_config_v2(4099, @node.hostname, "default", "default", "default", "dev", "default")
    @node.stop_configserver
    set_env_and_region(@node, "prod", "us-west")
    deploy("#{selfdir}/multienv", nil, {:environment=>"prod", :region=>"us-west"})
    assert_logd_config_v2(5000, @node.hostname, "default", "default", "default", "prod", "us-west")
  end

  def test_preprocess_tool
    dest = "#{dirs.tmpdir}/multienv"
    outputdest = "#{dirs.tmpdir}/multienv_dest"
    @node.copy("#{selfdir}/multienv", dest)
    @node.execute("mkdir #{outputdest}")
    out = @node.execute("#{Environment.instance.vespa_home}/bin/vespa-preprocess-application #{dest} prod default #{outputdest}")
    assert(out =~ /Application preprocessed successfully/)
  end

  def set_env_and_region(node, environment, region)
    override_environment_setting(node, "VESPA_ENVIRONMENT", environment);
    override_environment_setting(node, "VESPA_REGION", region)
  end

  def teardown
    override_environment_setting(@node, "VESPA_ENVIRONMENT", nil)
    override_environment_setting(@node, "VESPA_REGION", nil)
    stop
  end
end
