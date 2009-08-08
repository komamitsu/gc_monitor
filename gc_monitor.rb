module GcMonitor
  class << self
    def include_in_subclasses(klass = Object)
      ObjectSpace.each_object(class << klass; self; end) do |cls|
        next if cls.ancestors.include?(Exception)
        next if [GcMonitor, Time].include?(cls)
        cls.__send__(:include, GcMonitor)
      end
    end

    def key(obj)
      sprintf("%s__%0x", obj.class, obj.object_id)
    end

    def regist(obj, caller)
      @gc_monitor_objs ||= {}
      @gc_monitor_objs[GcMonitor.key(obj)] = {:time => Time.now, :caller => caller}
    end

    def release(obj, caller)
      @gc_monitor_objs.delete(GcMonitor.key(obj))
    end

    def list(cond = {})
      cond.keys.inject(@gc_monitor_objs) {|objs, cond_key|
        new_objs = nil

        case cond_key
        when :time
          now = Time.now
          new_objs = objs.select do |obj_k, obj_v|
            obj_v[:time] < now - cond[cond_key]
          end
        else
          raise "Invalid list option [#{cond_key}]"
        end

        new_objs
      }.sort_by{|k, v| v[:time]}
    end

    def release_proc(proc_str)
      lambda {
        instance_eval(proc_str)
        GcMonitor.release(self)
      }
    end

    def included(base)
      class << base
        return if @gc_monitor_included
        @gc_monitor_included = true
      end
      return unless base.private_methods.include?("initialize")
      begin
        base.__send__(:alias_method, :initialize_without_gc_monitor_pre, :initialize)
      rescue NameError
        return
      end
      base.__send__(:alias_method, :initialize, :initialize_with_gc_monitor_pre)

      def base.method_added(name)
        return unless name == :initialize
        return if @made_initialize_with_gc_monitor_post
        @made_initialize_with_gc_monitor_post = true
        alias_method :initialize_without_gc_monitor_post, :initialize
        alias_method :initialize, :initialize_with_gc_monitor_post
      end

      def base.release_hook(proc_str)
        @@gc_monitor_release_hook = proc_str
      end
    end

    def tcp_server(host, port)
      require 'socket'

      Thread.new do
        s = TCPServer.new(host, port)
        loop do
          Thread.new(s.accept) do |c|
            while command_line = c.gets.strip
              next if command_line.empty?

              command, *args = command_line.split(/\s+/)

              case command
              when 'list'
                cond = args.empty? ? {} : {:time => Integer(args[0])}
                c.puts "now: #{Time.now}"
                GcMonitor.list(cond).each do |obj|
                  c.puts(obj.inspect)
                end
              when 'quit'
                c.close
                Thread.exit
              else
                c.puts 'unknown command'
              end
            end
          end
        end
      end
    end
  end

  private
  def regist_gc_monitor(caller)
    GcMonitor.regist(self, caller)
    @@gc_monitor_release_hook ||= nil
    ObjectSpace.define_finalizer(self, GcMonitor.release_proc(@@gc_monitor_release_hook))
  end

  def initialize_with_gc_monitor_pre(*args, &blk)
    initialize_without_gc_monitor_pre(*args, &blk)
    regist_gc_monitor(caller)
  end
  
  def initialize_with_gc_monitor_post(*args, &blk)
    initialize_without_gc_monitor_post(*args, &blk)
    regist_gc_monitor(caller)
  end
end

if $0 == __FILE__
  require 'date'

  class Date
    attr_accessor :dummy
  end

  GcMonitor.include_in_subclasses(Object)

  Date.release_hook('puts "i am released."')
  GcMonitor.tcp_server('0.0.0.0', 4321)

  10.times do
    o = Date.new
    o.dummy = 'x' * 50 * 1024 * 1024
    sleep 0.5
  end

  # GcMonitor.list(:time => 8).each{|rec| p rec} 
  GcMonitor.list.each{|rec| p rec} 
end

