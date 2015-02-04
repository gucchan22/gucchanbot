#-*- coding:utf-8 -*-
require "net/http"
require "json"
require "nokogiri"
 
class ODA
  ODA_hdr = {
    "Host" => "www2.onlinedisassembler.com",
    "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
    "Referer" => "http://www2.onlinedisassembler.com/odaweb/",
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:12.0) Gecko/20100101 Firefox/12.0"
  }
  def initialize
    self.generate_cookie
  end
  def generate_cookie
    Net::HTTP.start(ODA_hdr["Host"]) do |oda|
      oda_res = oda.get("/odaweb/").get_fields("Set-Cookie").join
      oda_cookie = {}
      _,v = oda_res.split(";").first.split("=")
      ENV["ODA_SID"] = v
    end
  end
  
  def generate_payload(d)
    d.map{|k,v| "#{k}=#{v}" }.join("&")
  end
 	
  def disasm(args)
    Net::HTTP.start(ODA_hdr["Host"], 80) do |oda|
      ODA_hdr.merge!({ "Cookie" => "sessionid=#{ENV['ODA_SID']};" })
      oda.post("/odaweb/_set",
        generate_payload({
          :arch => args[:arch],
          :base_address => "0",
          :hex_val => args[:binary].join("+"),
          :endian => args[:endian]
        }),
        ODA_hdr
      )
      oda.post("/odaweb/_refresh", "", ODA_hdr) do |refresh|
        if refresh =~ /503/
          ENV.delete("ODA_SID")
          self.generate_cookie
        else
          puts refresh
        end
      end
    end
  end
 
  def analyze_disasm_html(json)
    json = JSON.parse(json)["disassembly"]
    html_parser = Nokogiri::HTML.parse(json)
    html_parser.xpath("//tr").each do |disasm|
      addr = disasm.children.children[1].text
      raw = disasm.children.children[2].text
      dis = disasm.children.children[3].text
      puts "#{addr}: #{raw}  #{dis}\n"
    end
  end
end
 
# [Rk@23:32:34] ruby oda.rb | tr -d '\n' | ruby oda.rb --in
oda = ODA.new
 
if ARGV.first == "--in" 
  oda.analyze_disasm_html(STDIN.gets)
else
  #binary =  "55 31 D2 89 E5 8B 45 08 56 8B 75 0C 53 8D 58 FF 0F"
  #binary +=  "B6 0C 16 88 4C 13 01 83 C2 01 84 C9 75 F1 5B 5E 5D C3"
  #binary = binary.split(" ")
  binary = ARGV[0].scan(/.{1,2}/)
  arch = ARGV[1]
  #puts "Binary: #{binary}"
  #puts "Architechture: #{arch}"

  oda.disasm(
    :arch => arch,
    :binary => binary,
    :endian => "DEFAULT" #DEFAULT(little-endian), BIG(big-endian), LITTLE(little-endian)
  )
end
