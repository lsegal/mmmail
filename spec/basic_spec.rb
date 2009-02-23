require File.dirname(__FILE__) + '/../lib/mmmail.rb'
require 'net/smtp'

describe MmMail::Message, '#initialize' do
  it "should always have from, subject and body" do
    m = MmMail::Message.new
    m.from.should == 'nobody@localhost'
    m.body.should == ''
    m.subject.should == ''
  end
end

describe MmMail::Message, "accessor methods" do
  it "should allow access from m.value/m.value=" do
    m = MmMail::Message.new
    m.some_field = 'hello'
    m.some_field.should == 'hello'
  end
  
  it "should allow access from m[:value]" do
    m = MmMail::Message.new
    m[:some_field] = 'hello'
    m[:some_field].should == 'hello'
  end
  
  it "should allow access from m['Value']" do
    m = MmMail::Message.new
    m['Some-Field'] = 'hello'
    m['Some-Field'].should == 'hello'
  end
  
  it "should allow mixing of any form of access" do
    check = lambda do |m|
      m.some_field.should == 'hello'
      m[:some_field].should == 'hello'
      m['Some-Field'].should == 'hello'
    end
    
    m = MmMail::Message.new
    m.some_field = 'hello'
    check.call(m)
    m[:some_field] = 'hello'
    check.call(m)
    m['Some-Field'] = 'hello'
    check.call(m)
  end
  
  it "should advertise that it responds to set fields (respond_to?)" do
    m = MmMail::Message.new
    m.some_field = 'hello'
    m.respond_to?(:to_s).should == true # sanity check
    m.respond_to?(:some_field).should == true
    m.respond_to?(:FAIL).should == false
  end
end

describe MmMail::Message, '#translate_header_name' do
  def translate(val) MmMail::Message.new.send(:translate_header_name, val) end
  
  it "should translate header 'Some-Field' attribute name to :some_field" do
    translate('Some-Field').should == :some_field
    translate('Some-field').should == :some_field
    translate('To').should == :to
    translate('X-Message-Id').should == :x_message_id
  end
  
  it "should translate header :some_field to 'Some-Field'" do
    translate(:some_field).should == 'Some-Field'
  end
  
  it "should raise ArgumentError if arg is not Symbol or String" do
    lambda { translate({}) }.should raise_error(ArgumentError)
  end
end

describe MmMail::Message, "#to_s" do
  it "should show all headers before special value body" do
    m = MmMail::Message.new
    m.to = 'hello@email.com'
    m.from = 'me@email.com'
    m.x_message_id = '12345'
    m.body = "Hello World"
    m.subject = 'Subject Here'
    
    # Might not work in Ruby 1.8 (hashes are unordered)
    m.to_s.should == 
    "From: me@email.com\nSubject: Subject Here\nTo: hello@email.com\n" +
    "X-Message-Id: 12345\n\nHello World"
  end
end

describe MmMail::Message, '#valid?' do
  it "should be valid only if message has from, to and subject" do
    m = MmMail::Message.new
    m.valid?.should == false # no to or subject
    m.to = '' 
    m.valid?.should == false # to is empty, not good enough
    m.to = 'hello@test.com'
    m.subject = ''
    m.valid?.should == true # empty subject is legal
    m.subject = nil
    m.valid?.should == false
  end
end

describe MmMail::Message, '#recipient_list' do
  it "should list all emails in the To header" do
    m = MmMail::Message.new
    m.to = 'a@b.c ,     b@c.d'
    m.recipients_list.should == ['a@b.c', 'b@c.d']
  end
end

describe MmMail::Transport::Config, '#initialize' do
  it "should initialize with sane defaults" do
    config = MmMail::Transport::Config.new
    config.host.should == 'localhost'
    config.port.should == 25
    config.auth_type.should be_nil
    config.auth_user.should be_nil
    config.auth_pass.should be_nil
    config.method.should == :smtp
    config.sendmail_binary.should == 'sendmail'
  end
end

describe MmMail::Transport, '.mail' do
  it "should create a Transport object and call #mail" do
    Net::SMTP.should_receive(:start)
    m = MmMail::Message.new(:to => 'test@test.com', :subject => 'hi')
    MmMail::Transport.mail(m)
  end
end

describe MmMail::Transport, '#initialize' do
  it "should allow config object to be passed" do
    lambda { MmMail::Transport.new(:symbol) }.should raise_error(ArgumentError)
  end
  
  it "should allow valid config" do
    conf = MmMail::Transport::Config.new
    transport = MmMail::Transport.new(conf)
    transport.config.should == conf
  end
end

describe MmMail::Transport, '#mail' do
  it "should raise ArgumentError if argument is not a message" do
    lambda { MmMail::Transport.new.mail(:sym) }.should raise_error(ArgumentError)
  end
  
  it "should raise TransportError if message is invalid" do
    invalid_m = MmMail::Message.new
    lambda { MmMail::Transport.new.mail(invalid_m) }.should raise_error(MmMail::TransportError)
  end
  
  it "should pass to Net::SMTP if method is set to :smtp" do
    Net::SMTP.should_receive(:start).with('localhost', 25, 'localhost.localdomain', nil, nil, nil)
    m = MmMail::Message.new(:to => 'test@test.com', :subject => 'hi')
    MmMail::Transport.new.mail(m)
  end
  
  it "should pass changed config values to Net::SMTP" do
    conf = MmMail::Transport::Config.new
    conf.auth_type = :plain
    conf.auth_user = 'foo'
    conf.auth_pass = 'bar'
    conf.host = 'foo.bar'
    conf.port = 587
    Net::SMTP.should_receive(:start).with(conf.host, conf.port, 
      'localhost.localdomain', conf.auth_user, conf.auth_pass, conf.auth_type)
    m = MmMail::Message.new(:to => 'test@test.com', :subject => 'hi')
    MmMail::Transport.new(conf).mail(m)
  end

  it "should pass to sendmail if method is set to :sendmail" do
    conf = MmMail::Transport::Config.new
    conf.method = :sendmail
    conf.sendmail_binary = '/path/to/sendmail'
    IO.should_receive(:popen).with('/path/to/sendmail -t 2>&1', 'w+')
    m = MmMail::Message.new(:to => 'test@test.com', :subject => 'hi')
    lambda { MmMail::Transport.new(conf).mail(m) }.should raise_error
  end
  
  it "should fail if the sendmail binary is invalid" do
    conf = MmMail::Transport::Config.new
    conf.method = :sendmail
    conf.sendmail_binary = '/FAIL'
    m = MmMail::Message.new(:to => 'test@test.com', :subject => 'hi')
    lambda { MmMail::Transport.new(conf).mail(m) }.should raise_error(MmMail::TransportError)
  end
end
