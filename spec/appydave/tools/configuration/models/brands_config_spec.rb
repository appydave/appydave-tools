# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::Models::BrandsConfig do
  let(:temp_folder) { Dir.mktmpdir }
  let(:brands_config) { described_class.new }
  let(:config_file) { File.join(temp_folder, 'brands.json') }
  let(:config_data) do
    {
      'brands' => {
        'appydave' => {
          'name' => 'AppyDave',
          'shortcut' => 'ad',
          'type' => 'owned',
          'youtube_channels' => ['appydave'],
          'team' => %w[david jan],
          'locations' => {
            'video_projects' => '/Users/davidcruwys/dev/video-projects/v-appydave',
            'ssd_backup' => '/Volumes/T7/youtube-PUBLISHED/appydave'
          },
          'aws' => {
            'profile' => 'david-appydave',
            'region' => 'ap-southeast-1',
            's3_bucket' => 'appydave-video-projects',
            's3_prefix' => 'staging/v-appydave/'
          },
          'settings' => {
            's3_cleanup_days' => 90
          }
        },
        'voz' => {
          'name' => 'VOZ Creative',
          'shortcut' => 'voz',
          'type' => 'client',
          'youtube_channels' => [],
          'team' => ['vasilios'],
          'locations' => {
            'video_projects' => '/Users/davidcruwys/dev/video-projects/v-voz',
            'ssd_backup' => '/Volumes/T7/voz'
          },
          'aws' => {
            'profile' => 'vasilios-voz',
            'region' => 'ap-southeast-1',
            's3_bucket' => 'appydave-video-projects',
            's3_prefix' => 'staging/v-voz/'
          },
          'settings' => {
            's3_cleanup_days' => 90
          }
        }
      },
      'users' => {
        'david' => {
          'name' => 'David Cruwys',
          'email' => 'david@appydave.com',
          'role' => 'owner',
          'default_aws_profile' => 'david-appydave'
        },
        'vasilios' => {
          'name' => 'Vasilios Kapenekas',
          'role' => 'client',
          'default_aws_profile' => 'vasilios-voz'
        }
      }
    }
  end

  before do
    File.write(config_file, config_data.to_json)
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    describe '.name' do
      subject { brands_config.name }

      it { is_expected.to eq('Brands') }
    end

    describe '.config_name' do
      subject { brands_config.config_name }

      it { is_expected.to eq('brands') }
    end

    describe '.config_path' do
      subject { brands_config.config_path }

      it { is_expected.to eq(config_file) }
    end

    describe '.data' do
      subject { brands_config.data }

      it { is_expected.to eq(config_data) }
    end
  end

  describe '#get_brand' do
    it 'retrieves existing brand information by string key' do
      brand = brands_config.get_brand('appydave')

      expect(brand.name).to eq('AppyDave')
      expect(brand.shortcut).to eq('ad')
      expect(brand.type).to eq('owned')
    end

    it 'retrieves existing brand information by symbol key' do
      brand = brands_config.get_brand(:appydave)

      expect(brand.name).to eq('AppyDave')
      expect(brand.shortcut).to eq('ad')
    end

    it 'returns default brand information for a non-existent brand' do
      brand = brands_config.get_brand('nonexistent_brand')

      expect(brand.name).to eq('')
      expect(brand.shortcut).to eq('')
      expect(brand.type).to eq('owned')
    end

    describe '.youtube_channels' do
      it 'retrieves youtube_channels array' do
        brand = brands_config.get_brand('appydave')

        expect(brand.youtube_channels).to eq(['appydave'])
      end

      it 'returns empty array for brand with no YouTube channels' do
        brand = brands_config.get_brand('voz')

        expect(brand.youtube_channels).to eq([])
      end
    end

    describe '.team' do
      it 'retrieves team members array' do
        brand = brands_config.get_brand('appydave')

        expect(brand.team).to eq(%w[david jan])
      end
    end

    describe '.locations' do
      it 'retrieves brand locations' do
        brand = brands_config.get_brand('appydave')

        expect(brand.locations.video_projects).to eq('/Users/davidcruwys/dev/video-projects/v-appydave')
        expect(brand.locations.ssd_backup).to eq('/Volumes/T7/youtube-PUBLISHED/appydave')
      end
    end

    describe '.aws' do
      it 'retrieves AWS configuration' do
        brand = brands_config.get_brand('appydave')

        expect(brand.aws.profile).to eq('david-appydave')
        expect(brand.aws.region).to eq('ap-southeast-1')
        expect(brand.aws.s3_bucket).to eq('appydave-video-projects')
        expect(brand.aws.s3_prefix).to eq('staging/v-appydave/')
      end
    end

    describe '.settings' do
      it 'retrieves brand settings' do
        brand = brands_config.get_brand('appydave')

        expect(brand.settings.s3_cleanup_days).to eq(90)
      end
    end
  end

  describe '#set_brand' do
    let(:new_brand) do
      described_class::BrandInfo.new('kiros',
                                     'name' => 'Kiros',
                                     'shortcut' => 'kiros',
                                     'type' => 'client',
                                     'youtube_channels' => [],
                                     'team' => ['ronnie'],
                                     'locations' => {
                                       'video_projects' => '/Users/davidcruwys/dev/video-projects/v-kiros',
                                       'ssd_backup' => '/Volumes/T7/kiros'
                                     },
                                     'aws' => {
                                       'profile' => 'ronnie-kiros',
                                       'region' => 'ap-southeast-1',
                                       's3_bucket' => 'appydave-video-projects',
                                       's3_prefix' => 'staging/v-kiros/'
                                     })
    end

    it 'sets new brand information and persists it' do
      brands_config.set_brand('kiros', new_brand)
      brands_config.save

      reloaded_brands_config = described_class.new
      reloaded_brand = reloaded_brands_config.get_brand('kiros')

      expect(reloaded_brand.name).to eq('Kiros')
      expect(reloaded_brand.shortcut).to eq('kiros')
      expect(reloaded_brand.type).to eq('client')
      expect(reloaded_brand.team).to eq(['ronnie'])
    end
  end

  describe '#brands' do
    it 'returns a list of all brands' do
      brands = brands_config.brands
      expect(brands.size).to eq(2)
      expect(brands.first.name).to eq('AppyDave')
      expect(brands.first.shortcut).to eq('ad')
      expect(brands.last.name).to eq('VOZ Creative')
      expect(brands.last.shortcut).to eq('voz')
    end
  end

  describe '#get_brands_for_user' do
    it 'returns brands for a specific user' do
      brands = brands_config.get_brands_for_user('david')
      expect(brands.size).to eq(1)
      expect(brands.first.name).to eq('AppyDave')
    end

    it 'returns brands for a user with symbol key' do
      brands = brands_config.get_brands_for_user(:vasilios)
      expect(brands.size).to eq(1)
      expect(brands.first.name).to eq('VOZ Creative')
    end

    it 'returns empty array for user with no brands' do
      brands = brands_config.get_brands_for_user('nonexistent_user')
      expect(brands).to eq([])
    end
  end

  describe '#get_user' do
    it 'retrieves existing user information by string key' do
      user = brands_config.get_user('david')

      expect(user.name).to eq('David Cruwys')
      expect(user.email).to eq('david@appydave.com')
      expect(user.role).to eq('owner')
      expect(user.default_aws_profile).to eq('david-appydave')
    end

    it 'retrieves existing user information by symbol key' do
      user = brands_config.get_user(:david)

      expect(user.name).to eq('David Cruwys')
    end

    it 'returns default user information for a non-existent user' do
      user = brands_config.get_user('nonexistent_user')

      expect(user.name).to eq('')
      expect(user.role).to eq('team_member')
    end
  end

  describe '#set_user' do
    let(:new_user) do
      described_class::UserInfo.new('jan',
                                    'name' => 'Jan',
                                    'role' => 'team_member',
                                    'default_aws_profile' => 'jan-appydave')
    end

    it 'sets new user information and persists it' do
      brands_config.set_user('jan', new_user)
      brands_config.save

      reloaded_brands_config = described_class.new
      reloaded_user = reloaded_brands_config.get_user('jan')

      expect(reloaded_user.name).to eq('Jan')
      expect(reloaded_user.role).to eq('team_member')
      expect(reloaded_user.default_aws_profile).to eq('jan-appydave')
    end
  end

  describe '#users' do
    it 'returns a list of all users' do
      users = brands_config.users
      expect(users.size).to eq(2)
      expect(users.first.name).to eq('David Cruwys')
      expect(users.last.name).to eq('Vasilios Kapenekas')
    end
  end

  describe '#key?' do
    it 'returns true for an existing brand key' do
      expect(brands_config.key?('appydave')).to be true
    end

    it 'returns false for a non-existent brand key' do
      expect(brands_config.key?('nonexistent')).to be false
    end
  end

  describe '#shortcut?' do
    it 'returns true for an existing brand shortcut' do
      expect(brands_config.shortcut?('ad')).to be true
      expect(brands_config.shortcut?('voz')).to be true
    end

    it 'returns false for a non-existent brand shortcut' do
      expect(brands_config.shortcut?('nonexistent')).to be false
    end
  end
end
