
class DotErrorsFormatter

  RSpec::Core::Formatters.register self, :dump_failures

  def initialize(output)

    @output = output
  end

  def dump_failures(notification)

    notification.failure_notifications.each do |fn|

      lib = nil
      spe = nil

      fn.formatted_backtrace.each do |l|

        if m = l.match(/[^:()]+_spec\.rb:\d+/)
          spe ||= m
        elsif m = l.match(/\A(\.\/lib\/.+\.rb:\d+)/)
          lib ||= m
        end
      end

      @output << spe << "\n"
      @output << '  ' << lib << "\n" if lib

      #@output << "  +--> " << fn.description << "\n"
    end
  end
end

