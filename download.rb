#!/usr/bin/env ruby

=begin
  Download DBA scripts from oracle-base.com

=end

require 'openssl'
require 'open-uri'
require 'nokogiri'

Dir.chdir __dir__

urlbase = 'https://oracle-base.com/dba/'
indexurl = 'https://oracle-base.com/dba/scripts'

indexfile = "index.htm"

if !File.file?(indexfile) || (Time.now-File.stat(indexfile).mtime) > 30
  indexurl.yield_self{ |e| open(e) }
  .yield_self{ |e| e.read }
  .yield_self{ |e| File.write(indexfile, e) }
end

d = File.read indexfile
html = Nokogiri::HTML d
aa = html.css 'a'
puts "links: #{aa.size}"



aa.each do |link|
  /^script\?category\=(?<category>.*?)\&file\=(?<file>.*)/ =~ link.attr('href')
  if category && file
    fn = "#{category}/#{file}"
    if File.file?(fn)
      puts " Skip exists #{fn}"
      next
    end
    Dir.mkdir(category) unless File.directory?(category)
    puts "Saving #{fn}"
    begin
      d2 = open("#{urlbase}#{link.attr('href')}").read
    rescue OpenSSL::SSL::SSLError, Net::OpenTimeout => e
      puts "     err #{e.message}"
      sleep 20+Random.rand(3)*3
      retry
    end

    d2.yield_self{ |e| Nokogiri::HTML e }
    .yield_self{ |e| e.css('pre') }
    .yield_self{ |e| e.text }
    .yield_self{ |e| File.write(fn, e) }
    puts "   Done!"
    sleep Random.rand(3)*3
    # break
  else
    puts "  Skip #{link.attr('href')} -> #{link.text}"
  end
end

