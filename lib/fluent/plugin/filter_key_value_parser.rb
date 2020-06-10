require 'fluent/filter'
require 'fluent/parser'

module Fluent
  class KeyValueParser < Filter
    Fluent::Plugin.register_filter('key_value_parser', self)

    config_param :key, :string, default: 'log'
    config_param :remove_key, :bool, default: false
    config_param :filter_out_lines_without_keys, :bool, default: false
    config_param :use_regex, :bool, default: false
    config_param :remove_prefix, :string, default: ''
    config_param :keys_delimiter, :string, default: '/\s+/'
    config_param :kv_delimiter_chart, :string, default: '='
    config_param :filtered_keys, :string, default: nil
    config_param :filtered_keys_regex, :string, default: nil
    config_param :filtered_keys_delimiter, :string, default: ','


    def configure(conf)
      super

      regex = /^\/.+\/$/

      if regex.match(@keys_delimiter.to_s)
        @keys_delimiter = Regexp.new(@keys_delimiter[1..-2])
      end

      if regex.match(@remove_prefix.to_s)
        @remove_prefix = Regexp.new(@remove_prefix[1..-2])
      end

      if regex.match(@filtered_keys_regex.to_s)
         @filtered_keys_regex = Regexp.new(@filtered_keys_regex[1..-2])
      end

      @filtered_keys_list = parse_filtered_keys_parameter
    end

    def filter(tag, time, record)
      return if record[@key].nil?

      keys = extracted_keys(extract_log_line(record[@key]))

      return if @filter_out_lines_without_keys && keys.empty?

      record.merge! keys
      record.tap { |r| r.delete(@key) if @remove_key }.compact
    end

    private

    def regex_filter(line)
      "#{line} ".scan(/(?<key>[a-zA-Z_0-9]+)=(?<value>([^=]+|[^ ]+))\s/).to_h
    end

    def extracted_keys(line)
      keys = @use_regex ? regex_filter(line) : delimiter_filter(line)
      filtered_keys = @filtered_keys_list.empty? ? keys : keys.slice(*@filtered_keys_list)
      @filtered_keys_regex.nil? ? filtered_keys : filtered_keys.merge(keys.select{ |k,v| @filtered_keys_regex.match(k.to_s)})
    end

    def delimiter_filter(line)
      items = {}
      line.split(@keys_delimiter).each do |kv|
        key, value = kv.split(@kv_delimiter_chart, 2)
        items[key] = value if value
      end
      items
    end

    def parse_filtered_keys_parameter
      @filtered_keys.to_s.split(@filtered_keys_delimiter)
    end

    def extract_log_line(line)
      line.gsub(@remove_prefix,'').strip
    end
  end
end
