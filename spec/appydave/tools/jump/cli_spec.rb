# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::CLI do
  include_context 'with jump filesystem'

  let(:output) { StringIO.new }
  let(:cli) { described_class.new(config: config, path_validator: path_validator, output: output) }
  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/dev/test-project', '~/dev/new-path']) }

  let(:initial_locations) do
    [
      {
        'key' => 'test-project',
        'path' => '~/dev/test-project',
        'jump' => 'jtest',
        'brand' => 'appydave',
        'type' => 'tool'
      }
    ]
  end

  let(:config) do
    data = minimal_config(locations: initial_locations)
    create_test_config(data)
  end

  describe 'auto-regenerate after CRUD operations' do
    let(:aliases_output_path) { File.join(temp_folder, 'aliases-jump.zsh') }
    let(:settings_mock) { instance_double(Appydave::Tools::Configuration::Models::SettingsConfig) }

    before do
      # Initialize the configurations hash on Config class
      Appydave::Tools::Configuration::Config.instance_variable_set(:@configurations, { settings: settings_mock })
      allow(settings_mock).to receive(:aliases_output_path).and_return(aliases_output_path)
    end

    after do
      # Clean up the configurations
      Appydave::Tools::Configuration::Config.reset
    end

    context 'when adding a location' do
      it 'auto-regenerates aliases file after successful add' do
        cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path'])

        expect(File.exist?(aliases_output_path)).to be true
        content = File.read(aliases_output_path)
        expect(content).to include('jnew-project')
      end

      it 'reports regeneration in output' do
        cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path'])

        expect(output.string).to include('Regenerated:')
        expect(output.string).to include(aliases_output_path)
      end

      it 'skips regeneration when --no-generate flag is used' do
        cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path', '--no-generate'])

        expect(File.exist?(aliases_output_path)).to be false
        expect(output.string).not_to include('Regenerated:')
      end

      it 'does not regenerate on failed add' do
        cli.run(['add', '--key', 'test-project', '--path', '~/dev/duplicate'])

        expect(File.exist?(aliases_output_path)).to be false
      end
    end

    context 'when updating a location' do
      it 'auto-regenerates aliases file after successful update' do
        cli.run(['update', 'test-project', '--description', 'Updated description'])

        expect(File.exist?(aliases_output_path)).to be true
      end

      it 'skips regeneration when --no-generate flag is used' do
        cli.run(['update', 'test-project', '--description', 'Updated', '--no-generate'])

        expect(File.exist?(aliases_output_path)).to be false
      end

      it 'does not regenerate on failed update' do
        cli.run(['update', 'nonexistent', '--description', 'Fail'])

        expect(File.exist?(aliases_output_path)).to be false
      end
    end

    context 'when removing a location' do
      it 'auto-regenerates aliases file after successful remove' do
        cli.run(['remove', 'test-project', '--force'])

        expect(File.exist?(aliases_output_path)).to be true
        content = File.read(aliases_output_path)
        expect(content).not_to include('jtest')
      end

      it 'skips regeneration when --no-generate flag is used' do
        cli.run(['remove', 'test-project', '--force', '--no-generate'])

        expect(File.exist?(aliases_output_path)).to be false
      end

      it 'does not regenerate when --force is missing' do
        cli.run(%w[remove test-project])

        expect(File.exist?(aliases_output_path)).to be false
      end
    end

    context 'when aliases-output-path is not configured' do
      before do
        allow(settings_mock).to receive(:aliases_output_path).and_return(nil)
      end

      it 'does not attempt regeneration after add' do
        cli.run(['add', '--key', 'another-project', '--path', '~/dev/new-path'])

        expect(output.string).not_to include('Regenerated:')
      end

      it 'does not attempt regeneration after update' do
        cli.run(['update', 'test-project', '--description', 'Updated'])

        expect(output.string).not_to include('Regenerated:')
      end

      it 'does not attempt regeneration after remove' do
        cli.run(['remove', 'test-project', '--force'])

        expect(output.string).not_to include('Regenerated:')
      end
    end

    context 'with existing aliases file' do
      it 'backs up before regeneration' do
        # Create an existing aliases file
        FileUtils.mkdir_p(File.dirname(aliases_output_path))
        File.write(aliases_output_path, '# Old content')

        cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path'])

        expect(output.string).to include('Backed up:')
      end
    end
  end
end
