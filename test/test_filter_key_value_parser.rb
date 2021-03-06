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

  test 'test_empty_line' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 1, filtered.count
    assert_equal false,  filtered.key?("log")
  end

  test 'test_two_log_key' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    msg2 = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg, msg2])
    assert_equal 2, filtered.count
  end

  test 'test_no_log_key' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
    }
    msg2 = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg, msg2])
    assert_equal 1, filtered.count
  end

  test 'test_with_space_and_regex' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
        use_regex true
      ])
    msg = {
      'time' => '2013-02-12 22:01:15 UTC',
      'log'  => "Start Request key=10 skey='this is a miltispace line' akey=20 zkey=30 dkey=4",
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 6, filtered.count
    assert_equal "'this is a miltispace line'", filtered['skey']
    assert_equal false,  filtered.key?("log")
  end

  test 'test_filter_keys' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
        use_regex true
        filtered_keys key,gkeyn,nkey,skey,akey,zkey
      ])
    msg = {
      'time' => '2013-02-12 22:01:15 UTC',
      'log'  => "Start Request key=10 gkey=100 nkey=108 skey='this is a miltispace line' akey=20 zkey=30 dkey=4",
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 6, filtered.count
    assert_equal "'this is a miltispace line'", filtered['skey']
    assert_equal false,  filtered.key?("log")
  end

  test 'test_filter_keys_with_regex' do
    d = create_driver(%[
        key log
        remove_key true
        remove_prefix /^[^ ]+\s[^ ]+/
        use_regex true
        filtered_keys key,gkeyn,nkey,skey,akey,zkey
        filtered_keys_regex /^sub_[a-zA-Z_0-9]+/
      ])
    msg = {
      'time' => '2013-02-12 22:01:15 UTC',
      'log'  => "Start Request sub_key=0 sub_akey=11 sub_zkey=12 key=10 gkey=100 nkey=108 skey='this is a miltispace line' akey=20 zkey=30 dkey=4",
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal 9, filtered.count
    assert_equal "'this is a miltispace line'", filtered['skey']
    assert_equal "0", filtered['sub_key']
    assert_equal false,  filtered.key?("log")
  end

  test 'test_filter_out_lines_without_keys' do
    d = create_driver(%[
        key log
        remove_key true
        use_regex true
        filtered_keys_regex /^sub_[a-zA-Z_0-9]+/
        filter_out_lines_without_keys true
      ])
    msg = {
      'time' => '2013-02-12 22:01:15 UTC',
      'log'  => "akey=10 bkey=11 ckey=11",
    }

    msg2 = {
      'time' => '2013-02-12 22:01:15 UTC',
      'log'  => "Start Request to test lines without any keys",
    }
    filtered = filter(d, [msg, msg2])

    assert_equal 1, filtered.count
    assert_equal 4, filtered.first[2].count
    assert_equal "10", filtered.first[2]['akey']
  end

  test 'test_keys_prefix' do
    d = create_driver(%[
        key log
        keys_prefix test
      ])
    msg = {
      'time'      => '2013-02-12 22:01:15 UTC',
      'log'      => 'Start Request key=10 akey=20 zkey=30 dkey=40',
    }
    filtered = filter(d, [msg]).first[2]
    assert_equal false,  filtered.key?("key")
    assert_equal true,  filtered.key?("test.key")
  end
end
