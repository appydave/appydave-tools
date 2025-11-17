# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::ShareOperations do
  let(:temp_dir) { Dir.mktmpdir }
  let(:brand_path) { File.join(temp_dir, 'v-test') }
  let(:project_dir) { File.join(brand_path, 'test-project') }

  let(:mock_s3_client) { instance_double(Aws::S3::Client) }
  let(:mock_presigner) { instance_double(Aws::S3::Presigner) }

  let(:settings_data) do
    {
      'video-projects-root' => temp_dir
    }
  end

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
            'ssd_backup' => '/tmp/ssd'
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

  # Helper to create ShareOperations with dependency injection
  def create_share_operations(brand: 'test', project: 'test-project', client: mock_s3_client)
    described_class.new(
      brand,
      project,
      brand_info: brand_info,
      brand_path: brand_path,
      s3_client: client
    )
  end

  before do
    # Create real project directory structure
    FileUtils.mkdir_p(project_dir)

    # Mock AWS presigner
    allow(Aws::S3::Presigner).to receive(:new).and_return(mock_presigner)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'initializes with brand and project' do
      share_ops = create_share_operations

      expect(share_ops.brand).to eq('test')
      expect(share_ops.project).to eq('test-project')
      expect(share_ops.brand_info).to be_a(Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo)
    end
  end

  describe '#generate_links' do
    let(:share_ops) { create_share_operations }
    let(:test_file) { 'video.mp4' }
    let(:presigned_url) { 'https://test-bucket.s3.amazonaws.com/video.mp4?signature=xyz' }

    before do
      # Mock file existence check
      allow(mock_s3_client).to receive(:head_object).and_return(true)

      # Mock presigned URL generation
      allow(mock_presigner).to receive(:presigned_url).and_return(presigned_url)

      # Mock clipboard
      allow(Clipboard).to receive(:copy)
    end

    context 'when file exists in S3' do
      it 'generates pre-signed URL successfully' do
        result = share_ops.generate_links(files: test_file, expires: '7d')

        expect(result[:success]).to be true
        expect(result[:urls]).to be_an(Array)
        expect(result[:urls].first[:file]).to eq(test_file)
        expect(result[:urls].first[:url]).to eq(presigned_url)
        expect(result[:expiry]).to be_a(Time)
      end

      it 'copies URL to clipboard' do
        expect(Clipboard).to receive(:copy).with(presigned_url)

        share_ops.generate_links(files: test_file, expires: '7d')
      end

      it 'handles multiple files' do
        files = %w[video1.mp4 video2.mp4]

        result = share_ops.generate_links(files: files, expires: '7d')

        expect(result[:urls].size).to eq(2)
        expect(result[:urls].map { |u| u[:file] }).to eq(files)
      end
    end

    context 'when file does not exist in S3' do
      before do
        allow(mock_s3_client).to receive(:head_object).and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not Found'))
      end

      it 'returns error result' do
        result = share_ops.generate_links(files: test_file, expires: '7d')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No files found in S3')
      end
    end

    context 'with custom expiry' do
      it 'accepts hours format' do
        result = share_ops.generate_links(files: test_file, expires: '24h')

        expect(result[:success]).to be true
        expiry_seconds = result[:expiry] - Time.now
        expect(expiry_seconds).to be_within(10).of(24 * 3600)
      end

      it 'accepts days format' do
        result = share_ops.generate_links(files: test_file, expires: '3d')

        expect(result[:success]).to be true
        expiry_seconds = result[:expiry] - Time.now
        expect(expiry_seconds).to be_within(10).of(3 * 86_400)
      end
    end
  end

  describe '#parse_expiry' do
    let(:share_ops) { create_share_operations }

    context 'with hours format' do
      it 'parses 1h' do
        expect(share_ops.send(:parse_expiry, '1h')).to eq(3600)
      end

      it 'parses 24h' do
        expect(share_ops.send(:parse_expiry, '24h')).to eq(86_400)
      end

      it 'parses 168h (7 days)' do
        expect(share_ops.send(:parse_expiry, '168h')).to eq(604_800)
      end

      it 'raises error for less than 1 hour' do
        expect { share_ops.send(:parse_expiry, '0h') }.to raise_error(ArgumentError, 'Expiry must be at least 1 hour')
      end

      it 'raises error for more than 168 hours' do
        expect { share_ops.send(:parse_expiry, '169h') }.to raise_error(ArgumentError, 'Expiry cannot exceed 168 hours (7 days)')
      end
    end

    context 'with days format' do
      it 'parses 1d' do
        expect(share_ops.send(:parse_expiry, '1d')).to eq(86_400)
      end

      it 'parses 7d' do
        expect(share_ops.send(:parse_expiry, '7d')).to eq(604_800)
      end

      it 'raises error for less than 1 day' do
        expect { share_ops.send(:parse_expiry, '0d') }.to raise_error(ArgumentError, 'Expiry must be at least 1 day')
      end

      it 'raises error for more than 7 days' do
        expect { share_ops.send(:parse_expiry, '8d') }.to raise_error(ArgumentError, 'Expiry cannot exceed 7 days')
      end
    end

    context 'with invalid format' do
      it 'raises error for invalid format' do
        expect { share_ops.send(:parse_expiry, 'invalid') }.to raise_error(ArgumentError, /Invalid expiry format/)
      end

      it 'raises error for missing unit' do
        expect { share_ops.send(:parse_expiry, '7') }.to raise_error(ArgumentError, /Invalid expiry format/)
      end
    end
  end

  describe '#build_s3_key' do
    let(:share_ops) { create_share_operations }

    it 'builds correct S3 key path' do
      file = 'video.mp4'
      s3_key = share_ops.send(:build_s3_key, file)

      expect(s3_key).to eq('staging/v-test/test-project/video.mp4')
    end
  end

  describe '#file_exists_in_s3?' do
    let(:share_ops) { create_share_operations }
    let(:s3_key) { 'staging/v-test/test-project/video.mp4' }

    context 'when file exists' do
      before do
        allow(mock_s3_client).to receive(:head_object).with(
          bucket: 'test-bucket',
          key: s3_key
        ).and_return(true)
      end

      it 'returns true' do
        expect(share_ops.send(:file_exists_in_s3?, s3_key)).to be true
      end
    end

    context 'when file does not exist' do
      before do
        allow(mock_s3_client).to receive(:head_object).and_raise(
          Aws::S3::Errors::NotFound.new(nil, 'Not Found')
        )
      end

      it 'returns false' do
        expect(share_ops.send(:file_exists_in_s3?, s3_key)).to be false
      end
    end
  end
end
