require 'net/smtp'

module MmMail
  class TransportError < Exception; end
  
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
      if config && !config.is_a?(Config)
        raise ArgumentError, "expected #{self.class}::Config"
      end
      
      @config = config || DefaultConfig
    end
    
    def mail(message)
      unless Message === message
        raise ArgumentError, "expected MmMail::Message, got #{message.class}"
      end
      
      raise TransportError, "invalid message" unless message.valid?
      
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
      
      raise TransportError, err if $? != 0
    end
  end

  class Message
    def initialize(opts = {})
      defaults = {
        :from => 'nobody@localhost',
        :subject => '',
        :body => ''
      }
      @headers = defaults.merge(opts)
    end
    
    def [](k)     @headers[translate_header_to_sym(k)]     end
    def []=(k, v) @headers[translate_header_to_sym(k)] = v end
    
    def method_missing(sym, *args)
      if sym.to_s =~ /=$/
        self[sym.to_s[0..-2].to_sym] = args.first
      elsif @headers.has_key?(sym)
        self[sym]
      else
        super
      end
    end
    
    def respond_to?(sym)
      return true if super
      @headers.has_key?(sym)
    end
    
    def to_s
      [headers, body].join("\n")
    end
    
    def recipients_list
      to.split(/\s*,\s*/)
    end
    
    # Checks if the message is valid. Validity is based on
    # having the From, To and Subject fields set. From and To
    # must not be empty.
    # 
    # @return [Boolean] whether or not the message is a valid e-mail
    def valid?
      [:from, :to].each do |field|
        return false if !self[field] || self[field].empty?
      end
      
      self[:subject] ? true : false
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
