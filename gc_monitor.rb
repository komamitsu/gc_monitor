require 'pp'
require 'socket'

module GcMonitor
  @@gc_monitor_objs = {}   # TODO
  
  class << self
    def regist(obj, caller)
      @@gc_monitor_objs[obj.to_s] = [Time.now, caller]
    end

    def release(obj, caller)
      @@gc_monitor_objs.delete(obj.to_s)
    end

    def dump
      @@gc_monitor_objs
    end

    def release_proc(proc_str)
      lambda {
        instance_eval(proc_str)
        GcMonitor.release(self)
      }
    end

    def included(base)
      base.__send__(:alias_method, :initialize_without_gc_monitor_pre, :initialize)
      base.__send__(:alias_method, :initialize, :initialize_with_gc_monitor_pre)

      def base.method_added(name)
        return unless name == :initialize
        return if @is_made_initialize_with_gc_monitor_post
        @is_made_initialize_with_gc_monitor_post = true
        alias_method :initialize_without_gc_monitor_post, :initialize
        alias_method :initialize, :initialize_with_gc_monitor_post
      end

      def base.release_hook(proc_str)
        @@gc_monitor_release_hook = proc_str
      end
    end

    def tcp_server(host, port)
      Thread.new do
        s = TCPServer.new(host, port)
        loop do
          Thread.new(s.accept) do |c|
            while command = c.gets.strip
              next if command.empty?

              case command
              when 'dump'
                GcMonitor.dump.each do |obj|
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

  def initialize_with_gc_monitor_pre(*args)
    initialize_without_gc_monitor_pre(*args)
    regist_gc_monitor(caller)
  end
  
  def initialize_with_gc_monitor_post(*args)
    initialize_without_gc_monitor_post(*args)
    regist_gc_monitor(caller)
  end
end

if $0 == __FILE__
  class Hoge
    def initialize(name)
      @name = name
    end
    include GcMonitor
  end

  Hoge.release_hook('puts "i am released."')
  GcMonitor.tcp_server('0.0.0.0', 54321)

  20.times do
    Hoge.new('a' * 50 * 1024 * 1024)
    sleep 1
  end

  # p GcMonitor.dump.size
end
