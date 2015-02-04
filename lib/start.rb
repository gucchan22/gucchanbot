#-*- coding:utf-8 -*-
#require "./oda.rb"
class ODAWrapper
  def initialize(args = nil)
  end
  def disasm(args)
    `ruby ./lib/oda.rb #{args[:binary]} #{args[:arch]} | tr -d '\n' | ruby ./lib/oda.rb --in`
    #`ls -la .`
  end
end
