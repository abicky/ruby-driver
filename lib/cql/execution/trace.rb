# encoding: utf-8

module Cql
  module Execution
    class Trace
      class Event
        attr_reader :id, :activity, :source, :source_elapsed, :thread

        def initialize(id, activity, source, source_elapsed, thread)
          @id             = id
          @activity       = activity
          @source         = source
          @source_elapsed = source_elapsed
          @thread         = thread
        end
      end

      include MonitorMixin

      attr_reader :id

      def initialize(id, session)
        @id      = id
        @session = session
      end

      def coordinator
        load unless @coordinator

        @coordinator
      end

      def duration
        load unless @duration

        @duration
      end

      def parameters
        load unless @parameters

        @parameters
      end

      def request
        load unless @request

        @request
      end

      def started_at
        load unless @started_at

        @started_at
      end

      def events
        load_events unless @events

        @events
      end

      private

      SELECT_SESSION = "SELECT * FROM system_traces.sessions WHERE session_id = ?"
      SELECT_EVENTS  = "SELECT * FROM system_traces.events WHERE session_id = ?"

      def load
        synchronize do
          return if @loaded

          data = @session.execute(SELECT_SESSION, @id).first
          raise ::RuntimeError, "unable to load trace #{@id}" if data.nil?

          @coordinator = data['coordinator']
          @duration    = data['duration']
          @parameters  = data['parameters']
          @request     = data['request']
          @started_at  = data['started_at']
          @loaded      = true
        end

        nil
      end

      def load_events
        synchronize do
          return if @loaded_events

          @events = []

          @session.execute(SELECT_EVENTS, @id).each do |row|
            @events << Event.new(row['event_id'], row['activity'], row['source'], row['source_elapsed'], row['thread'])
          end

          @events.freeze

          @loaded_events = true
        end
      end
    end
  end
end