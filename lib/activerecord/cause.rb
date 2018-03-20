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

        locations = get_locations
        return if locations.empty?

        if ActiveRecord::Cause.log_mode != :all
          locations = locations.take(1)
        end

        locations.each do |loc|
          @is_odd = nil

          unless (payload[:binds] || []).empty?
            binds = get_binds(payload)
          end

          name = name_with_color(payload[:name])
          sql = sql_with_color(payload[:sql])
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

      private

      def is_odd?
        return @is_odd unless @is_odd.nil?
        @is_odd = odd?
      end

      def get_locations
        return [] if ActiveRecord::Cause.match_paths.empty?
        caller_locations.select do |l|
          ActiveRecord::Cause.match_paths.any? do |re|
            re.match(l.absolute_path)
          end
        end
      end

      def get_binds(payload)
        raise NotImplementedError
      end

      def name_with_color(payload_name)
        raise NotImplementedError
      end

      def sql_with_color(payload_sql)
        raise NotImplementedError
      end
    end

    class LogSubscriberAR4 < ActiveRecord::Cause::LogSubscriber
      def sql(event)
        super
      end

      private

      def get_binds(payload)
        "  " + payload[:binds].map { |col,v|
          render_bind(col, v)
        }.inspect
      end

      def name_with_color(payload_name)
        name = "#{payload_name} (ActiveRecord::Cause)"
        if is_odd?
          color(name, CYAN, true)
        else
          color(name, MAGENTA, true)
        end
      end

      def sql_with_color(payload_sql)
        is_odd? ? color(payload_sql, nil, true) : payload_sql
      end
    end

    class LogSubscriberAR502 < ActiveRecord::Cause::LogSubscriber
      def sql(event)
        super
      end

      private

      def get_binds(payload)
        "  " + payload[:binds].map { |attr| render_bind(attr) }.inspect
      end

      def name_with_color(payload_name)
        name = "#{payload_name} (ActiveRecord::Cause)"
        colorize_payload_name(name, payload_name)
      end

      def sql_with_color(sql)
        color(sql, sql_color(sql), true)
      end
    end

    class LogSubscriberAR503 < LogSubscriberAR502
      def sql(event)
        super
      end

      private

      def get_binds(payload)
        casted_params = type_casted_binds(payload[:binds], payload[:type_casted_binds])
        "  " + payload[:binds].zip(casted_params).map { |attr, value| render_bind(attr, value) }.inspect
      end
    end

    class LogSubscriberAR515 < LogSubscriberAR502
      def sql(event)
        super
      end

      private

      def get_binds(payload)
        casted_params = type_casted_binds(payload[:type_casted_binds])
        "  " + payload[:binds].zip(casted_params).map { |attr, value| render_bind(attr, value) }.inspect
      end
    end
  end
end

require "activerecord/cause/railtie" if defined?(Rails)

ActiveSupport.on_load(:active_record) do
  if ActiveRecord.version >= Gem::Version.new("5.1.5")
    ActiveRecord::Cause::LogSubscriberAR515.attach_to :active_record
  elsif ActiveRecord.version >= Gem::Version.new("5.0.3")
    ActiveRecord::Cause::LogSubscriberAR503.attach_to :active_record
  elsif ActiveRecord.version >= Gem::Version.new("5.0.0")
    ActiveRecord::Cause::LogSubscriberAR502.attach_to :active_record
  else
    ActiveRecord::Cause::LogSubscriberAR4.attach_to :active_record
  end
end
