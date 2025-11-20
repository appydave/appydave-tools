# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::S3Operations do
  let(:temp_dir) { Dir.mktmpdir }
  let(:brand_path) { File.join(temp_dir, 'v-test') }
  let(:project_dir) { File.join(brand_path, 'test-project') }
  let(:staging_dir) { File.join(project_dir, 's3-staging') }

  let(:mock_s3_client) { instance_double(Aws::S3::Client) }
  let(:mock_credentials) { instance_double(Aws::SharedCredentials) }

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

  # Helper to create S3Operations with dependency injection
  def create_s3_operations(brand: 'test', project: 'test-project', client: mock_s3_client)
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
    FileUtils.mkdir_p(staging_dir)
    File.write(File.join(staging_dir, 'test-file.txt'), 'test content')
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'creates an S3 client with the correct profile and region' do
      allow(Aws::SharedCredentials).to receive(:new).with(profile_name: 'test-profile').and_return(mock_credentials)
      allow(Aws::S3::Client).to receive(:new).with(
        credentials: mock_credentials,
        region: 'us-east-1',
        http_wire_trace: false,
        ssl_verify_peer: false
      ).and_return(mock_s3_client)

      # Don't inject s3_client to test the creation logic
      s3_ops = described_class.new('test', 'test-project', brand_info: brand_info, brand_path: brand_path)

      expect(s3_ops.s3_client).to eq(mock_s3_client)
    end

    it 'raises error if AWS profile is not configured' do
      # Create BrandInfo with empty profile
      bad_brand_data = brands_data['brands']['test'].dup
      bad_brand_data['aws']['profile'] = ''

      bad_brand_info = Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo.new(
        'test',
        bad_brand_data
      )

      expect do
        s3_ops = described_class.new('test', 'test-project', brand_info: bad_brand_info, brand_path: brand_path)
        s3_ops.s3_client # Trigger lazy loading to cause the error
      end.to raise_error("AWS profile not configured for current user or brand 'test'")
    end
  end

  describe '#build_s3_key' do
    it 'builds correct S3 key from relative path' do
      s3_ops = create_s3_operations
      key = s3_ops.send(:build_s3_key, 'video.mp4')

      expect(key).to eq('staging/v-test/test-project/video.mp4')
    end

    it 'handles empty relative path' do
      s3_ops = create_s3_operations
      key = s3_ops.send(:build_s3_key, '')

      expect(key).to eq('staging/v-test/test-project/')
    end
  end

  describe '#extract_relative_path' do
    it 'extracts relative path from S3 key' do
      s3_ops = create_s3_operations
      relative = s3_ops.send(:extract_relative_path, 'staging/v-test/test-project/video.mp4')

      expect(relative).to eq('video.mp4')
    end

    it 'handles nested paths' do
      s3_ops = create_s3_operations
      relative = s3_ops.send(:extract_relative_path, 'staging/v-test/test-project/folder/video.mp4')

      expect(relative).to eq('folder/video.mp4')
    end
  end

  describe '#upload' do
    let(:s3_ops) { create_s3_operations }

    it 'reports error when s3-staging directory does not exist' do
      FileUtils.rm_rf(staging_dir)

      expect { s3_ops.upload(dry_run: false) }.to output(/❌ No s3-staging directory found/).to_stdout
    end

    it 'reports when no files to upload' do
      FileUtils.rm_rf(Dir.glob("#{staging_dir}/*"))

      expect { s3_ops.upload(dry_run: false) }.to output(/❌ No files found in s3-staging/).to_stdout
    end

    it 'performs dry-run upload without making S3 calls' do
      # Mock head_object to return nil (file doesn't exist in S3)
      allow(mock_s3_client).to receive(:head_object).and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not Found'))

      expect(mock_s3_client).not_to receive(:put_object)

      expect do
        s3_ops.upload(dry_run: true)
      end.to output(/\[DRY-RUN\] Would upload/).to_stdout
    end

    it 'uploads files to S3 with correct key format' do
      allow(s3_ops).to receive(:s3_file_md5).and_return(nil)

      expect(mock_s3_client).to receive(:put_object) do |args|
        expect(args[:bucket]).to eq('test-bucket')
        expect(args[:key]).to eq('staging/v-test/test-project/test-file.txt')
      end

      expect { s3_ops.upload(dry_run: false) }.to output(/✓ Uploaded: test-file.txt/).to_stdout
    end

    it 'skips files with matching MD5' do
      local_md5 = Digest::MD5.hexdigest('test content')
      allow(s3_ops).to receive(:s3_file_md5).and_return(local_md5)

      expect(mock_s3_client).not_to receive(:put_object)

      expect { s3_ops.upload(dry_run: false) }.to output(/⏭️  Skipped: test-file.txt/).to_stdout
    end

    it 'excludes Windows Zone.Identifier files from upload' do
      # Create a Zone.Identifier file
      zone_file = File.join(staging_dir, 'video.mp4:Zone.Identifier')
      File.write(zone_file, 'test zone data')

      allow(s3_ops).to receive(:s3_file_md5).and_return(nil)

      # Should not attempt to upload Zone.Identifier file
      expect(mock_s3_client).to receive(:put_object).once do |args|
        expect(args[:key]).not_to include('Zone.Identifier')
        expect(args[:key]).to eq('staging/v-test/test-project/test-file.txt')
      end

      s3_ops.upload(dry_run: false)
    end

    it 'excludes .DS_Store files from upload' do
      # Create a .DS_Store file
      ds_store = File.join(staging_dir, '.DS_Store')
      File.write(ds_store, 'mac metadata')

      allow(s3_ops).to receive(:s3_file_md5).and_return(nil)

      # Should not attempt to upload .DS_Store file
      expect(mock_s3_client).to receive(:put_object).once do |args|
        expect(args[:key]).not_to include('.DS_Store')
        expect(args[:key]).to eq('staging/v-test/test-project/test-file.txt')
      end

      s3_ops.upload(dry_run: false)
    end
  end

  describe '#download' do
    let(:s3_ops) { create_s3_operations }

    it 'reports when no files in S3' do
      allow(s3_ops).to receive(:list_s3_files).and_return([])

      expect { s3_ops.download(dry_run: false) }.to output(/❌ No files found in S3/).to_stdout
    end

    it 'performs dry-run download without making S3 calls' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).not_to receive(:get_object)

      expect do
        s3_ops.download(dry_run: true)
      end.to output(/\[DRY-RUN\] Would download/).to_stdout
    end

    it 'downloads files from S3 to staging directory' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:get_object) do |args|
        expect(args[:bucket]).to eq('test-bucket')
        expect(args[:key]).to eq('staging/v-test/test-project/video.mp4')
        expect(args[:response_target]).to match(%r{s3-staging/video.mp4$})

        # Actually create the file so File.size doesn't fail
        FileUtils.mkdir_p(File.dirname(args[:response_target]))
        File.write(args[:response_target], 'downloaded content')
      end

      expect { s3_ops.download(dry_run: false) }.to output(/✓ Downloaded: video.mp4/).to_stdout
    end

    it 'skips files with matching MD5' do
      local_file = File.join(staging_dir, 'video.mp4')
      File.write(local_file, 'existing content')
      local_md5 = Digest::MD5.hexdigest('existing content')

      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => "\"#{local_md5}\"" }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).not_to receive(:get_object)

      expect { s3_ops.download(dry_run: false) }.to output(/⏭️  Skipped: video.mp4/).to_stdout
    end

    it 'creates project directory if it does not exist' do
      # Remove the entire project directory
      FileUtils.rm_rf(project_dir)

      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:get_object) do |args|
        FileUtils.mkdir_p(File.dirname(args[:response_target]))
        File.write(args[:response_target], 'downloaded content')
      end

      expect do
        s3_ops.download(dry_run: false)
      end.to output(/📁 Creating project directory: test-project/).to_stdout

      # Verify directory was created
      expect(Dir.exist?(project_dir)).to be true
    end

    it 'shows download timing in output' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:get_object) do |args|
        FileUtils.mkdir_p(File.dirname(args[:response_target]))
        File.write(args[:response_target], 'downloaded content')
      end

      expect do
        s3_ops.download(dry_run: false)
      end.to output(/✓ Downloaded: video\.mp4 \(\d+\.?\d* [KMGT]?B\) in \d+\.?\d*s/).to_stdout
    end
  end

  describe '#status' do
    let(:s3_ops) { create_s3_operations }

    it 'reports when no files in S3 or locally' do
      FileUtils.rm_rf(Dir.glob("#{staging_dir}/*"))
      allow(s3_ops).to receive(:list_s3_files).and_return([])

      expect { s3_ops.status }.to output(/❌ No files found in S3 or locally/).to_stdout
    end

    it 'shows in-sync files' do
      local_file = File.join(staging_dir, 'video.mp4')
      File.write(local_file, 'synced content')
      local_md5 = Digest::MD5.hexdigest('synced content')

      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => "\"#{local_md5}\"" }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect { s3_ops.status }.to output(/video.mp4.*\[synced\]/).to_stdout
    end

    it 'shows out-of-sync files' do
      local_file = File.join(staging_dir, 'video.mp4')
      File.write(local_file, 'different content')

      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"different_md5"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect { s3_ops.status }.to output(/video.mp4.*\[modified\]/).to_stdout
    end

    it 'shows S3-only files' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/remote-only.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect { s3_ops.status }.to output(/remote-only.mp4.*\[S3 only\]/).to_stdout
    end

    it 'shows local-only files' do
      local_file = File.join(staging_dir, 'local-only.srt')
      File.write(local_file, 'local content')

      allow(s3_ops).to receive(:list_s3_files).and_return([])

      expect { s3_ops.status }.to output(/local-only.srt.*\[local only\]/).to_stdout
    end

    it 'shows summary with file counts and sizes' do
      # Remove the default test-file.txt first
      FileUtils.rm_rf(Dir.glob("#{staging_dir}/*"))

      # Create mixed scenario
      local_synced = File.join(staging_dir, 'synced.mp4')
      File.write(local_synced, 'synced content')
      local_md5 = Digest::MD5.hexdigest('synced content')

      local_only = File.join(staging_dir, 'local.srt')
      File.write(local_only, 'local content')

      s3_files = [
        { 'Key' => 'staging/v-test/test-project/synced.mp4', 'Size' => 1024, 'ETag' => "\"#{local_md5}\"" },
        { 'Key' => 'staging/v-test/test-project/s3-only.mp4', 'Size' => 2048, 'ETag' => '"abc123"' }
      ]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect { s3_ops.status }.to output(/S3 files: 2, Local files: 2/).to_stdout
    end
  end

  describe '#cleanup' do
    let(:s3_ops) { create_s3_operations }

    it 'reports when no files in S3' do
      allow(s3_ops).to receive(:list_s3_files).and_return([])

      expect { s3_ops.cleanup(force: false, dry_run: false) }.to output(/❌ No files found in S3/).to_stdout
    end

    it 'requires --force flag to proceed' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect do
        s3_ops.cleanup(force: false, dry_run: false)
      end.to output(/Use --force to confirm deletion/).to_stdout
    end

    it 'performs dry-run cleanup without deleting' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).not_to receive(:delete_object)

      expect do
        s3_ops.cleanup(force: true, dry_run: true)
      end.to output(/\[DRY-RUN\] Would delete/).to_stdout
    end

    it 'deletes files from S3 with force flag' do
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:delete_object).with(
        bucket: 'test-bucket',
        key: 'staging/v-test/test-project/video.mp4'
      )

      expect { s3_ops.cleanup(force: true, dry_run: false) }.to output(/✓ Deleted: video.mp4/).to_stdout
    end
  end

  describe '#list_s3_files' do
    let(:s3_ops) { create_s3_operations }

    it 'returns empty array when no files exist' do
      response = instance_double(Aws::S3::Types::ListObjectsV2Output, contents: nil)
      allow(mock_s3_client).to receive(:list_objects_v2).and_return(response)

      expect(s3_ops.send(:list_s3_files)).to eq([])
    end

    it 'lists files with correct prefix' do
      file1 = instance_double(Aws::S3::Types::Object, key: 'staging/v-test/test-project/file1.mp4', size: 1024,
                                                      etag: '"abc123"')
      file2 = instance_double(Aws::S3::Types::Object, key: 'staging/v-test/test-project/file2.srt', size: 512,
                                                      etag: '"def456"')

      response = instance_double(Aws::S3::Types::ListObjectsV2Output, contents: [file1, file2])

      expect(mock_s3_client).to receive(:list_objects_v2).with(
        bucket: 'test-bucket',
        prefix: 'staging/v-test/test-project/'
      ).and_return(response)

      files = s3_ops.send(:list_s3_files)

      expect(files.size).to eq(2)
      expect(files[0]['Key']).to eq('staging/v-test/test-project/file1.mp4')
      expect(files[1]['Key']).to eq('staging/v-test/test-project/file2.srt')
    end
  end

  describe '#cleanup_local' do
    let(:s3_ops) { create_s3_operations }

    it 'reports when s3-staging directory does not exist' do
      FileUtils.rm_rf(staging_dir)

      expect { s3_ops.cleanup_local(force: false, dry_run: false) }.to output(/❌ No s3-staging directory found/).to_stdout
    end

    it 'reports when no files in s3-staging' do
      FileUtils.rm_rf(Dir.glob("#{staging_dir}/*"))

      expect { s3_ops.cleanup_local(force: false, dry_run: false) }.to output(/❌ No files found in s3-staging/).to_stdout
    end

    it 'requires --force flag to proceed' do
      expect do
        s3_ops.cleanup_local(force: false, dry_run: false)
      end.to output(/Use --force to confirm deletion/).to_stdout
    end

    it 'performs dry-run cleanup without deleting' do
      expect do
        s3_ops.cleanup_local(force: true, dry_run: true)
      end.to output(/\[DRY-RUN\] Would delete/).to_stdout

      expect(File.exist?(File.join(staging_dir, 'test-file.txt'))).to be true
    end

    it 'deletes local files with force flag' do
      # Create a nested file structure
      FileUtils.mkdir_p(File.join(staging_dir, 'subfolder'))
      File.write(File.join(staging_dir, 'subfolder', 'nested.txt'), 'nested content')

      expect do
        s3_ops.cleanup_local(force: true, dry_run: false)
      end.to output(/✓ Deleted/).to_stdout

      # Files should be deleted
      expect(File.exist?(File.join(staging_dir, 'test-file.txt'))).to be false
      expect(File.exist?(File.join(staging_dir, 'subfolder', 'nested.txt'))).to be false

      # Empty directories should be cleaned up
      expect(Dir.exist?(File.join(staging_dir, 'subfolder'))).to be false
    end

    it 'reports deleted and failed counts' do
      expect do
        s3_ops.cleanup_local(force: true, dry_run: false)
      end.to output(/Deleted: 1, Failed: 0/).to_stdout
    end
  end

  describe '#archive' do
    let(:ssd_backup) { File.join(temp_dir, 'ssd-backup') }
    let(:s3_ops) { create_s3_operations }

    before do
      # Create SSD backup directory
      FileUtils.mkdir_p(ssd_backup)

      # Update brand_info to include ssd_backup location
      allow(brand_info.locations).to receive(:ssd_backup).and_return(ssd_backup)
    end

    it 'reports error when SSD backup location not configured' do
      allow(brand_info.locations).to receive(:ssd_backup).and_return(nil)

      expect { s3_ops.archive(force: false, dry_run: false) }.to output(/❌ SSD backup location not configured/).to_stdout
    end

    it 'reports error when SSD not mounted' do
      FileUtils.rm_rf(ssd_backup)

      expect { s3_ops.archive(force: false, dry_run: false) }.to output(/❌ SSD not mounted/).to_stdout
    end

    it 'reports error when project does not exist' do
      bad_ops = described_class.new('test', 'non-existent-project',
                                    brand_info: brand_info,
                                    brand_path: brand_path,
                                    s3_client: mock_s3_client)

      expect { bad_ops.archive(force: false, dry_run: false) }.to output(/❌ Project not found/).to_stdout
    end

    it 'performs dry-run archive without copying' do
      expect do
        s3_ops.archive(force: false, dry_run: true)
      end.to output(/\[DRY-RUN\] Would copy project to SSD \(excluding node_modules, \.git, etc\.\)/).to_stdout

      expect(Dir.exist?(File.join(ssd_backup, 'test-project'))).to be false
    end

    it 'copies project to SSD without deleting local copy' do
      expect do
        s3_ops.archive(force: false, dry_run: false)
      end.to output(/✅ Copied to SSD/).to_stdout

      expect(Dir.exist?(File.join(ssd_backup, 'test-project'))).to be true
      expect(Dir.exist?(File.join(brand_path, 'test-project'))).to be true
    end

    it 'warns when not using --force' do
      expect do
        s3_ops.archive(force: false, dry_run: false)
      end.to output(/⚠️  Project copied to SSD but NOT deleted locally/).to_stdout
    end

    it 'copies and deletes local project with --force' do
      expect do
        s3_ops.archive(force: true, dry_run: false)
      end.to output(/✅ Deleted local folder/).to_stdout

      expect(Dir.exist?(File.join(ssd_backup, 'test-project'))).to be true
      expect(Dir.exist?(File.join(brand_path, 'test-project'))).to be false
    end

    it 'skips copy when project already exists on SSD' do
      # Create existing SSD copy
      FileUtils.mkdir_p(File.join(ssd_backup, 'test-project'))

      expect do
        s3_ops.archive(force: false, dry_run: false)
      end.to output(/⚠️  Already exists on SSD/).to_stdout
    end
  end

  describe '#excluded_path?' do
    let(:s3_ops) { create_s3_operations }

    it 'excludes Windows Zone.Identifier files' do
      expect(s3_ops.send(:excluded_path?, 'video.mp4:Zone.Identifier')).to be true
      expect(s3_ops.send(:excluded_path?, 'folder/file.txt:Zone.Identifier')).to be true
    end

    it 'excludes .DS_Store files' do
      expect(s3_ops.send(:excluded_path?, '.DS_Store')).to be true
      expect(s3_ops.send(:excluded_path?, 'folder/.DS_Store')).to be true
    end

    it 'excludes node_modules directories' do
      expect(s3_ops.send(:excluded_path?, 'node_modules/package.json')).to be true
      expect(s3_ops.send(:excluded_path?, 'folder/node_modules/index.js')).to be true
    end

    it 'excludes .git directories' do
      expect(s3_ops.send(:excluded_path?, '.git/config')).to be true
      expect(s3_ops.send(:excluded_path?, 'folder/.git/HEAD')).to be true
    end

    it 'excludes build artifact directories' do
      expect(s3_ops.send(:excluded_path?, 'dist/bundle.js')).to be true
      expect(s3_ops.send(:excluded_path?, 'build/output.js')).to be true
      expect(s3_ops.send(:excluded_path?, '.next/static/page.js')).to be true
    end

    it 'does not exclude normal files' do
      expect(s3_ops.send(:excluded_path?, 'video.mp4')).to be false
      expect(s3_ops.send(:excluded_path?, 'subtitle.srt')).to be false
      expect(s3_ops.send(:excluded_path?, 'folder/document.pdf')).to be false
    end
  end

  describe 'projects_subfolder support' do
    let(:subfolder_brands_data) do
      {
        'brands' => {
          'test-subfolder' => {
            'name' => 'Test Subfolder Brand',
            'shortcut' => 'tsf',
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
              's3_cleanup_days' => 90,
              'projects_subfolder' => 'projects'
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

    let(:subfolder_brand_info) do
      Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo.new(
        'test-subfolder',
        subfolder_brands_data['brands']['test-subfolder']
      )
    end

    let(:subfolder_project_dir) { File.join(brand_path, 'projects', 'test-project') }
    let(:subfolder_staging_dir) { File.join(subfolder_project_dir, 's3-staging') }

    before do
      FileUtils.mkdir_p(subfolder_staging_dir)
      File.write(File.join(subfolder_staging_dir, 'subfolder-test.txt'), 'subfolder content')
    end

    def create_subfolder_s3_operations
      described_class.new(
        'test-subfolder',
        'test-project',
        brand_info: subfolder_brand_info,
        brand_path: brand_path,
        s3_client: mock_s3_client
      )
    end

    it 'constructs correct path with projects_subfolder for upload' do
      s3_ops = create_subfolder_s3_operations
      allow(s3_ops).to receive(:s3_file_md5).and_return(nil)

      expect(mock_s3_client).to receive(:put_object) do |args|
        expect(args[:key]).to eq('staging/v-test/test-project/subfolder-test.txt')
      end

      s3_ops.upload(dry_run: false)
    end

    it 'constructs correct path with projects_subfolder for download' do
      s3_ops = create_subfolder_s3_operations
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:get_object) do |args|
        expect(args[:response_target]).to match(%r{projects/test-project/s3-staging/video\.mp4$})
        FileUtils.mkdir_p(File.dirname(args[:response_target]))
        File.write(args[:response_target], 'downloaded content')
      end

      s3_ops.download(dry_run: false)
    end

    it 'constructs correct path with projects_subfolder for status' do
      s3_ops = create_subfolder_s3_operations
      allow(s3_ops).to receive(:list_s3_files).and_return([])

      expect do
        s3_ops.status
      end.to output(%r{test-subfolder/test-project}).to_stdout
    end

    it 'creates project directory in subfolder when downloading to non-existent project' do
      FileUtils.rm_rf(subfolder_project_dir)

      s3_ops = create_subfolder_s3_operations
      s3_files = [{ 'Key' => 'staging/v-test/test-project/video.mp4', 'Size' => 1024, 'ETag' => '"abc123"' }]
      allow(s3_ops).to receive(:list_s3_files).and_return(s3_files)

      expect(mock_s3_client).to receive(:get_object) do |args|
        FileUtils.mkdir_p(File.dirname(args[:response_target]))
        File.write(args[:response_target], 'downloaded content')
      end

      expect do
        s3_ops.download(dry_run: false)
      end.to output(/📁 Creating project directory: test-project/).to_stdout

      expect(Dir.exist?(subfolder_project_dir)).to be true
    end

    it 'defaults to empty string when projects_subfolder not configured' do
      expect(brand_info.settings.projects_subfolder).to eq('')
    end

    it 'returns configured projects_subfolder value' do
      expect(subfolder_brand_info.settings.projects_subfolder).to eq('projects')
    end
  end
end
