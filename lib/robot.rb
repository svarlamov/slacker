require_relative 'listener'
require_relative 'message'

module Slacker
  class Robot
    attr_reader :name

    def initialize(name)
      @name, @listeners, @adapter = (name || ENV["NAME"]), [], nil
    end

    def respond(regex, &callback)
      @listeners << Listener.new(regex, callback)
    end

    def address_pattern
      /^((#{@name}[:,]?)|\/)\s*/
    end

    def hear(raw_message)
      text = raw_message[:text]

      return unless text =~ address_pattern
      message = Message.new(text.gsub(address_pattern, ""),
                            raw_message[:channel],
                            raw_message[:user])

      @listeners.each do |listener|
        match = listener.hears?(message)
        if match
          listener.hear!(message, match)
        end
      end

      @adapter.send(message) if @adapter

      return message
    end

    def attach(adapter)
      @adapter = adapter
      
      begin
        (Thread.new { adapter.run }).join
      rescue Exception => e
        puts e
      end
    end

    def plug(plugin)
      plugin.ready(self)
    end
  end
end
