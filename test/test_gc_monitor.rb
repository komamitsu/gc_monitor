require File.dirname(__FILE__) + '/test_helper.rb'

class AP
  attr_reader :something
  def initialize(something)
    @something = something
  end
end

class AC < AP
end

class BP
  attr_reader :something
  def initialize(something)
    @something = something
  end
end

class BC < BP
  attr_reader :something_else
  def initialize(something_else)
    @something_else = something_else
    super
  end
end

class CP
end

class CC < CP
  attr_reader :something
  def initialize(something)
    @something = something
  end
end

class DP
  attr_reader :something
  attr_accessor :value
  def initialize(something)
    @something = something
  end
end

class DC < DP
  attr_reader :something_else
  def initialize(something_else)
    @something_else = something_else
    super
  end
end

class EP
  attr_reader :something
  def initialize(something)
    @something = something
  end
end

class EC < EP
  attr_reader :something_else
  attr_accessor :value
  def initialize(something_else)
    @something_else = something_else
    super
  end
end

class FP
  attr_accessor :value
end

class FC < FP
end

class GP
end

class GC_ < GP
  attr_accessor :value
end

class HP
  attr_reader :something
  def initialize(something, &blk)
    @something = something
    @proc = blk
  end

  def do_it
    @proc.call
  end
end

class HC < HP
end

class IP
end

class IC < IP
  attr_reader :something
  def initialize(something, &blk)
    @something = something
    @proc = blk
  end

  def do_it
    @proc.call
  end
end

[AC, BC, CC, DC, EC, FC, GC_, HC, IC].each do |c|
  GcMonitor.include_in_subclasses(c)
  c.release_hook('puts "i am released."')
end

class TestGcMonitor < Test::Unit::TestCase

  def setup
  end
  
  def test_exit_normal
    GcMonitor.tcp_server('0.0.0.0', 4321)

    # dummy_str = 'x' * 1 * 1024 * 1024
    dummy_str = 'x' * 10
    2.times do
      a = AC.new(dummy_str.clone)
      assert_equal dummy_str, a.something

      b = BC.new(dummy_str.clone)
      assert_equal dummy_str, b.something
      assert_equal dummy_str, b.something_else

      c = CC.new(dummy_str.clone)
      assert_equal dummy_str, c.something

      d = DC.new(dummy_str.clone)
      d.value = dummy_str.clone 
      assert_equal dummy_str, d.something
      assert_equal dummy_str, d.something_else
      assert_equal dummy_str, d.value

      e = EC.new(dummy_str.clone)
      e.value = dummy_str.clone 
      assert_equal dummy_str, e.something
      assert_equal dummy_str, e.something_else
      assert_equal dummy_str, e.value

      f = FC.new
      f.value = dummy_str.clone
      assert_equal dummy_str, f.value

      g = GC_.new
      g.value = dummy_str.clone
      assert_equal dummy_str, g.value
      
      h = HC.new(dummy_str.clone) { dummy_str.clone }
      assert_equal dummy_str, h.something
      assert_equal dummy_str, h.do_it

      i = IC.new(dummy_str.clone) { dummy_str.clone }
      assert_equal dummy_str, i.something
      assert_equal dummy_str, i.do_it

      sleep 1
    end

    # You can filter the objects with using :time keyword.
    assert GcMonitor.list(:time => 8).kind_of? Array
  end
end
