#-*- coding:utf-8 -*-
require "sinatra"
require "./lib/start.rb"
require "./lib/6502.rb"
require "./lib/arch.rb"
require "slackbotsy"
require "open-uri"
require "shellwords"
require "cgi"
require "uri"

slack_config  = {
  "channel" => "",
  "name" => "",
  "incoming_webhook" => "",
  "outgoing_token" => ""
}
config = {
	:host => "http://example.com",
	:key => ""
}
bot = Slackbotsy::Bot.new(slack_config) do
  hear /disas\s+(\w+)\s+([0-9A-Za-z]+)$/ do |data,mdata|
      #res = data.match(/dasm\s+(\w+)\s+([0-9A-Za-z]+)$/)
      #disasm = oda.disasm(:arch => data[1], :binary => data[2])
     if data[1] != "6502"
       open("#{config[:host]}/api/#{data[1]}/#{data[2]}/sfc-rg").read
     else
       Disassembler.new.disassemble(data[2].scan(/.{1,2}/).join(" "))        
    end 
  end
  hear /disas\s+search\s+(\w+)/ do |data,mdata|
  	open("#{config[:host]}/api/search/#{data[1]}").read
  end
  hear /disas\s+help$/ do |data,mdata|
    res = ""
    res += "*gucchanbot(disassembler-bot) help*\n\n" 
    res += "disas (arch) (binary) - Disassemble code as 'arch', (e.g. dasm 6502 a900)\n"
    res += "disas search (search word) - Architecture search\n"
    res
  end
end
helpers do
	def h(s); CGI.escapeHTML(s) end
end
enable :sessions
not_found do
  erb :index, :locals => {:text => "error."}
end
error do
  "invalid machine code."
end
post "/slack" do
  bot.handle_item(params)
end
get "/api/search/:word" do
  results = []
	archs.each {|k,v| results << "#{k} - #{v}" if (k+v).upcase =~ /#{params[:word].upcase}/ }
	responser = ""
	"#{results.size} arch(s) found.\n#{results.join("\n")}"
end
get "/api/6502/:bin/:api_key" do
	if params[:api_key] == config[:key]
		binn = params[:bin].scan(/.{1,2}/).join(" ")
		Disassembler.new.disassemble(binn)
	end
end
get "/api/:arch/:binary/:api_key" do
	if params[:api_key] == config[:key]
		oda = ODAWrapper.new
		disas = oda.disasm(:arch => params[:arch], :binary => Shellwords.shellescape(params[:binary]))
		disas
	end
end
