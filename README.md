# Geetest

Geetest sdk v3 in ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'geetest', github: 'zhulux/geetest-ruby-sdk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install geetest

## Usage

```ruby
# @doc https://docs.geetest.com/install/deploy/server/python
def behavior_verification_step_one
  # status=1表示初始化成功，status=0表示宕机状态
  status, response_h = $geetest.pre_process(nil, 0, 0, 'web', request.remote_ip)

  render json: response_h
end

def behavior_verification_step_two
  challenge = behavior_verification_params[:geetest_challenge]
  validate = behavior_verification_params[:geetest_validate]
  seccode = behavior_verification_params[:geetest_seccode]
  status = 1
  result = if status == 1
             $geetest.success_validate(challenge, validate, seccode, nil, nil, '', '', 0)
           else
             $geetest.failback_validate(challenge, validate, seccode)
           end
  render json: { status: result }
end

def behavior_verification_params
  params.permit(:geetest_challenge, :geetest_validate, :geetest_seccode)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/geetest. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Geetest project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/geetest/blob/master/CODE_OF_CONDUCT.md).
