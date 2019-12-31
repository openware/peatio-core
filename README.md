# Peatio Core

Peatio Core is a part of Peatio cryptocurrency exchange platform exposed as a Ruby gem and implementing some authentication, database, AMQP and other critical stuff.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'peatio', '~> 2.4.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install peatio

## Configuration variables

| Name                    | Description                          | Default value                  |
|-------------------------|--------------------------------------|--------------------------------|
| `LOG_LEVEL`             | Logger level                         | info                           |
| `RABBITMQ_HOST`         |                                      | 0.0.0.0                        |
| `RABBITMQ_PORT`         |                                      | 5672                           |
| `RABBITMQ_USER`         |                                      | guest                          |
| `RABBITMQ_PASSWORD`     |                                      | guest                          |
| `DATABASE_HOST`         |                                      | localhost                      |
| `DATABASE_USER`         |                                      | root                           |
| `DATABASE_PASS`         |                                      | Empty password used by default |
| `DATABASE_PORT`         |                                      | 3306                           |
| `DATABASE_NAME`         |                                      | peatio_development             |
| `RANGER_HOST`           | WebSocket server binding host        | 0.0.0.0                        |
| `RANGER_PORT`           | WebSocket server binding port        | 8081                           |
| `METRICS_HOST`          | Thin Web server metrics binding host | 0.0.0.0                        |
| `METRICS_PORT`          | Thin Web server metrics binding port | 8082                           |
| `JWT_ISSUER`            |                                      |                                |
| `JWT_AUDIENCE`          |                                      |                                |
| `JWT_ALGORITHM`         |                                      | RS256                          |
| `JWT_DEFAULT_LEEWAY`    |                                      |                                |
| `JWT_ISSUED_AT_LEEWAY`  |                                      |                                |
| `JWT_EXPIRATION_LEEWAY` |                                      |                                |
| `JWT_NOT_BEFORE_LEEWAY` |                                      |                                |
| `JWT_PUBLIC_KEY`        | Base64-encoded RSA public key        |                                |
| `WEBSOCKET_HOST`        | Used for testing                     | 0.0.0.0                        |
| `WEBSOCKET_PORT`        | Used for testing                     | 13579                          |

## Usage

### Start Ranger WebSocket server

Command:
```
JWT_PUBLIC_KEY=RSA_PUBLIC_KEY_BASE64 bundle exec peatio service start ranger
``` 

Check out `bundle exec peatio service start ranger --help` for more information about available options.

You also may need to adjust environment variables (see above).

### Generate RSA keypair and print or save to file

Command:
```
bundle exec peatio security keygen --print
```

Result:
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAv5QEw1nKyex1+MKMJM+CC1qhS6er3dpRZYxQvwK1l3shODgq
haAuJuxLK/RHzvzfsrtGtkmGv6wvJtsdM6muNQo8Jpqy9yXyY1d+HGq1sLgcI6LE
+/hU35JbwXkF5JT4oep0NCM4YNOlZB1Kd6DwdeHPk079DEMxpFo0KDiFmdnRakVc
dl4tki2ZUkeI5uNFFFUWjDsU39guIOIeKOeEANi08FBgpcfbUhM1a/i4VOHXBFfp
nk91lB1TANiy0rZlUhfIdT7/uiokDc06Fnd8XZErtxEiCXueNU9vRZLE/Rqms2Hm
ZKumY8aQ/nHFzw+DfxfjT72HuCH/8S1mSI19YQIDAQABAoIBAA0gDPt9SWFwK9zx
JzzWYqh4exh90k6OyIjWhimv+9T3AJ2ja3ZgNQlBoxzNzaWmuYS7Q+r1OqAjIc/d
rzB87YyAuQJEEwLPvL2FnwQ/Y1dKJdNjMW+54ca3dkXZDshMVIRzVabEyvYHSguD
3jg39IF/CQOko72VVO9Xpr8isDSME1zbfLDdA0K7O2wv1HrrvXvWc5ji9LtLnm3h
n+ru4VDNXSrtsQS44r/NeYcjZ72VC8JfTmCZMlHY4uwSrfOtXMHq1/wTE5dPlDA9
6m49AzO6fPV8Q2kEW45XsHa3zZlcKi5vbrxqQoWKOUXbod/EL73OHyHmeK6QAbZl
DQtj2uECgYEA7OY+vVYj/dY2bRCWlfhfDtXHUbXOTE6jSfYYuCu9zmN+CILyS4j1
GL5IrhF4QKdrsbxudkp3V2zP3CINjZfseP+6Di/fMc8XBHFwrk27jGcEqwGtG/ss
LLaQf4rEJ8JZcNLF30lHk+NzfMiW5pc0NAf0dS73ed2hmcnBRX0yrIUCgYEAzwZQ
p1DvfS0ObSxo9Q40XfOGY5tTQyLrIPloe7ywmBlEcG4d4s0e9olJmP5Pud+XI2Aj
yq5LlDr2EpUJv0PzSqqmJJwXaeQNViC+6qY25RZ+x6MwqJdjmBybp6OHjf8+cV4Q
18rxMIC897Kq4U4W3N1RcgD7RgMOsbvY8iFloi0CgYEAhEVKYozmK6SfXuYULkgv
Sykx0P2h4hlGMtWll69UmxgSFs6GWoZt0xLrocU/T1orV2HOi12opLesl0ysJJLf
BfBDAgjYpgbq4yAzuh7MyOf8Qz78WNM1JwIITC4+t7RcHBKTSMixnnEw2ktldfqW
uzZ117gRlYmZ4TQ1JYdx88ECgYAhL/f5+oWJ4ZEwezAQKMjITuO6UAoW9yAOVy0i
uOruVw6bn2t3Ej7mcrezqQEK4QcPirfyI+LFznXoILBBUxlLXPPpZoRyWzawGevB
HggqzWJhio2gWTSEDAH/670tTD+sWNIGZegoSFsCskemeqg7m9cUmYeuf4r5fw2W
MzhhuQKBgQCLN/tGXu4fsHM6mHy7m6rlBMzuhGzoFdtoefeULvLvk5KBRdSFPT8h
UdF36wFDsqBMFJO9qHy94IYujCRXIUbeeJjUslQVcGRnlDVx3NvcuyD3cqgCPEYG
Dkst0skvrA5HF4SqMFpUBT2aoA8mVQVO5RplRJtP2g7u+QQ62g4gZw==
-----END RSA PRIVATE KEY-----
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv5QEw1nKyex1+MKMJM+C
C1qhS6er3dpRZYxQvwK1l3shODgqhaAuJuxLK/RHzvzfsrtGtkmGv6wvJtsdM6mu
NQo8Jpqy9yXyY1d+HGq1sLgcI6LE+/hU35JbwXkF5JT4oep0NCM4YNOlZB1Kd6Dw
deHPk079DEMxpFo0KDiFmdnRakVcdl4tki2ZUkeI5uNFFFUWjDsU39guIOIeKOeE
ANi08FBgpcfbUhM1a/i4VOHXBFfpnk91lB1TANiy0rZlUhfIdT7/uiokDc06Fnd8
XZErtxEiCXueNU9vRZLE/Rqms2HmZKumY8aQ/nHFzw+DfxfjT72HuCH/8S1mSI19
YQIDAQAB
-----END PUBLIC KEY-----
-----BASE64 ENCODED-----
LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF2NVFFdzFuS3lleDErTUtNSk0rQwpDMXFoUzZlcjNkcFJaWXhRdndLMWwzc2hPRGdxaGFBdUp1eExLL1JIenZ6ZnNydEd0a21HdjZ3dkp0c2RNNm11Ck5RbzhKcHF5OXlYeVkxZCtIR3Exc0xnY0k2TEUrL2hVMzVKYndYa0Y1SlQ0b2VwME5DTTRZTk9sWkIxS2Q2RHcKZGVIUGswNzlERU14cEZvMEtEaUZtZG5SYWtWY2RsNHRraTJaVWtlSTV1TkZGRlVXakRzVTM5Z3VJT0llS09lRQpBTmkwOEZCZ3BjZmJVaE0xYS9pNFZPSFhCRmZwbms5MWxCMVRBTml5MHJabFVoZklkVDcvdWlva0RjMDZGbmQ4ClhaRXJ0eEVpQ1h1ZU5VOXZSWkxFL1JxbXMySG1aS3VtWThhUS9uSEZ6dytEZnhmalQ3Mkh1Q0gvOFMxbVNJMTkKWVFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==
```

Check out `bundle exec peatio security keygen --help` for more information.

### Create database

```
bundle exec peatio db create
```

### Run database migrations

This command will create important tables related to account management, trades and orders: `operations`, `orders`, `trades`.

```
bundle exec peatio db migrate
```

### Publish events to RabbitMQ (debugging purposes)

Command:
```
bundle exec peatio inject peatio_events
```

Result:
```
D, [2019-12-31T16:20:07.391515 #38502] DEBUG -- : published event to public.global.tickers
D, [2019-12-31T16:20:07.391739 #38502] DEBUG -- : published event to public.eurusd.update
D, [2019-12-31T16:20:07.391857 #38502] DEBUG -- : published event to private.IDABC0000001.order
D, [2019-12-31T16:20:07.391961 #38502] DEBUG -- : published event to private.IDABC0000001.trade
D, [2019-12-31T16:20:07.392056 #38502] DEBUG -- : published event to private.IDABC0000002.trade
D, [2019-12-31T16:20:07.392170 #38502] DEBUG -- : published event to public.eurusd.trades
D, [2019-12-31T16:20:07.392266 #38502] DEBUG -- : published event to public.eurusd.ob-inc
D, [2019-12-31T16:20:07.392378 #38502] DEBUG -- : published event to public.eurusd.ob-snap
D, [2019-12-31T16:20:07.392473 #38502] DEBUG -- : published event to public.eurusd.ob-inc
D, [2019-12-31T16:20:07.392560 #38502] DEBUG -- : published event to public.eurusd.ob-inc
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/openware/peatio-core.
