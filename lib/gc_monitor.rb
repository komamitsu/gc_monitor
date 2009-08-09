require 'thread'

module GcMonitor
  VERSION = '0.0.1'

  class << self
    def remaining_objects
      @remaining_objects ||= {}
      @remaining_objects
    end

    def mutex
      @mutex ||= Mutex.new
      @mutex
    end

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
      mutex.synchronize do
        remaining_objects[GcMonitor.key(obj)] = {:time => Time.now, :caller => caller}
      end
    end

    def release(obj, caller)
      mutex.synchronize do
        remaining_objects.delete(GcMonitor.key(obj))
      end
    end

    def list(cond = {})
      mutex.synchronize do
        cond.keys.inject(remaining_objects) {|objs, cond_key|
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

