module Poke
  require 'awesome_print'
  require 'goliath'
  require 'openssl'
  require 'base64'

  DELAY_FOR_PLUGGING_A_HOLE = 4 * 60 * 60
  FW_KEY = "super secret shared key"

  class Firewall
    def whitelist(ip)
      system("/usr/local/sbin/proxy_whitelist", ip);
    end

    def unwhitelist(ip)
      system("/usr/local/sbin/proxy_unwhitelist", ip);
    end
  end

  class APIServer < Goliath::API
    use Goliath::Rack::Params

    def initialize
      super
      @timers ||= { }
      @firewall = Firewall.new
    end

    def tokens
      [ -0x10000, 0x0, 0x10000 ].collect do |offset|
        ts = ((Time.now.to_i + offset) & ~ 0xffff).to_s
        hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'),
                                    FW_KEY, ts)
        Base64.encode64(hmac).chop
      end
    end

    def response(env)
      client_ip = env['REMOTE_ADDR']
      timer = @timers[client_ip]
      timer.cancel if timer
      @timers[client_ip] = EM::Timer.new(DELAY_FOR_PLUGGING_A_HOLE) do
        @timers.delete(client_ip)
        @firewall.unwhitelist(client_ip)
      end
      return [401, {}, 'get the hell out of here'] unless
        env['REQUEST_URI'] == '/knock'
      sent_token = env['HTTP_X_TOKEN']
      return [412, {}, 'forgot the token?'] unless sent_token
      return [401, {}, 'yeah, rite'] unless tokens.include?(sent_token)
      @firewall.whitelist(client_ip) unless timer
      [200, {}, 'knock']
    end
  end
end
