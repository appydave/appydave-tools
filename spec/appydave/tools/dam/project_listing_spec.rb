# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::ProjectListing do
  let(:temp_root) { Dir.mktmpdir }
  let(:brand1_path) { File.join(temp_root, 'v-appydave') }
  let(:brand2_path) { File.join(temp_root, 'v-voz') }

  before do
    # Setup temp directory structure
    FileUtils.mkdir_p(brand1_path)
    FileUtils.mkdir_p(brand2_path)

    # Create projects for brand1
    FileUtils.mkdir_p(File.join(brand1_path, 'b60-project'))
    FileUtils.mkdir_p(File.join(brand1_path, 'b61-project'))
    FileUtils.mkdir_p(File.join(brand1_path, 'b65-project'))

    # Create projects for brand2
    FileUtils.mkdir_p(File.join(brand2_path, 'boy-baker'))
    FileUtils.mkdir_p(File.join(brand2_path, 'the-point'))

    # Mock Config
    allow(Appydave::Tools::Dam::Config).to receive_messages(projects_root: temp_root, available_brands: %w[appydave voz])
    allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('appydave').and_return(brand1_path)
    allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('v-appydave').and_return(brand1_path)
    allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('voz').and_return(brand2_path)
    allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('v-voz').and_return(brand2_path)
    allow(Appydave::Tools::Dam::Config).to receive(:expand_brand).with('appydave').and_return('v-appydave')
    allow(Appydave::Tools::Dam::Config).to receive(:expand_brand).with('voz').and_return('v-voz')
  end

  after do
    FileUtils.remove_entry(temp_root)
  end

  describe '.list_brands_with_counts' do
    it 'displays brands in tabular format with counts, sizes, and paths' do
      expect { described_class.list_brands_with_counts }.to output(
        a_string_matching(/BRAND\s+PROJECTS\s+SIZE\s+LAST MODIFIED\s+PATH/)
          .and(matching(/appydave\s+3/))
          .and(matching(/voz\s+2/))
          .and(matching(/v-appydave/))
          .and(matching(/v-voz/))
      ).to_stdout
    end

    it 'shows message when no brands found' do
      allow(Appydave::Tools::Dam::Config).to receive(:available_brands).and_return([])

      expect { described_class.list_brands_with_counts }.to output(
        /⚠️  No brands found/
      ).to_stdout
    end

    it 'uses shortened paths with tilde' do
      allow(Dir).to receive(:home).and_return('/Users/testuser')
      allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('appydave')
                                                                 .and_return('/Users/testuser/dev/video-projects/v-appydave')

      expect { described_class.list_brands_with_counts }.to output(
        a_string_matching(%r{~/dev/video-projects/v-appydave})
      ).to_stdout
    end
  end

  describe '.list_brand_projects' do
    it 'displays projects in tabular format with sizes, dates, and paths' do
      expect { described_class.list_brand_projects('appydave') }.to output(
        a_string_matching(/Projects in v-appydave:/)
          .and(matching(/PROJECT\s+SIZE\s+LAST MODIFIED\s+PATH/))
          .and(matching(/b60-project/))
          .and(matching(/b61-project/))
          .and(matching(/b65-project/))
      ).to_stdout
    end

    it 'shows message when no projects found' do
      allow(Appydave::Tools::Dam::ProjectResolver).to receive(:list_projects).and_return([])

      expect { described_class.list_brand_projects('appydave') }.to output(
        /⚠️  No projects found for brand: v-appydave/
      ).to_stdout
    end

    it 'includes full paths with tilde shortening' do
      expect { described_class.list_brand_projects('appydave') }.to output(
        a_string_matching(%r{v-appydave/b60-project})
      ).to_stdout
    end
  end

  describe '.list_with_pattern' do
    before do
      allow(Appydave::Tools::Dam::ProjectResolver).to receive(:resolve_pattern)
        .with(brand1_path, 'b6*')
        .and_return(%w[b60-project b61-project b65-project])
    end

    it 'displays matching projects in tabular format' do
      expect { described_class.list_with_pattern('appydave', 'b6*') }.to output(
        a_string_matching(/Projects matching 'b6\*' in v-appydave:/)
          .and(matching(/PROJECT\s+SIZE\s+LAST MODIFIED\s+PATH/))
          .and(matching(/b60-project/))
          .and(matching(/b61-project/))
          .and(matching(/b65-project/))
      ).to_stdout
    end

    it 'shows message when no matches found' do
      allow(Appydave::Tools::Dam::ProjectResolver).to receive(:resolve_pattern)
        .with(brand1_path, 'b9*')
        .and_return([])

      expect { described_class.list_with_pattern('appydave', 'b9*') }.to output(
        /⚠️  No projects found matching pattern: b9\*/
      ).to_stdout
    end

    it 'includes paths in output' do
      expect { described_class.list_with_pattern('appydave', 'b6*') }.to output(
        a_string_matching(%r{v-appydave/b60-project})
      ).to_stdout
    end
  end

  describe '.shorten_path' do
    it 'replaces home directory with tilde' do
      allow(Dir).to receive(:home).and_return('/Users/testuser')
      path = '/Users/testuser/dev/video-projects/v-appydave'

      result = described_class.shorten_path(path)

      expect(result).to eq('~/dev/video-projects/v-appydave')
    end

    it 'returns path unchanged if not under home' do
      allow(Dir).to receive(:home).and_return('/Users/testuser')
      path = '/var/tmp/video-projects/v-appydave'

      result = described_class.shorten_path(path)

      expect(result).to eq('/var/tmp/video-projects/v-appydave')
    end
  end

  describe '.format_size' do
    it 'formats bytes' do
      expect(described_class.format_size(512)).to eq('512.0 B')
    end

    it 'formats kilobytes' do
      expect(described_class.format_size(1024)).to eq('1.0 KB')
    end

    it 'formats megabytes' do
      expect(described_class.format_size(1024 * 1024)).to eq('1.0 MB')
    end

    it 'formats gigabytes' do
      expect(described_class.format_size(1024 * 1024 * 1024)).to eq('1.0 GB')
    end

    it 'handles zero bytes' do
      expect(described_class.format_size(0)).to eq('0 B')
    end
  end

  describe '.format_date' do
    it 'formats time in YYYY-MM-DD HH:MM format' do
      time = Time.new(2025, 11, 9, 19, 30, 0)
      expect(described_class.format_date(time)).to eq('2025-11-09 19:30')
    end

    it 'returns N/A for nil' do
      expect(described_class.format_date(nil)).to eq('N/A')
    end
  end
end
