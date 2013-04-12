require "gc_monitor/version"
require 'thread'

module GcMonitor
  class << self
    def include_in_subclasses(klass = Object)
      ObjectSpace.each_object(class << klass; self; end) do |cls|
        next if cls.ancestors.include?(Exception)
        next if out_of_scope?(cls)
        cls.__send__(:include, GcMonitor)
      end
    end

    def list_remaining_objects(cond = {})
      gc_monitor_mutex.synchronize do
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

    def included(base)
      class << base
        @gc_monitor_included ||= false
        return if @gc_monitor_included
        @gc_monitor_included = true
      end

      return unless base.private_methods.include?(:initialize)
      begin
        base.__send__(:alias_method, :initialize_without_gc_monitor_pre, :initialize)
      rescue NameError
        return
      end
      base.__send__(:alias_method, :initialize, :initialize_with_gc_monitor_pre)

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

    def gc_monitor_register(obj, caller)
      return if out_of_scope?(obj.class)
      gc_monitor_mutex.synchronize do
        remaining_objects[GcMonitor.gc_monitor_key(obj)] = {:time => Time.now, :caller => caller}
      end
    end

    def gc_monitor_key(obj)
      sprintf("%s__%0x", obj.class, obj.object_id)
    end

    def gc_monitor_release_proc(klass, key, proc_str)
      proc {
        instance_eval(proc_str)
        gc_monitor_release(klass, key)
      }
    end

    def gc_monitor_release(klass, key)
      return if out_of_scope?(klass)
      gc_monitor_mutex.synchronize do
        remaining_objects.delete(key)
      end
    end

    private
    def gc_monitor_mutex
      @gc_monitor_mutex ||= Mutex.new
      @gc_monitor_mutex
    end

    def out_of_scope?(klass)
      [GcMonitor, Time, Mutex].include?(klass)
    end

    def remaining_objects
      @remaining_objects ||= {}
      @remaining_objects
    end
  end

  private
  def register_gc_monitor(caller)
    GcMonitor.gc_monitor_register(self, caller)
    @@gc_monitor_release_hook ||= nil
    prc = GcMonitor.gc_monitor_release_proc(
      self.class,
      GcMonitor.gc_monitor_key(self),
      @@gc_monitor_release_hook
    )
    ObjectSpace.define_finalizer(self, prc)
    # ObjectSpace.define_finalizer(self, proc {|id| puts "hoge #{id}"})
  end

  def initialize_with_gc_monitor_pre(*args, &blk)
    return if caller.detect{|c| c =~ /in `initialize(?:_with_gc_monitor_pre)?'\z/}
    initialize_without_gc_monitor_pre(*args, &blk)
    register_gc_monitor(caller)
  end
end

