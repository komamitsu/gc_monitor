# GcMonitor

GcMonitor is Ruby library for monitoring GC.

## Installation

Add this line to your application's Gemfile:

    gem 'gc_monitor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gc_monitor

## Usage

If you want to monitor the specific class, then include GcMonitor into the class.
  
    require 'gc_monitor'

    class Foo
      attr_accessor :dummy
    end

    class Foo
      include GcMonitor
    end

    Foo.release_hook('puts "i am released."')  # This is option hook, for debug.

    15.times do
      o = Foo.new
      o.dummy = 'x' * 100 * 1024 * 1024  # For GC.
      sleep 0.5
    end

    GcMonitor.list.each{|rec| p rec}  # Array of the remaining objects (not garbage collected).

    # You can filter the objects by :time keyword.
    GcMonitor.list(:time => 8).each{|rec| p rec}  # Only older than 8 sec.

Then "i am released." will be printed when some Foo instances are collected. At the last code, the remaining objects will be dumped.

    i am released.
       :
    i am released.
    ["Foo__fdbef6946", {:time=>Sun Aug 09 00:11:49 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8f52", {:time=>Sun Aug 09 00:11:50 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8dfe", {:time=>Sun Aug 09 00:11:55 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8c28", {:time=>Sun Aug 09 00:11:57 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8912", {:time=>Sun Aug 09 00:11:59 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef87c8", {:time=>Sun Aug 09 00:12:00 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef84ee", {:time=>Sun Aug 09 00:12:02 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8386", {:time=>Sun Aug 09 00:12:04 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8110", {:time=>Sun Aug 09 00:12:05 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef7ea4", {:time=>Sun Aug 09 00:12:07 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8f3e", {:time=>Sun Aug 09 00:12:09 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8f34", {:time=>Sun Aug 09 00:12:10 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    ["Foo__fdbef8e76", {:time=>Sun Aug 09 00:12:12 +0900 2009, :caller=>["gc_monitor.rb:136:in `new'", "gc_monitor.rb:136", "gc_monitor.rb:135:in `times'", "gc_monitor.rb:135"]}]
    i am released.
       :
    i am released.

You can monitor almost all of classes. Instead of "include GcMonitor" in the class definition, call GcMonitor.include_in_subclasses. But some classes are not supported, Time (sorry...) and implemented classes in ruby such as String and so on.

    GcMonitor.include_in_subclasses(Object)  # If you monitor IO and the sub classes, set the argument IO.

Finally, there is TCP/IP interface.

    GcMonitor.tcp_server('0.0.0.0', 4321)

And using TCP/IP client, you can monitor the realtime information by 'list' command.

    $ telnet localhost 4321
    Trying ::1...
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    list
    now: Sun Aug 09 00:48:59 +0900 2009
    ["Rational__fdbe7752e", {:time=>Sun Aug 09 00:48:56 +0900 2009, :caller=>["/usr/lib/ruby/1.8/rational.rb:94:in `new'", "/usr/lib/ruby/1.8/rational.rb:94:in `new!'", "/usr/lib/ruby/1.8/rational.rb:337:in `coerce'", "/usr/lib/ruby/1.8/date.rb:503:in `-'", "/usr/lib/ruby/1.8/date.rb:503:in `jd_to_ajd'", "/usr/lib/ruby/1.8/date.rb:754:in `new'", "gc_monitor.rb:155", "gc_monitor.rb:154:in `times'", "gc_monitor.rb:154"]}]
      :
    list 8   <== Only the remaining objects older than 8 sec ago.
      :
    quit     <== Command for quit TCP/IP interface.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
