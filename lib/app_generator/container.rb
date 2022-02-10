# Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'app_generator/qrserver_cluster'
require 'app_generator/processing'

class Node < NodeBase
  tag "node"
end

class Container
  include ChainedSetter

  chained_setter :baseport
  chained_setter :search
  chained_setter :docproc
  chained_setter :processing
  chained_setter :http
  chained_setter :documentapi
  chained_setter :jvmargs
  chained_setter :jvmoptions
  chained_setter :jvmgcoptions
  chained_setter :cpu_socket_affinity

  chained_forward :config, :config => :add
  chained_forward :handlers, :handler => :push
  chained_forward :components, :component => :push
  chained_forward :concretedocs, :concretedoc => :push

  def initialize(id = "default")
    @config = ConfigOverrides.new
    @handlers = []
    @components = []
    @concretedocs = []
    @nodes = []
    @id = id
    @baseport = 0
    @jvmoptions = nil
    @jvmgcoptions = nil
    @cpu_socket_affinity = nil
  end

  def node_list
    return [Node.new] if @nodes.empty?
    return @nodes
  end

  def node(params={})
    @nodes.push(Node.new(params))
    self
  end

  def jvm_options= jvm_options
    @jvmoptions = jvm_options
  end

  def jvm_options
    @jvmoptions
  end

  def feeder_options(feeder_options)
    @feeder_options = feeder_options
    self
  end

  def to_xml(indent)
    attrs = {:version => "1.0", :id => @id}
    attrs[:baseport] = @baseport.to_s if @baseport != 0

    helper = XmlHelper.new(indent)
    helper.tag("container", attrs)

    nodeparams = @jvmargs ? { :jvmargs => @jvmargs } : {}
    if @cpu_socket_affinity then
      nodeparams = nodeparams.merge({:"cpu-socket-affinity" => @cpu_socket_affinity})
    end

    jvm_options = @jvmoptions ? { :options => @jvmoptions } : {}
    if @jvmgcoptions
      jvm_options = jvm_options.merge({:"gc-options" => @jvmgcoptions })
    end

    helper.
      to_xml(@config).
      to_xml(@search).
      to_xml(@docproc).
      to_xml(@concretedocs).
      to_xml(@processing).
      to_xml(@documentapi).
      to_xml(@handlers).
      to_xml(@components).
      to_xml(@http).
      to_xml(@feeder_options).
      tag("nodes", nodeparams).tag("jvm", jvm_options).close_tag.to_xml(node_list).close_tag.
      to_s
  end
end

class Containers
  include ChainedSetter

  chained_setter :feeder_options

  def initialize()
    @containers = []
    @jvm_options = nil
    @feeder_options = nil
  end

  def add(container)
    @containers.push(container)
  end

  def newline(s)
    s.empty? ? s : s + "\n"
  end

  def jvmoptions= jvm_options
    @jvm_options = jvm_options
  end

  def to_xml(indent)
    out = ""
    for container in @containers
      if (@jvm_options and ! container.jvm_options)
        container.jvm_options = @jvm_options
      end
      out << newline(container.to_xml(indent))
    end
    return out
  end

end

class Searching
  include ChainedSetter

  chained_forward :config, :config => :add
  chained_forward :chains, :chain => :push
  chained_forward :renderers, :renderer => :push

  def initialize()
    @config = ConfigOverrides.new
    @chains = []
    @renderers = []
  end

  def to_xml(indent)
    XmlHelper.new(indent)\
      .tag_always("search")\
      .to_xml(@config)\
      .to_xml(@chains)\
      .to_xml(@renderers)\
      .to_s
  end

end

class DocumentProcessing
  include ChainedSetter

  chained_forward :chains, :chain => :push

  def initialize()
    @chains = []
  end

  def to_xml(indent)
    XmlHelper.new(indent)\
      .tag_always("document-processing")\
        .to_xml(@chains)\
        .to_s
  end

end

class DocProc < Processor
  def initialize(id, after=nil, before=nil, klass=nil, bundle=nil)
    super(id, after, before, klass, bundle)
  end

  def to_xml(indent="")
    return dump_xml(indent, "documentprocessor")
  end
end

class ContainerDocumentApi
  include ChainedSetter

  chained_setter :feeder_options

  def initialize()
    @abortondocumenterror = nil
    @timeout = nil
    @feeder_options = nil
  end

  def to_xml(indent)
    XmlHelper.new(indent).
      tag_always("document-api").to_xml(@feeder_options).close_tag.
      to_s
  end

end

class Handler
  include ChainedSetter

  chained_setter :klass
  chained_setter :config
  chained_setter :bundle

  chained_forward :bindings, :binding => :push

  def initialize(id)
    @id = id
    @config = ConfigOverrides.new
    @bindings = []
  end

  def to_xml(indent="")
    return dump_xml(indent)
  end

  def dump_xml(indent="", tagname="handler")
    XmlHelper.new(indent).
        tag(tagname, :id => @id, :bundle => @bundle,
            :provides => @provides, :class => @klass).
      list_do(@bindings) { |helper, binding|
      helper.tag("binding").content(binding).
      close_tag }.to_xml(@config).to_s
  end
end

class Component
  include ChainedSetter

  chained_setter :klass
  chained_setter :config
  chained_setter :bundle

  def initialize(id)
    @id = id
    @config = ConfigOverrides.new
  end

  def to_xml(indent="")
    dump_xml(indent)
  end

  def dump_xml(indent="", tagname="component")
    XmlHelper.new(indent).
        tag(tagname,
            :id => @id,
            :bundle => @bundle,
            :class => @klass).
        to_xml(@config).to_s
  end
end

class Client
  include ChainedSetter

  chained_setter :klass
  chained_setter :config
  chained_setter :bundle

  chained_forward :bindings, :binding => :push

  def initialize(id)
    @id = id
    @config = ConfigOverrides.new
    @bindings = []
  end

  def to_xml(indent="")
    return dump_xml(indent)
  end

  def dump_xml(indent="", tagname="client")
    XmlHelper.new(indent).
        tag(tagname, :id => @id, :bundle => @bundle,
            :provides => @provides, :class => @klass).
      list_do(@bindings) { |helper, binding|
      helper.tag("binding").content(binding).
      close_tag }.to_xml(@config).to_s
  end
end

class AccessLog
  include ChainedSetter

  chained_setter :rotationInterval
  chained_setter :fileNamePattern
  chained_setter :symlinkName
  chained_setter :compressionFormat


  def initialize(type)
    @type = type
  end

  def to_xml(indent="")
    XmlHelper.new(indent).
      tag("accesslog",
          :type => @type,
          :fileNamePattern => @fileNamePattern,
          :symlinkName => @symlinkName,
          :compressionFormat => @compressionFormat,
          :rotationInterval => @rotationInterval).to_s
  end
end

class ConcreteDoc
  include ChainedSetter

  chained_setter :klass
  chained_setter :config
  chained_setter :bundle

  def initialize(name)
    @name = name
    @config = ConfigOverrides.new
    @bundle = 'concretedocs'
    @klass = 'com.yahoo.concretedocs.' + name.capitalize
  end

  def to_xml(indent="")
    dump_xml(indent)
  end

  def dump_xml(indent="", tagname='document')
    XmlHelper.new(indent).
        tag(tagname,
            :type => @name,
            :bundle => @bundle,
            :class => @klass).
        to_xml(@config).to_s
  end
end
