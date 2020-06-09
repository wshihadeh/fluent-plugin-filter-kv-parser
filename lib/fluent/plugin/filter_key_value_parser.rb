require 'fluent/filter'
require 'fluent/parser'

module Fluent
  class KeyValueParser < Filter
    Fluent::Plugin.register_filter('key_value_parser', self)

    config_param :key, :string, default: 'log'
    config_param :remove_key, :bool, default: false
    config_param :use_regex, :bool, default: false
    config_param :remove_prefix, :string, default: ''
    config_param :keys_delimiter, :string, default: '/\s+/'
    config_param :kv_delimiter_chart, :string, default: '='
    config_param :filtered_keys, :string, default: nil
    config_param :filtered_keys_delimiter, :string, default: ','


    def configure(conf)
      super
      if @keys_delimiter[0] == '/' and @keys_delimiter[-1] == '/'
        @keys_delimiter = Regexp.new(@keys_delimiter[1..-2])
      end

      if @remove_prefix[0] == '/' and @remove_prefix[-1] == '/'
        @remove_prefix = Regexp.new(@remove_prefix[1..-2])
      end

      @filtered_keys_list = parse_filtered_keys_parameter
    end

    def filter(tag, time, record)
      return if record[@key].nil?

      log_line = extract_log_line record[@key]

      if @use_regex
        extracted_keys = regex_filter(log_line)
      else
        extracted_keys = delimiter_filter(log_line)
      end

      extracted_keys = extracted_keys.slice(*@filtered_keys_list) unless @filtered_keys_list.empty?
      record.merge! extracted_keys
      record.tap { |r| r.delete(@key) if @remove_key }.compact
    end

    private

    def regex_filter(line)
      "#{line} ".scan(/(?<key>[a-zA-Z_0-9]+)=(?<value>[^=]+)\s/).to_h
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
