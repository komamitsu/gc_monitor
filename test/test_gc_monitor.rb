require File.dirname(__FILE__) + '/test_helper.rb'

class Foo
  attr_accessor :dummy
  include GcMonitor
end

class TestGcMonitor < Test::Unit::TestCase

  def setup
  end
  
  def test_exit_normal
    Foo.release_hook('puts "i am released."')  # This is option hook, for debug.
    # GcMonitor.tcp_server('0.0.0.0', 4321)

    10.times do
      o = Foo.new
      o.dummy = 'x' * 10 * 1024 * 1024  # For GC.
      sleep 0.5
    end

    # You can filter the objects with using :time keyword.
    assert GcMonitor.list(:time => 8).kind_of? Array
  end
end
