require_relative 'helper'
require 'fluent/plugin/filter_key_value_parser'

class KeyValueFilterTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf = '')
    Test::FilterTestDriver.new(KeyValueParser).configure(conf, true)
  end

  def filter(d, msgs)
    d.run {
      msgs.each {|msg|
        d.filter(msg, @time)
      }
    }
    d.filtered_as_array
  end

  test 'test_key_value_parser' do
    d = create_driver(%[
        key log
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 6, filtered.count
    assert_equal true,  filtered.key?("time")
    assert_equal true,  filtered.key?("log")
    assert_equal true,  filtered.key?("key")
    assert_equal true,  filtered.key?("akey")
    assert_equal true,  filtered.key?("zkey")
    assert_equal true,  filtered.key?("dkey")
  end

  test 'test_remove_key' do
    d = create_driver(%[
        key log
        remove_key true
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 5, filtered.count
    assert_equal false,  filtered.key?("log")
  end

  test 'test_remove_prefix_str' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix 'Start Request'
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 5, filtered.count
    assert_equal false,  filtered.key?("log")
  end

  test 'test_remove_prefix_regex' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 5, filtered.count
    assert_equal false,  filtered.key?("log")
  end
end
