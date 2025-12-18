# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Generate do
  include_context 'with jump filesystem'

  let(:locations) do
    [
      {
        'key' => 'dev',
        'path' => '~/dev',
        'jump' => 'jd',
        'type' => 'monorepo',
        'tags' => %w[root polyglot],
        'description' => 'Development root'
      },
      {
        'key' => 'ad-tools',
        'path' => '~/dev/ad/appydave-tools',
        'jump' => 'jad-tools',
        'brand' => 'appydave',
        'type' => 'tool',
        'tags' => %w[ruby cli],
        'description' => 'AppyDave CLI tools'
      },
      {
        'key' => 'ss-app',
        'path' => '~/dev/clients/supportsignal/app',
        'jump' => 'jss-app',
        'client' => 'supportsignal',
        'type' => 'product',
        'tags' => %w[typescript nextjs],
        'description' => 'SupportSignal app'
      },
      {
        'key' => 'flivideo',
        'path' => '~/dev/ad/flivideo',
        'jump' => 'jfli',
        'brand' => 'appydave',
        'type' => 'product',
        'tags' => %w[video asset-management],
        'description' => 'FliVideo'
      },
      {
        'key' => 'gem-k-builder',
        'path' => '~/dev/kgems/k_builder',
        'jump' => 'jgb',
        'type' => 'gem',
        'tags' => %w[ruby code-generation],
        'description' => 'k_builder gem'
      },
      {
        'key' => 'video-appydave',
        'path' => '~/dev/video-projects/v-appydave',
        'jump' => 'jv-ad',
        'brand' => 'appydave',
        'type' => 'video',
        'tags' => %w[youtube flivideo-workflow],
        'description' => 'AppyDave video projects'
      },
      {
        'key' => 'joy',
        'path' => '~/dev/ad/beauty-and-joy',
        'jump' => 'jjoy',
        'brand' => 'beauty-and-joy',
        'type' => 'brand',
        'tags' => ['lifestyle'],
        'description' => "Joy's brand"
      },
      {
        'key' => 'historical',
        'path' => '~/dev/historical',
        'jump' => 'jhist',
        'type' => 'archive',
        'tags' => ['deprecated'],
        'description' => 'Historical archives'
      }
    ]
  end

  let(:config) do
    data = minimal_config(locations: locations)
    create_test_config(data)
  end

  let(:path_validator) { TestPathValidator.new(valid_paths: locations.map { |l| l['path'] }) }

  describe '#run' do
    context 'with invalid target' do
      it 'returns error for unknown target' do
        cmd = described_class.new(config, 'unknown', path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
        expect(result[:error]).to include('Unknown generate target')
      end
    end

    context 'with aliases target' do
      it 'generates alias content' do
        cmd = described_class.new(config, 'aliases', path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:content]).to include('alias jd=')
        expect(result[:content]).to include('alias jad-tools=')
      end

      it 'writes to file when output path provided' do
        output_path = File.join(temp_folder, 'aliases-jump.zsh')
        cmd = described_class.new(config, 'aliases', output_path: output_path, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:path]).to eq(output_path)
        expect(File.exist?(output_path)).to be true
        expect(File.read(output_path)).to include('alias jd=')
      end
    end

    context 'with help target' do
      it 'generates help content' do
        cmd = described_class.new(config, 'help', path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:content]).to include('jd')
        expect(result[:content]).to include('jad-tools')
      end
    end

    context 'with ah-help target' do
      subject(:cmd) { described_class.new(config, 'ah-help', path_validator: path_validator) }

      it 'generates ah-help content' do
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:content]).to be_a(String)
      end

      it 'includes section headers with ## prefix' do
        result = cmd.run

        expect(result[:content]).to include('## Base Directories')
        expect(result[:content]).to include('## Brand Projects - AppyDave')
        expect(result[:content]).to include('## Client Projects')
      end

      it 'formats aliases with padding' do
        result = cmd.run

        # Aliases should be left-padded to 24 characters
        expect(result[:content]).to match(%r{^jd {20,}~/dev})
      end

      it 'includes tags with # prefix' do
        result = cmd.run

        expect(result[:content]).to include('#tool')
        expect(result[:content]).to include('#appydave')
        expect(result[:content]).to include('#ruby')
      end

      it 'groups locations by section' do
        result = cmd.run
        lines = result[:content].split("\n")

        # Find section indices
        base_idx = lines.index('## Base Directories')
        brand_idx = lines.index('## Brand Projects - AppyDave')
        client_idx = lines.index('## Client Projects')

        expect(base_idx).to be < brand_idx
        expect(brand_idx).to be < client_idx
      end

      it 'collapses home directory to ~' do
        result = cmd.run

        expect(result[:content]).to include('~/dev')
        expect(result[:content]).not_to include(Dir.home)
      end

      it 'sorts locations within sections by jump alias' do
        result = cmd.run
        lines = result[:content].split("\n")

        # Find AppyDave brand section
        brand_start = lines.index('## Brand Projects - AppyDave')
        brand_entries = []
        ((brand_start + 1)...lines.length).each do |i|
          break if lines[i].start_with?('##') || lines[i].empty?

          brand_entries << lines[i]
        end

        aliases = brand_entries.map { |line| line.split.first }
        expect(aliases).to eq(aliases.sort)
      end

      it 'writes to file when output path provided' do
        output_path = File.join(temp_folder, 'aliases-help.zsh')
        cmd = described_class.new(config, 'ah-help', output_path: output_path, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:path]).to eq(output_path)
        expect(File.exist?(output_path)).to be true

        content = File.read(output_path)
        expect(content).to include('## Base Directories')
        expect(content).to include('#appydave')
      end

      it 'places gem locations in Ruby Gems section' do
        result = cmd.run

        expect(result[:content]).to include('## Ruby Gems')
        expect(result[:content]).to match(/## Ruby Gems\njgb/)
      end

      it 'places video locations in Video Projects section' do
        result = cmd.run

        expect(result[:content]).to include('## Video Projects')
        expect(result[:content]).to match(/## Video Projects\njv-ad/)
      end

      it 'places archive locations in Reference & Archives section' do
        result = cmd.run

        expect(result[:content]).to include('## Reference & Archives')
        expect(result[:content]).to match(/## Reference & Archives\njhist/)
      end

      it 'places other brand locations in Brand Projects - Other section' do
        result = cmd.run

        expect(result[:content]).to include('## Brand Projects - Other')
        expect(result[:content]).to match(/## Brand Projects - Other\njjoy/)
      end
    end

    context 'with all target' do
      it 'generates both aliases and help content' do
        cmd = described_class.new(config, 'all', path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:aliases]).to include('alias jd=')
        expect(result[:help]).to include('jd')
      end

      it 'writes both files when output directory provided' do
        cmd = described_class.new(config, 'all', output_dir: temp_folder, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:files]).to include(File.join(temp_folder, 'aliases-jump.zsh'))
        expect(result[:files]).to include(File.join(temp_folder, 'data', 'jump-help.txt'))
      end
    end
  end
end
