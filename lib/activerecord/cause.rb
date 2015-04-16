require "active_record"
require "active_record/log_subscriber"

require "activerecord/cause/version"

module ActiveRecord
  module Cause
    include ActiveSupport::Configurable

    config_accessor :match_paths, instance_accessor: false do
      []
    end

    config_accessor :log_with_sql, instance_accessor: false do
      false
    end

    class LogSubscriber < ActiveRecord::LogSubscriber
      IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"]

      def sql(event)
        return if ActiveRecord::Cause.match_paths.empty?
        return unless logger.debug?

        payload = event.payload

        return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        loc = caller_locations.find do |l|
          ActiveRecord::Cause.match_paths.any? do |re|
            re.match(l.absolute_path)
          end
        end

        return unless loc

        name  = "#{payload[:name]} (ActiveRecord::Cause)"
        sql   = payload[:sql]
        binds = nil

        if respond_to?(:render_bind)
          unless (payload[:binds] || []).empty?
            binds = "  " + payload[:binds].map { |col,v|
              render_bind(col, v)
            }.inspect
          end
        end

        if odd?
          name = color(name, CYAN, true)
          sql  = color(sql, nil, true)
        else
          name = color(name, MAGENTA, true)
        end
        cause = color(loc.to_s, nil, true)

        output =
          if ActiveRecord::Cause.log_with_sql
            "  #{name}  #{sql}#{binds} caused by #{cause}"
          else
            "  #{name}  caused by #{cause}"
          end

        debug(output)
      end
    end
  end
end

require "activerecord/cause/railtie" if defined?(Rails)

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Cause::LogSubscriber.attach_to :active_record
end
