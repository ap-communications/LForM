module Fluent
  class SnmpInput
    def out_exec manager, opts = {}

      manager.get(opts[:mib]).each_varbind do | vb |
        record = {}
        time = Engine.now.to_i
        key = case vb.name.to_s
              when "SNMPv2-SMI::enterprises.12356.101.4.1.3.0" then :cpu_usage
              when "SNMPv2-SMI::enterprises.12356.101.4.1.4.0" then :memory_usage
              when "SNMPv2-SMI::enterprises.12356.101.4.1.8.0" then :session_count
              else; nil
              end

        if vb.value.to_s.match(/^[0-9]+$/) then
          record[key] = vb.value.to_i if key
          Engine.emit opts[:tag], time, record
        end

      end
    end
  end
end