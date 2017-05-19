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

    # :single or :all
    config_accessor :log_mode, instance_accessor: false do
      :single
    end

    class LogSubscriber < ActiveRecord::LogSubscriber
      IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"]

      def sql(event)
        return unless logger.debug?

        payload = event.payload

        return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        if ActiveRecord.version >= Gem::Version.new("5.0.0.beta")
          sql_for_ar5(event)
        else
          sql_for_ar4(event)
        end
      end

      private

      def sql_for_ar4(event)
        payload = event.payload
        locations = caller_locations.select do |l|
          ActiveRecord::Cause.match_paths.any? do |re|
            re.match(l.absolute_path)
          end
        end

        return if locations.empty?

        if ActiveRecord::Cause.log_mode != :all
          locations = locations.take(1)
        end

        locations.each do |loc|
          name  = "#{payload[:name]} (ActiveRecord::Cause)"
          sql   = payload[:sql]
          binds = nil

          unless (payload[:binds] || []).empty?
            binds = "  " + payload[:binds].map { |col,v|
              render_bind(col, v)
            }.inspect
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

      def sql_for_ar5(event)
        payload = event.payload
        locations = get_locations
        return if locations.empty?

        if ActiveRecord::Cause.log_mode != :all
          locations = locations.take(1)
        end

        locations.each do |loc|
          name  = "#{payload[:name]} (ActiveRecord::Cause)"
          sql   = payload[:sql]
          binds = nil

          unless (payload[:binds] || []).empty?
            binds = if ActiveRecord.version >= Gem::Version.new("5.0.3")
                      "  " + payload[:binds].zip(payload[:type_casted_binds]).map { |attr, value| render_bind(attr, value) }.inspect
                    else
                      "  " + payload[:binds].map { |attr| render_bind(attr) }.inspect
                    end
          end

          name = colorize_payload_name(name, payload[:name])
          sql  = color(sql, sql_color(sql), true)
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

      def get_locations
        return [] if ActiveRecord::Cause.match_paths.empty?
        caller_locations.select do |l|
          ActiveRecord::Cause.match_paths.any? do |re|
            re.match(l.absolute_path)
          end
        end
      end
    end
  end
end

require "activerecord/cause/railtie" if defined?(Rails)

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Cause::LogSubscriber.attach_to :active_record
end
