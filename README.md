# fluent-plugin-filter-kv-parser

A Fluentd filter plugin to parse key value items

## Requirements

Fluentd >= v0.12

## Install

Use RubyGems:

```
gem install fluent-plugin-filter-kv-parser
```

## Configuration Examples

```
<filter **>
  type key_value_parser
  key log
  remove_prefix /^prefix/
  keys_delimiter /\s+/
  kv_delimiter_chart '='
</filter>

<match **>
  type stdout
</match>
```


## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2015 Naotoshi Seo. See [LICENSE](LICENSE) for details.