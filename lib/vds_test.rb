# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.
require 'testcase'
require 'app_generator/storage_app'

class VdsTest < TestCase

  attr_accessor :perform_implicit_log_check

  def initialize(*args)
    super(*args)
    @expected_logged = nil
    # To avoid mass test breakage in case of known warnings, maintain a workaround
    # set of log messages to ignore.
    # ... don't keep them around for long, though!
    ignores =
    [
      /Data is unavailable until node comes back up/
    ]
    add_ignorable_messages(ignores)

  end

  # It is used by factory for categorizing tests.
  def modulename
    "vds"
  end

  def can_share_configservers?(method_name=nil)
    true
  end

  def default_app(sd = "music", path = VDS + "/schemas/")
    sd_file = path + "#{sd}.sd"
    StorageApp.new.default_cluster.sd(sd_file).
      enable_document_api(FeederOptions.new.timeout(120)).
      transition_time(0)
  end

  def default_app_no_sd
    StorageApp.new.default_cluster.
      enable_document_api(FeederOptions.new.timeout(120)).
      transition_time(0)
  end


  alias :super_stop :stop
  def stop
    begin
      if not failure_recorded
        #vespa.storage["storage"].validate_cluster_bucket_state <- don't enable until tests have been cleaned up for logchecking
      else
        output "Testcase failed, skipping bucket database checks"
      end
    ensure
      super_stop
    end
  end


  # Creates a feed file with bucketIdStop-bucketIdStart buckets with numDocs documents of type 'type' that would be placed into the desired buckets.
  def make_feed_file(fileName, type, bucketIdStart, bucketIdStop, numDocs)
    file = File.new(fileName, "w")

    file.syswrite("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    file.syswrite("<vespafeed>\n")
    (1+bucketIdStop-bucketIdStart).times{|i|
      bucketId=bucketIdStart+i
      numDocs.times{|n|
        file.syswrite("  <document type=\"#{type}\" id=\"id:#{type}:#{type}:n=#{bucketId}:#{n}:system_test\"/>\n")
      }
    }
    file.syswrite("</vespafeed>\n")

    file.close
  end

  # Creates a feed file with docIdStop-docIdStart documents of type 'type' that would be placed into the desired bucket.
  def make_feed_file2(fileName, type, bucketId, docIdStart, docIdStop)
    file = File.new(fileName, "w")

    file.syswrite("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    file.syswrite("<vespafeed>\n")
    (1+docIdStop-docIdStart).times{|i|
      docId=docIdStart+i
      file.syswrite("  <document type=\"#{type}\" id=\"id:#{type}:#{type}:n=#{bucketId}:#{docId}\"/>\n")
    }
    file.syswrite("</vespafeed>\n")

    file.close
  end

  def get_default_log_check_levels
    return [:warning, :error, :fatal]
  end

  def get_default_log_check_components
    return ['storagenode\\d*', 'distributor\\d*',
            'searchnode\\d*', 'fleetcontroller']
  end

end
