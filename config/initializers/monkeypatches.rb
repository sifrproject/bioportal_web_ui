# Mixin for UTF-8 supported substring
class String
  def utf8_slice(index, size = 1)
    self[/.{#{index}}(.{#{size}})/, 1]
  end

  def utf8_slice!(index, size = 1)
    str = self[/.{#{index}}(.{#{size}})/, 1]
    self[/.{#{index}}(.{#{size}})/, 1] = ""
    str
  end
end

# Add the current hostname to the config for using wildcard subomains for custom ontology lists
if !$ENABLE_SLICES.nil? && $ENABLE_SLICES == true
  module ActionControllerExtensions
    def self.included(base)
      base::Dispatcher.send :include, DispatcherExtensions
    end

    module DispatcherExtensions
      def self.included(base)
        base.send :before_dispatch, :set_session_domain
      end

      def set_session_domain
        if @env['HTTP_HOST']
          # remove the port if there is one
          domain = @env['HTTP_HOST'].gsub(/:\d+$/, '')

          # turn "brendan.app.com" to ".app.com"
          # and turn "app.com" to ".app.com"
          if domain.match(/([^.]+\.[^.]+)$/)
            domain = '.' + $1
          end

          @env['rack.session.options'] = @env['rack.session.options'].merge(:domain => domain)
        end
      end
    end
  end

  ActionController.send :include, ActionControllerExtensions
end
