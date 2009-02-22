require 'net/smtp'

module CMail
  class SendMailError < Exception; end
  
  class Transport
    class Config
      attr_accessor :host, :port
      attr_accessor :auth_type, :auth_user, :auth_pass
      attr_accessor :method, :sendmail_binary

      def initialize
        @method = :smtp # :sendmail
        @host = 'localhost'
        @port = 25
        @auth_type = nil # :plain, :login, :cram_md5
        @auth_user = nil
        @auth_pass = nil
        @sendmail_binary = 'sendmail'
      end
    end
    
    DefaultConfig = Config.new

    def self.mail(message, config = nil)
      new(config).mail(message)
    end
    
    attr_accessor :config
    
    def initialize(config = nil)
      @config = config || DefaultConfig
    end
    
    def mail(message)
      unless Message === message
        raise ArgumentError, "expected CMail::Message, got #{message.class}"
      end
      
      send("mail_#{config.method}", message)
    end
    
    def mail_smtp(message)
      Net::SMTP.start(config.host, config.port, 'localhost.localdomain', 
          config.auth_user, config.auth_pass, config.auth_type) do |smtp|
        smtp.send_message(message.to_s, message.from, message.recipients_list)
      end
    end
    
    def mail_sendmail(message)
      bin, err = config.sendmail_binary, ''
      result = IO.popen("#{bin} -t 2>&1", "w+") do |io|
        io.write(message.to_s)
        io.close_write
        err = io.read.chomp
      end
      
      raise SendMailError, err if $? != 0
    end
  end

  class Message
    def initialize(opts = {})
      defaults = {
        :from => 'nobody@localhost',
        :body => ''
      }
      @headers = defaults.merge(opts)
    end
    
    def [](k)     @headers[translate_header_to_sym(k)]     end
    def []=(k, v) @headers[translate_header_to_sym(k)] = v end
    
    def method_missing(sym, *args)
      if sym.to_s =~ /=$/
        self[sym.to_s[0..-2].to_sym] = *args
      elsif @headers.has_key?(sym)
        self[sym]
      else
        super
      end
    end
    
    def to_s
      "#{headers}\n#{body}\n"
    end
    
    def recipients_list
      to.split(/\s*,\s*/)
    end
    
    private
    
    def headers
      @headers.reject {|k, v| k == :body }.map do |k, v|
        translate_header_name(k) + ': ' + v + "\n"
      end.join
    end

    def translate_header_name(key)
      case key
      when String
        key.downcase.tr('-', '_').to_sym
      when Symbol
        key.to_s.capitalize.gsub(/_(.)/) {|m| '-' + m[1].upcase }
      else
        raise ArgumentError, "invalid key type #{key.class}"
      end
    end
    
    def translate_header_to_sym(key)
      return key if Symbol === key
      translate_header_name(key)
    end
  end
  
  def self.mail(opts = {}, config = nil)
    Transport.mail(Message.new(opts), config)
  end
end
