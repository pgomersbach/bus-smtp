require 'mini-smtp-server'
require 'net/ping'
require 'logger'

class StdoutSmtpServer < MiniSmtpServer
  def new_message_event(message_hash)
    contentArray=[]  # start with an empty array
    offlineArray=[]
    livehostsArray=[]
    pushnext=false
    nronline=0
    nroffline=0

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    logger.info("New email received")
    logger.debug("Mail from: #{message_hash[:from]}")
    logger.debug("Mail to: #{message_hash[:to]}")

    s=message_hash[:data].gsub(/\r\n/, "\r\n")
    # create array from input lines
    s.each_line {|line|
      contentArray.push line
    }
    # reverse loop to array to find the line before 'Offline'
    contentArray.reverse.each { |x|
      if pushnext == true then # this is the line we need
        pushnext=false
        # remove to >
        x=x.split('>')[1]
        # remove after <
        x=x.split('<')[0]
        offlineArray.push x
      end
      if x.include? "Offline" then # we need the next line in the loop
        pushnext=true
      end
    }
    logger.info "Checking #{offlineArray.length} hosts"
    offlineArray.each { |x|
      # other options are 'Net::Ping::(ICMP/TCP/UDP/WMI/EXTERNAL)
      u = Net::Ping::External.new(x)
      u.timeout = 2
      if u.ping then
        logger.debug "Host: #{x} is online"
        nronline += 1
        livehostsArray.push x
      else
        logger.debug "Host: #{x} is offline"
        nroffline += 1
      end
    }
    if nronline > 0 then
      logger.info "NOK, online hosts"
      logger.debug livehostsArray
      print "NOK, online hosts: ", livehostsArray, "\n"
    else
      logger.info "OK, all hosts offline"
      print "OK "
    end
    print nronline, " hosts online, ", nroffline, " hosts offline\n"
  end

end

# start of main
# create and start new smtp server
smtpserver = StdoutSmtpServer.new(2525, "0.0.0.0", 4)
smtpserver.start
smtpserver.join
# shutdown the smtpserver without interrupting any connections:
smtpserver.shutdown
while(smtpserver.connections > 0)
  sleep 0.01
end
smtpserver.stop
