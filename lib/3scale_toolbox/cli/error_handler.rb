module ThreeScaleToolbox
  module CLI
    class ErrorHandler
      def self.error_watchdog
        new.error_watchdog { yield }
      end

      # Catches errors and prints nice diagnostic messages
      def error_watchdog
        # Run
        yield
      rescue StandardError, ScriptError => e
        handle_error e
        e
      else
        nil
      end

      private

      def handle_error(error)
        if expected_error?(error)
          warn error_serialize(error)
        else
          print_unexpected_error(error)
        end
      end

      def expected_error?(error)
        case error
        when ThreeScaleToolbox::Error
          true
        else
          false
        end
      end

      def print_unexpected_error(error)
        File.open('crash.log', 'w') do |io|
          write_verbose_error(error, io)
        end

        warn error_serialize(UnexpectedError.new(error))
      end

      def write_error_message(error, stream)
        write_section_header(stream, 'Message')
        stream.puts "\e[1m\e[31m#{error.class}: #{error.message}\e[0m"
      end

      def write_stack_trace(error, stream)
        write_section_header(stream, 'Backtrace')
        stream.puts error.backtrace
      end

      def write_version_information(stream)
        write_section_header(stream, 'Version Information')
        stream.puts ThreeScaleToolbox::VERSION
      end

      def write_system_information(stream)
        write_section_header(stream, 'System Information')
        stream.puts Etc.uname.to_json
      end

      def write_installed_gems(stream)
        write_section_header(stream, 'Installed gems')
        gems_and_versions.each do |g|
          stream.puts "  #{g.first} #{g.last.join(', ')}"
        end
      end

      def write_load_paths(stream)
        write_section_header(stream, 'Load paths')
        $LOAD_PATH.each_with_index do |i, index|
          stream.puts "  #{index}. #{i}"
        end
      end

      def write_verbose_error(error, stream)
        stream.puts "Crashlog created at #{Time.now}"

        write_error_message(error, stream)
        write_stack_trace(error, stream)
        write_version_information(stream)
        write_system_information(stream)
        write_installed_gems(stream)
        write_load_paths(stream)
      end

      def gems_and_versions
        gems = {}
        Gem::Specification.find_all.sort_by { |s| [s.name, s.version] }.each do |spec|
          gems[spec.name] ||= []
          gems[spec.name] << spec.version.to_s
        end
        gems
      end

      def write_section_header(stream, title)
        stream.puts

        stream.puts "===== #{title.upcase}:"
        stream.puts
      end

      def error_serialize(error)
        JSON.pretty_generate format_error(error)
      end

      def format_error(error)
        {
          code: error.code,
          message: error.message,
          class: error.kind,
          stacktrace: error.stacktrace
        }.compact
      end
    end
  end
end
