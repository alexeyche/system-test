# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'search_container_test'
require 'app_generator/container_app'

class HealthCheckProxyTest < SearchContainerTest

  def setup
    set_owner('bjorncs')
    set_description('Verify that container is able to proxy health checks from http to https')
  end

  def test_server
    container_port = Environment.instance.vespa_web_service_port
    proxy_port = container_port + 1
    app = ContainerApp.new.container(
        Container.new.jvmargs('-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005').
            http(Http.new.
                server(
                    Server.new('https-server', container_port)).
                server(
                    Server.new('http-proxy-server', container_port + 1).
                        config(ConfigOverride.new('jdisc.http.connector').
                            add('healthCheckProxy', ConfigValues.new.add('enable', true).add('port', container_port.to_s))))))
    deploy_app(app)
    start
    response = Net::HTTP.get_response(URI("http://#{vespa.container.values.first.hostname}:#{proxy_port}/status.html"))
    assert_equal(200, response.code.to_i)
    assert_match(Regexp.new('<title>OK</title>'), response.body, 'Could not find expected message in response.')
    assert_equal(container_port, response['Vespa-Health-Check-Proxy-Target'].to_i)
  end

  def teardown
    stop
  end

end
