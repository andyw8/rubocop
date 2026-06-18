# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Check whether the TODO configuration file contains redundant entries.
      # @api private
      class CheckTodo < Base
        self.command_name = :check_todo

        AUTO_GENERATED_FILE = AutoGenerateConfig::AUTO_GENERATED_FILE

        def run
          dotfile = @options[:config] || ConfigFinder::DOTFILE
          previous_todo = read(AUTO_GENERATED_FILE)
          previous_dotfile = read(dotfile)

          AutoGenerateConfig.new(@env).run

          regenerated_todo = read(AUTO_GENERATED_FILE)
          restore(AUTO_GENERATED_FILE, previous_todo)
          restore(dotfile, previous_dotfile)

          report(previous_todo, regenerated_todo)
        ensure
          RuboCop::ExcludeLimit.tmp_dir = nil
        end

        private

        def read(file)
          File.read(file, encoding: Encoding::UTF_8) if File.exist?(file)
        end

        def restore(file, contents)
          if contents.nil?
            FileUtils.rm_f(file)
          else
            File.write(file, contents)
          end
        end

        def report(previous_todo, regenerated_todo)
          stale_cops = cop_names(previous_todo) - cop_names(regenerated_todo)

          if stale_cops.empty?
            puts Rainbow("`#{AUTO_GENERATED_FILE}` has no redundant entries.").green
            STATUS_SUCCESS
          else
            warn Rainbow(
              "`#{AUTO_GENERATED_FILE}` contains redundant entries for the following " \
              "cop(s), which no longer need to be listed:\n\n" \
              "#{stale_cops.map { |cop_name| "  #{cop_name}" }.join("\n")}\n\n" \
              'Run `rubocop --regenerate-todo` to remove them.'
            ).red
            STATUS_OFFENSES
          end
        end

        def cop_names(contents)
          return [] unless contents

          body = contents.lines.drop_while { |line| line.start_with?('#') }.join
          (YAML.safe_load(body) || {}).keys
        end
      end
    end
  end
end
