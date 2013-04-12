require 'spec_helper'

describe GcMonitor do
  context "when included" do
    class Foo
      attr_accessor :dummy
    end

    class Foo
      include GcMonitor
    end

    $output = StringIO.new
    Foo.release_hook("$output.puts 'hoge'")

    total_obj_num = 10
    gc_obj_num = 4
    foos = []
    10.times do
      foos << Foo.new
    end

    gc_obj_num.times do |i|
      foos[i] = nil
    end
    GC.start

    describe 'GcMonitor#release_fook' do
      msg_count = 0
      $output.rewind
      $output.each_line do |line|
        msg_count += 1
        it { expect(line).to eq("hoge\n") }
      end
      it { expect(msg_count).to eq(gc_obj_num) }
    end

    describe 'GcMonitor#list_remaining_objects' do
      remains = GcMonitor.list_remaining_objects
      it { expect(remains.size).to eq(total_obj_num - gc_obj_num) }

      # You can filter the objects by :time keyword.
      # GcMonitor.list(:time => 8).each{|rec| p rec}  # Only older than 8 sec.
    end
  end
end

