require "curb"

module Curb_DSL

  def self.included(base)
    base.extend Singleton
    base.instance_eval do
      attr_reader :curl, :headers,:payload, :username, :password, :auth_type, :uri, :ssl, :redirects, :type_converter

      [:get, :post, :put, :delete, :head, :options, :patch, :link, :unlink].each do |func_name|
        define_method func_name do |&block|
          make_request_of func_name.to_s.upcase, &block
        end
      end

      [:password,:username,:payload, :auth_type, :uri, :ssl, :redirects,:type_converter].each do |func_name|
        define_method "set_#{func_name}" do |value|
          self.instance_variable_set :"@#{func_name}", value
        end
      end
    end



  end

  module Singleton
    def request(&block)
      puts block
      self.new(&block).body
    end

    def query_params(value)
      Curl::postalize(value)
    end
  end



  def initialize(&block)
    @headers = {}
    instance_eval(&block) if block
  end

  def header(name, content)
    @headers[name] = content
  end

  def make_request_of(request_method,&block)
    @curl = Curl::Easy.new(@uri) do |http|
      setup_request request_method, http
    end
    @curl.ssl_verify_peer = @ssl ||false
    @curl.ignore_content_length = true
    @curl.http request_method
    if @curl.response_code == 301
      @uri =  @curl.redirect_url
      make_request_of request_method
    end
  end

  def status_code
    @curl.response_code
  end

  def body
    @curl.body
  end

  def query_params(value)
    Curl::postalize(value)
  end


  private

  def setup_request(method,http)
    http.headers['request-method'] = method.to_s
    http.headers.update(headers || {})
    http.max_redirects = @redirects || 3
    http.post_body = get_payload || nil
    http.http_auth_types = @auth_type || nil
    http.username = @username || nil
    http.password = @password || nil
    http.useragent = "curb"
    http
  end


  def get_payload
    if @type_converter
      @type_converter.call(@payload)
    else
      @payload
    end
  end

end
