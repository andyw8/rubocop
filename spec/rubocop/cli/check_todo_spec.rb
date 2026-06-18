# frozen_string_literal: true

RSpec.describe 'RuboCop::CLI --check-todo', :isolated_environment do # rubocop:disable RSpec/DescribeClass
  subject(:cli) { RuboCop::CLI.new }

  include_context 'cli spec behavior'

  before do
    RuboCop::Formatter::DisabledConfigFormatter.config_to_allow_offenses = {}
    RuboCop::Formatter::DisabledConfigFormatter.detected_styles = {}
  end

  describe '--check-todo' do
    context 'when there is no existing todo file' do
      it 'generates one and reports no redundant entries' do
        create_file('example.rb', ['# frozen_string_literal: true', '', '$!'])

        expect(cli.run(['--check-todo'])).to eq(0)
        expect($stdout.string).to include('has no redundant entries')
        expect(File).not_to exist('.rubocop_todo.yml')
      end
    end

    context 'when the todo file has no redundant entries' do
      it 'exits successfully without modifying the todo file' do
        create_file('example.rb', ['# frozen_string_literal: true', '', '$!'])
        expect(cli.run(['--auto-gen-config'])).to eq(0)
        original_todo = File.read('.rubocop_todo.yml')

        expect(cli.run(['--check-todo'])).to eq(0)

        expect($stdout.string).to include('has no redundant entries')
        expect(File.read('.rubocop_todo.yml')).to eq(original_todo)
      end
    end

    context 'when the todo file has a redundant entry' do
      it 'exits with an error, lists the cop, and leaves the todo file unmodified' do
        create_file('example.rb', ['# frozen_string_literal: true', '', '$!'])
        expect(cli.run(['--auto-gen-config'])).to eq(0)
        original_todo = File.read('.rubocop_todo.yml')

        create_file('example.rb', ['# frozen_string_literal: true'])

        expect(cli.run(['--check-todo'])).to eq(1)

        expect($stderr.string).to include('contains redundant entries')
        expect($stderr.string).to include('Style/SpecialGlobalVars')
        expect(File.read('.rubocop_todo.yml')).to eq(original_todo)
      end
    end
  end
end
