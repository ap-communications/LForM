# coding: utf-8

module Fluent
 class TextParser
  class SyslogPaser < Parser
   Plugin.register_parser('fortigate_syslog', self)


    def initialize
      super
      tag = ""
    end

    def configure(conf)
      super
    end

    def parse(text)
      # parse syslog
      syslog_value = text.scan(/\w+=[\w+!#$%&'()-=^~|@`\[{;+:*\]},<\.>\/?\\_]+|\w+=\"[\w+\s+!#$%&'()-=^~|@`\[{;+:*\]},<\.>\/?\\_]*\"?+/)
      if syslog_value.length == 0 then raise "ERR001:syslog format error(wrong syslog format)" end
      # split by regex of ipaddress
      # syslog_value = text.split(/((([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\s)/, 2)
      # if syslog_value[1].nil? then raise "ERR001:syslog format error(no syslog value)" end
      logemit(syslog_value)
    end

    def logemit(syslog_value)
      # emit to elasticsearch
      record_value = {}
      date = ""
      datetime = ""
      syslog_value.each{|value|

        record = value.split("=")
        k = record[0]
        v = record[1]
        # date and time combining
        case k
          when "date" then
            date = v
            next
          when "time" then
            datetime = date.concat(" " + v)
            next
        end
        record_value["#{k}"] = (v == nil || v == "") ? nil : v.tr("\"","")
      }

      if datetime != "" then
        record_value["receive_time"] = time_transformation(datetime)
      end

      if record_value["type"] == "traffic" then
        tag = "syslog_traffic.forti"
      elsif record_value["type"] == "utm" then
        tag = "syslog_security.forti"
      else
        raise "ERR003:syslog format error(type definition error)"
      end

      #Log emit
      time = Engine.now
      Engine.emit(tag, time, record_value)
    end

    def time_transformation(syslog_time)
      require 'time'
      Time.parse(syslog_time).to_i
    end

  end
 end
end