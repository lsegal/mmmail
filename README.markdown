MmMail
======

Mmmm, a Minimalist mail library for Ruby. Works with SMTP or sendmail.
One method call to send out emails. You're done. Easy tastes good. Oh,
and it works with Ruby 1.9.

Join the discussion: #mmmail on freenode

Install
-------

    $ git clone git://github.com/lsegal/mmmail
    $ cd mmmail
    $ rake install

or use GitHub gems:

    $ sudo gem install lsegal-mmmail --source http://gems.github.com
    
Use
---

**An easy example**:

    require 'mmmail'
    MmMail.send(to: 'me@gmail.com', from: 'me@yahoo.com', 
                subject: 'hello joe', body: <<-eof)
      Hey Joe,
      
      You left the kitchen light on.
      It started a fire and burned down your house.
      Have fun in Hawaii.
      
      Jake.
    eof
    
Yes, that's Ruby 1.9 syntax, get used to it. It should work out
with the inferior 1.8 hash syntax too.

**More complex stuff, like using sendmail instead of Net::SMTP:**

    require 'mmmail'
    MmMail::Transport::DefaultConfig.method = :sendmail
    MmMail.send(...)
    
Okay it wasn't that hard. You can also specify the path to sendmail with

    MmMail::Transport::DefaultConfig.sendmail_binary = '/bin/sendmail'

**Dealing with SMTP auth and separate hosts:**

My ISP makes me do this:

    require 'mmmail'
    config = MmMail::Transport::DefaultConfig
    config.host = 'smtp.myisp.com'
    config.port = 587
    config.auth_type = :plain # or :md5cram or :login
    config.auth_user = 'myuser'
    config.auth_pass = 'mypass'

Yours might too. Okay, it doesn't make me do *all* of that, but these are
just examples, right?

You can also create a `MmMail::Transport::Config` object to pass to `#mail`
if you need multiple configurations:

    config = MmMail::Transport::Config.new
    config.host = 'mail.someOtherIspHost.com'
    
    MmMail.send({...}, config)
    # or 
    msg = MmMail::Message.new(to: ..., from: ..., subject: ..., body: ...)
    transport = MmMail::Transport.new(config)
    transport.send(msg, config)
    
Documentation
-------------

[http://lsegal.github.com/mmmail/docs]()
