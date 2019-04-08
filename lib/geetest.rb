require 'geetest/version'
require 'net/http'
require 'uri'
require 'digest'
require 'json'

# https://docs.geetest.com/install/help/glossary/#API1
# copy from https://github.com/GeeTeam/gt3-python-sdk
module Geetest
  class API
    API_VERSION = '3.0.0'.freeze
    # 极验验证二次验证表单数据 chllenge
    FN_CHALLENGE = 'geetest_challenge'.freeze
    # 极验验证二次验证表单数据 validate
    FN_VALIDATE = 'geetest_validate'.freeze
    # 极验验证二次验证表单数据 seccode
    FN_SECCODE = 'geetest_seccode'.freeze

    GT_STATUS_SESSION_KEY = 'gt_server_status'.freeze

    API_URL = 'http://api.geetest.com'.freeze
    REGISTER_HANDLER = '/register.php'.freeze
    VALIDATE_HANDLER = '/validate.php'.freeze

    def initialize(captcha_id, private_key)
      @captcha_id = captcha_id # 公钥
      @private_key = private_key # 私钥
      @sdk_version = API_VERSION
      @_response_str = ''
    end

    def pre_process(user_id = nil, new_captcha = 1, jf = 1, client_type = 'web', ip_address = '')
      status, challenge = _register(user_id, new_captcha, jf, client_type, ip_address)
      @_response_str = _make_response_format(status, challenge, new_captcha)
      status
    end

    # jf is JSON_FORMAT
    def _register(user_id = nil, new_captcha = 1, jf = 1, client_type = 'web', ip_address = '')
      pri_responce = _register_challenge(user_id, new_captcha, jf, client_type, ip_address)
      if pri_responce.empty?
        challenge = ' '
      else
        if jf == 1
          response_dic = JSON.parse(pri_responce)
          challenge = response_dic['challenge']
        else
          challenge = pri_responce
        end
      end

      if challenge.size == 32
        challenge = _md5_encode("#{challenge}#{@private_key}")
        return 1, challenge
      else
        return 0, _make_fail_challenge
      end
    end

    def get_response_str
      @_response_str
    end

    def _make_fail_challenge
      rnd1 = rand(100)
      rnd2 = rand(100)
      md5_str1 = _md5_encode(rnd1.to_s)
      md5_str2 = _md5_encode(rnd2.to_s)
      md5_str1 + md5_str2[0...2]
    end

    def _make_response_format(success = 1, challenge = nil, new_captcha = 1)
      challenge = _make_fail_challenge if challenge.nil?

      if new_captcha == 1
        string_format = JSON.generate('success': success, 'gt': @captcha_id, 'challenge': challenge, "new_captcha": true)
      else
        string_format = JSON.generate('success': success, 'gt': @captcha_id, 'challenge': challenge, "new_captcha": false)
      end
      string_format
    end

    # 正常模式的二次验证方式.向geetest server 请求验证结果.
    def success_validate(challenge, validate, seccode, user_id = nil, gt = nil, data = '', userinfo = '', jf = 1)
      return 0 unless _check_para(challenge, validate, seccode)
      return 0 unless _check_result(challenge, validate)

      validate_url = "#{self.API_URL}#{self.VALIDATE_HANDLER}"

      query = {
        "seccode": seccode,
        "sdk": "ruby_#{@sdk_version}",
        "user_id": user_id,
        "data": data,
        "timestamp": Time.now.to_i,
        "challenge": challenge,
        "userinfo": userinfo,
        "captchaid": gt,
        "json_format": jf
      }

      uri = URI(validate_url)
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(query)
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      backinfo = res.code == '200' ? res.body : ''
      if jf == 1
        backinfo = JSON.parse(backinfo)
        backinfo = backinfo['seccode']
      end

      return 1 if backinfo == _md5_encode(seccode)

      0
    end

    def _register_challenge(user_id = nil, _new_captcha = 1, jf = 1, client_type = 'web', ip_address = '')
      if user_id.nil?
        register_url = "#{self.API_URL}#{self.REGISTER_HANDLER}?gt=#{@captcha_id}&json_format=#{jf}&client_type=#{client_type}&ip_address=#{ip_address}"
      else
        register_url = "#{self.API_URL}#{self.REGISTER_HANDLER}?gt=#{@captcha_id}&user_id=#{user_id}&json_format=#{jf}&client_type=#{client_type}&ip_address=#{ip_address}"
      end

      uri = URI(register_url)
      res = Net::HTTP.get_response(uri)
      res.code == '200' ? res.body : ''
    end

    def _check_result(origin, validate)
      encode_str = _md5_encode(@private_key + 'geetest' + origin)
      validate == encode_str
    end

    def _check_para(challenge, validate, seccode)
      return false if challenge.nil? || challenge.strip.empty?
      return false if validate.nil? || validate.strip.empty?
      return false if seccode.nil? || seccode.strip.empty?

      true
    end

    def _md5_encode(values)
      Digest::MD5.hexdigest(values)
    end
  end
end
