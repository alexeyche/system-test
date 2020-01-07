# Private reason: Depends on pub/ data

require 'http_client'
require 'performance_test'
require 'performance/fbench'
require 'pp'


class BasicContainer < PerformanceTest

  STANDARD = 'standard'
  ASYNC_WRITE = 'asyncwrite'
  NON_PERSISTENT = 'nonpersistent'

  def initialize(*args)
    super(*args)
    @app = selfdir + 'app'
    @queryfile = nil
    @bundledir= selfdir + 'java'
  end

  def setup
    set_owner('bjorncs')
    # Bundle with HelloWorld and AsyncHelloWorld handler
    add_bundle_dir(@bundledir, 'performance', {:mavenargs => '-Dmaven.test.skip=true'})
  end

  def setup_and_deploy(app)
    deploy(app)
    start
  end

  def test_container_http_performance
    setup_and_deploy(@app)
    set_description('Test basic HTTP performance of container')
    @graphs = [
        {
            :title => 'QPS all combined',
            :x => 'legend',
            :y => 'qps',
            :historic => true
        },
        {
            :title => 'QPS HTTP/1.1',
            :filter => {'legend' => STANDARD},
            :x => 'legend',
            :y => 'qps',
            :y_min => 260000,
            :y_max => 292000,
            :historic => true
        },
        {
            :title => 'QPS HTTP/1.1 with async write',
            :filter => {'legend' => ASYNC_WRITE },
            :x => 'legend',
            :y => 'qps',
            :y_min => 190000,
            :y_max => 215000,
            :historic => true
        },
        {
            :title => 'QPS HTTP/1.1 without keep-alive',
            :filter => {'legend' => NON_PERSISTENT },
            :x => 'legend',
            :y => 'qps',
            :y_min => 2600,
            :y_max => 3150,
            :historic => true
        },
        {
            :x => 'legend',
            :y => 'latency',
            :historic => true
        },
        {
            :x => 'legend',
            :y => 'cpuutil',
            :historic => true
        }
    ]

    container = (vespa.qrserver['0'] or vespa.container.values.first)
    container.copy(selfdir + "hello.txt", dirs.tmpdir)
    sync_req_file = dirs.tmpdir + "hello.txt"
    container.copy(selfdir + "async_hello.txt", dirs.tmpdir)
    async_req_file = dirs.tmpdir + "async_hello.txt"

    @queryfile = sync_req_file
    run_fbench(container, 128, 20, []) # warmup

    profiler_start
    run_fbench(container, 128, 120, [parameter_filler('legend', STANDARD)])
    profiler_report(STANDARD)

    @queryfile = async_req_file
    profiler_start
    run_fbench(container, 128, 120, [parameter_filler('legend', ASYNC_WRITE)])
    profiler_report(ASYNC_WRITE)

    @queryfile = sync_req_file
    profiler_start
    run_fbench(container, 32, 120, [parameter_filler('legend', NON_PERSISTENT)], {:disable_http_keep_alive => true})
    profiler_report(NON_PERSISTENT)
  end

end