# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::ManifestGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:brand_path) { File.join(temp_dir, 'v-test') }
  let(:ssd_backup) { File.join(temp_dir, 'ssd-backup') }

  let(:brands_data) do
    {
      'brands' => {
        'test' => {
          'name' => 'Test Brand',
          'shortcut' => 'test',
          'type' => 'owned',
          'youtube_channels' => [],
          'team' => ['david'],
          'locations' => {
            'video_projects' => brand_path,
            'ssd_backup' => ssd_backup
          },
          'aws' => {
            'profile' => 'test-profile',
            'region' => 'us-east-1',
            's3_bucket' => 'test-bucket',
            's3_prefix' => 'staging/v-test/'
          },
          'settings' => {
            's3_cleanup_days' => 90
          }
        }
      },
      'users' => {
        'david' => {
          'name' => 'David Test',
          'email' => 'david@test.com',
          'role' => 'owner',
          'default_aws_profile' => 'test-profile'
        }
      }
    }
  end

  # Create real BrandInfo object from test data
  let(:brand_info) do
    Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo.new(
      'test',
      brands_data['brands']['test']
    )
  end

  # Helper to create ManifestGenerator with dependency injection
  def create_generator(brand: 'test')
    described_class.new(
      brand,
      brand_info: brand_info,
      brand_path: brand_path
    )
  end

  before do
    FileUtils.mkdir_p(brand_path)
    FileUtils.mkdir_p(ssd_backup)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'initializes with brand name and dependency injection' do
      generator = create_generator

      expect(generator.brand).to eq('test')
      expect(generator.brand_info).to eq(brand_info)
      expect(generator.brand_path).to eq(brand_path)
    end

    it 'uses provided brand_path when brand_info is injected' do
      # Test that dependency injection works correctly
      # We always inject brand_info in tests, so we test that it accepts it
      generator = described_class.new('test', brand_info: brand_info, brand_path: brand_path)

      expect(generator.brand).to eq('test')
      expect(generator.brand_path).to eq(brand_path)
      expect(generator.brand_info).to be_a(Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo)
    end
  end

  describe '#generate' do
    let(:output_file) { File.join(brand_path, 'projects.json') }

    context 'with no projects' do
      it 'creates manifest with empty projects array' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ Generated/).to_stdout
        expect(File.exist?(output_file)).to be true

        manifest = JSON.parse(File.read(output_file))
        expect(manifest['projects']).to eq([])
        expect(manifest['config']['brand']).to eq('test')
      end
    end

    context 'with local projects only' do
      before do
        FileUtils.mkdir_p(File.join(brand_path, 'b40-intro-video'))
        FileUtils.mkdir_p(File.join(brand_path, 'b41-tutorial'))
        File.write(File.join(brand_path, 'b40-intro-video', 'video.mp4'), 'video content')
        File.write(File.join(brand_path, 'b41-tutorial', 'subtitle.srt'), 'subtitle content')
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'generates manifest with local projects' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ Generated/).to_stdout

        expect(File.exist?(output_file)).to be true
        manifest = JSON.parse(File.read(output_file))

        expect(manifest['config']['brand']).to eq('test')
        expect(manifest['config']['local_base']).to eq(brand_path)
        expect(manifest['config']['ssd_base']).to eq(ssd_backup)
        expect(manifest['projects'].size).to eq(2)

        # Check first project
        project_b40 = manifest['projects'].find { |p| p['id'] == 'b40-intro-video' }
        expect(project_b40['storage']['local']['exists']).to be true
        expect(project_b40['storage']['local']['has_heavy_files']).to be true
        expect(project_b40['storage']['ssd']['exists']).to be false

        # Check second project
        project_b41 = manifest['projects'].find { |p| p['id'] == 'b41-tutorial' }
        expect(project_b41['storage']['local']['exists']).to be true
        expect(project_b41['storage']['local']['has_light_files']).to be true
        expect(project_b41['storage']['ssd']['exists']).to be false
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'shows correct distribution summary' do
        generator = create_generator

        expect { generator.generate }.to output(/Local only: 2/).to_stdout
        expect { generator.generate }.to output(/SSD only: 0/).to_stdout
        expect { generator.generate }.to output(/Both locations: 0/).to_stdout
      end

      it 'calculates disk usage correctly' do
        generator = create_generator

        generator.generate

        manifest = JSON.parse(File.read(output_file))
        local_usage = manifest['config']['disk_usage']['local']

        expect(local_usage['total_bytes']).to be > 0
        expect(local_usage['total_mb']).to be_a(Float)
        expect(local_usage['total_gb']).to be_a(Float)
      end
    end

    context 'with SSD projects only' do
      before do
        FileUtils.mkdir_p(File.join(ssd_backup, 'b30-archived'))
        FileUtils.mkdir_p(File.join(ssd_backup, 'b31-old-project'))
        File.write(File.join(ssd_backup, 'b30-archived', 'video.mp4'), 'archived video')
      end

      it 'generates manifest with SSD projects' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ Generated/).to_stdout

        manifest = JSON.parse(File.read(output_file))
        expect(manifest['projects'].size).to eq(2)

        project = manifest['projects'].find { |p| p['id'] == 'b30-archived' }
        expect(project['storage']['ssd']['exists']).to be true
        expect(project['storage']['local']['exists']).to be false
      end

      it 'shows correct distribution summary' do
        generator = create_generator

        expect { generator.generate }.to output(/Local only: 0/).to_stdout
        expect { generator.generate }.to output(/SSD only: 2/).to_stdout
        expect { generator.generate }.to output(/Both locations: 0/).to_stdout
      end
    end

    context 'with projects in both locations' do
      before do
        # Local and SSD
        FileUtils.mkdir_p(File.join(brand_path, 'b40-both'))
        FileUtils.mkdir_p(File.join(ssd_backup, 'b40-both'))
        File.write(File.join(brand_path, 'b40-both', 'video.mp4'), 'video')
        File.write(File.join(ssd_backup, 'b40-both', 'video.mp4'), 'video backup')

        # Local only
        FileUtils.mkdir_p(File.join(brand_path, 'b41-local'))
        File.write(File.join(brand_path, 'b41-local', 'subtitle.srt'), 'subtitle')

        # SSD only
        FileUtils.mkdir_p(File.join(ssd_backup, 'b42-ssd'))
        File.write(File.join(ssd_backup, 'b42-ssd', 'old.mp4'), 'old video')
      end

      it 'generates manifest with all project locations' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ Generated/).to_stdout

        manifest = JSON.parse(File.read(output_file))
        expect(manifest['projects'].size).to eq(3)

        # Both locations
        both_project = manifest['projects'].find { |p| p['id'] == 'b40-both' }
        expect(both_project['storage']['local']['exists']).to be true
        expect(both_project['storage']['ssd']['exists']).to be true

        # Local only
        local_project = manifest['projects'].find { |p| p['id'] == 'b41-local' }
        expect(local_project['storage']['local']['exists']).to be true
        expect(local_project['storage']['ssd']['exists']).to be false

        # SSD only
        ssd_project = manifest['projects'].find { |p| p['id'] == 'b42-ssd' }
        expect(ssd_project['storage']['local']['exists']).to be false
        expect(ssd_project['storage']['ssd']['exists']).to be true
      end

      it 'shows correct distribution summary' do
        generator = create_generator

        expect { generator.generate }.to output(/Local only: 1/).to_stdout
        expect { generator.generate }.to output(/SSD only: 1/).to_stdout
        expect { generator.generate }.to output(/Both locations: 1/).to_stdout
      end

      it 'calculates disk usage for both locations' do
        generator = create_generator

        generator.generate

        manifest = JSON.parse(File.read(output_file))

        local_usage = manifest['config']['disk_usage']['local']
        ssd_usage = manifest['config']['disk_usage']['ssd']

        expect(local_usage['total_bytes']).to be > 0
        expect(ssd_usage['total_bytes']).to be > 0
      end
    end

    context 'with SSD not configured' do
      let(:brand_info_no_ssd) do
        data = brands_data['brands']['test'].dup
        data['locations']['ssd_backup'] = ''

        Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo.new('test', data)
      end

      before do
        FileUtils.mkdir_p(File.join(brand_path, 'b40-local'))
      end

      it 'warns about missing SSD configuration' do
        generator = described_class.new('test', brand_info: brand_info_no_ssd, brand_path: brand_path)

        expect { generator.generate }.to output(/⚠️  SSD backup location not configured/).to_stdout
        expect { generator.generate }.to output(/Manifest will only include local projects/).to_stdout
      end

      it 'generates manifest with local projects only' do
        generator = described_class.new('test', brand_info: brand_info_no_ssd, brand_path: brand_path)

        generator.generate

        manifest = JSON.parse(File.read(File.join(brand_path, 'projects.json')))
        expect(manifest['projects'].size).to eq(1)
        expect(manifest['projects'][0]['storage']['ssd']['exists']).to be_falsey
        expect(manifest['config']['ssd_base']).to eq('')
      end
    end

    context 'with SSD not mounted' do
      before do
        FileUtils.rm_rf(ssd_backup) # Remove SSD directory
        FileUtils.mkdir_p(File.join(brand_path, 'b40-local'))
      end

      it 'generates manifest without SSD projects' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ Generated/).to_stdout

        manifest = JSON.parse(File.read(output_file))
        expect(manifest['projects'].size).to eq(1)
        expect(manifest['projects'][0]['storage']['ssd']['exists']).to be_falsey
      end
    end

    context 'when skipping special directories' do
      before do
        # Valid projects
        FileUtils.mkdir_p(File.join(brand_path, 'b40-valid'))

        # Special directories (should be skipped)
        FileUtils.mkdir_p(File.join(brand_path, 's3-staging'))
        FileUtils.mkdir_p(File.join(brand_path, 'archived'))
        FileUtils.mkdir_p(File.join(brand_path, 'final'))
        FileUtils.mkdir_p(File.join(brand_path, '.hidden'))
        FileUtils.mkdir_p(File.join(brand_path, '_private'))
      end

      it 'skips special directories' do
        generator = create_generator

        generator.generate

        manifest = JSON.parse(File.read(output_file))
        expect(manifest['projects'].size).to eq(1)
        expect(manifest['projects'][0]['id']).to eq('b40-valid')
      end
    end
  end

  describe 'file detection' do
    context 'with heavy files' do
      before do
        project_dir = File.join(brand_path, 'b40-heavy')
        FileUtils.mkdir_p(project_dir)
        File.write(File.join(project_dir, 'video.mp4'), 'video')
        File.write(File.join(project_dir, 'clip.mov'), 'clip')
      end

      it 'detects heavy video files' do
        generator = create_generator
        generator.generate

        manifest = JSON.parse(File.read(File.join(brand_path, 'projects.json')))
        project = manifest['projects'][0]

        expect(project['storage']['local']['has_heavy_files']).to be true
      end
    end

    context 'with light files' do
      before do
        project_dir = File.join(brand_path, 'b40-light')
        FileUtils.mkdir_p(project_dir)
        File.write(File.join(project_dir, 'subtitle.srt'), 'subtitle')
        File.write(File.join(project_dir, 'notes.md'), 'notes')
        File.write(File.join(project_dir, 'thumbnail.jpg'), 'image')
      end

      it 'detects light files' do
        generator = create_generator
        generator.generate

        manifest = JSON.parse(File.read(File.join(brand_path, 'projects.json')))
        project = manifest['projects'][0]

        expect(project['storage']['local']['has_light_files']).to be true
      end
    end

    context 'with mixed files' do
      before do
        project_dir = File.join(brand_path, 'b40-mixed')
        FileUtils.mkdir_p(project_dir)
        File.write(File.join(project_dir, 'video.mp4'), 'video')
        File.write(File.join(project_dir, 'subtitle.srt'), 'subtitle')
      end

      it 'detects both heavy and light files' do
        generator = create_generator
        generator.generate

        manifest = JSON.parse(File.read(File.join(brand_path, 'projects.json')))
        project = manifest['projects'][0]

        expect(project['storage']['local']['has_heavy_files']).to be true
        expect(project['storage']['local']['has_light_files']).to be true
      end
    end
  end

  describe 'project ID validation' do
    context 'with valid FliVideo pattern' do
      before do
        FileUtils.mkdir_p(File.join(brand_path, 'b40-intro'))
        FileUtils.mkdir_p(File.join(brand_path, 'b41-tutorial'))
      end

      it 'passes validation for FliVideo pattern' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ All validations passed!/).to_stdout
      end
    end

    context 'with valid legacy pattern' do
      before do
        FileUtils.mkdir_p(File.join(brand_path, '001-old-project'))
        FileUtils.mkdir_p(File.join(brand_path, '042-legacy-video'))
      end

      it 'passes validation for legacy numeric pattern' do
        generator = create_generator

        expect { generator.generate }.to output(/✅ All validations passed!/).to_stdout
      end
    end

    context 'with invalid project ID' do
      before do
        # Create one valid and one invalid project
        FileUtils.mkdir_p(File.join(brand_path, 'b40-valid'))
        FileUtils.mkdir_p(File.join(brand_path, 'invalid-project-name'))
      end

      it 'includes all valid folders with appropriate types' do
        generator = create_generator

        generator.generate

        manifest = JSON.parse(File.read(File.join(brand_path, 'projects.json')))
        # Both projects should be included (permissive validation)
        expect(manifest['projects'].size).to eq(2)

        # b40-valid should be type: flivideo
        b40_project = manifest['projects'].find { |p| p['id'] == 'b40-valid' }
        expect(b40_project).not_to be_nil
        expect(b40_project['type']).to eq('flivideo')

        # invalid-project-name should be type: general
        general_project = manifest['projects'].find { |p| p['id'] == 'invalid-project-name' }
        expect(general_project).not_to be_nil
        expect(general_project['type']).to eq('general')
      end
    end
  end

  describe 'custom output file' do
    it 'writes to custom output file' do
      FileUtils.mkdir_p(File.join(brand_path, 'b40-test'))
      custom_file = File.join(temp_dir, 'custom-manifest.json')
      generator = create_generator

      generator.generate(output_file: custom_file)

      expect(File.exist?(custom_file)).to be true
      manifest = JSON.parse(File.read(custom_file))
      expect(manifest['projects'].size).to eq(1)
    end
  end

  describe 'JSON output format' do
    before do
      FileUtils.mkdir_p(File.join(brand_path, 'b40-test'))
      File.write(File.join(brand_path, 'b40-test', 'video.mp4'), 'x' * 1024 * 1024) # 1MB
    end

    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    it 'generates valid JSON with correct structure' do
      generator = create_generator
      generator.generate

      output_file = File.join(brand_path, 'projects.json')
      manifest = JSON.parse(File.read(output_file))

      # Config section
      expect(manifest).to have_key('config')
      expect(manifest['config']).to have_key('brand')
      expect(manifest['config']).to have_key('local_base')
      expect(manifest['config']).to have_key('ssd_base')
      expect(manifest['config']).to have_key('last_updated')
      expect(manifest['config']).to have_key('note')
      expect(manifest['config']).to have_key('disk_usage')

      # Disk usage
      expect(manifest['config']['disk_usage']).to have_key('local')
      expect(manifest['config']['disk_usage']).to have_key('ssd')
      expect(manifest['config']['disk_usage']['local']).to have_key('total_bytes')
      expect(manifest['config']['disk_usage']['local']).to have_key('total_mb')
      expect(manifest['config']['disk_usage']['local']).to have_key('total_gb')

      # Projects section
      expect(manifest).to have_key('projects')
      expect(manifest['projects']).to be_an(Array)

      # Project structure
      project = manifest['projects'][0]
      expect(project).to have_key('id')
      expect(project).to have_key('storage')
      expect(project['storage']).to have_key('ssd')
      expect(project['storage']).to have_key('local')
      expect(project['storage']['ssd']).to have_key('exists')
      expect(project['storage']['ssd']).to have_key('path')
      expect(project['storage']['local']).to have_key('exists')
      expect(project['storage']['local']).to have_key('has_heavy_files')
      expect(project['storage']['local']).to have_key('has_light_files')
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

    it 'formats timestamps correctly' do
      generator = create_generator
      generator.generate

      output_file = File.join(brand_path, 'projects.json')
      manifest = JSON.parse(File.read(output_file))

      # ISO 8601 format check
      timestamp = manifest['config']['last_updated']
      expect(timestamp).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
    end
  end
end
