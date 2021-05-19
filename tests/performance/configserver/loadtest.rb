require 'performance_test'
require 'performance/configserver/generator'

class ConfigserverLoadTest < PerformanceTest

  def initialize(*args)
    super(*args)
    @app = selfdir + 'app'
    @testfile = 'test.cfg'
    @defdir = "defbundle/src/main/resources/configdefinitions"
  end

  def setup
    super
    set_owner("musum")
    set_description("Performance test of config server")
    FileUtils.cp_r(selfdir + "defbundle", @dirs.tmpdir)
  end

  def setup_generator(num_configs, num_fields, version)
    generator = Generator.new(num_configs, num_fields, version)
    generator.generate_def(dirs.tmpdir + @defdir)
    generator.generate_loadfile(dirs.tmpdir + @testfile)
  end

  def test_client_scaling
    @graphs = [
      {
        :x => 'blank',
        :y => 'config.loadtester.req_per_sec',
        :y_min => 24000,
        :y_max => 30000,
        :historic => true
      }
    ]
    num_requests = 100000
    setup_generator(150, 10, 1)

    copy_files_to_tmp_dir(vespa.nodeproxies.first[1])

    @node = @vespa.nodeproxies.first[1]
    # Set start and max heap equal to avoid a lot of GC while running test
    override_environment_setting(@node, "VESPA_CONFIGSERVER_JVMARGS", "-Xms2g -Xmx2g")
    deploy(@app)
    start

    node = @vespa.nodeproxies.first[1]
    1.times do
      run_cloudconfig_loadtester(node, 19070, num_requests, 32, @dirs.tmpdir + @testfile, @dirs.tmpdir + @defdir)
    end
  end

  def copy_files_to_tmp_dir(node)
    node.copy(dirs.tmpdir + @testfile, @dirs.tmpdir)
    node.copy(dirs.tmpdir + @defdir, @dirs.tmpdir + @defdir)
  end

  def teardown
    super
  end
end