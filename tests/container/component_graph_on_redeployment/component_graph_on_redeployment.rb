# Copyright Verizon Media. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'container_test'
require 'app_generator/container_app'

class ComponentGraphOnRedeployment < ContainerTest

  LOG_MSG_PATTERN = Regexp.compile('Container\\.com\\.yahoo\\.container\\.di\\.componentgraph.core\\.ComponentNode.+Constructing \'(.+)\'')

  ALLOWED_COMPONENTS_TO_RECONSTRUCT = [
      'com.yahoo.container.jdisc.state.StateHandler',
      'com.yahoo.container.handler.observability.ApplicationStatusHandler',
      'com.yahoo.container.core.config.HandlersConfigurerDi$RegistriesHack'
  ]

  def setup
    set_owner('bjorncs')
    set_description('Verify that only certain components are reconstructed on redeployment of identical app')
  end

  def test_only_known_components_are_reconstructed_on_redeployment_with_same_app
    app = ContainerApp.new.
        container(Container.new.docproc(DocumentProcessing.new).search(Searching.new).documentapi(ContainerDocumentApi.new))

    # Initial deploy
    start(app)

    # The wanted messages from ComponentNode are logged as debug.
    @container.logctl('container:com.yahoo.container.di.componentgraph.core.ComponentNode', 'debug=on')

    # Redeploy same app. This is similar to an internal reconfiguration in hosted Vespa.
    deploy(app)

    log_matches = vespa.logserver.find_log_matches(LOG_MSG_PATTERN)
    reconstructed_components = log_matches.flatten.sort
    assert_equal(ALLOWED_COMPONENTS_TO_RECONSTRUCT.sort, reconstructed_components)
  end

  def teardown
    stop
  end

end