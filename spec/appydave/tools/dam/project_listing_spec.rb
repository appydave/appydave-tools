# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::ProjectListing do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  before do
    # Create projects for appydave brand
    FileUtils.mkdir_p(File.join(appydave_path, 'b60-project'))
    FileUtils.mkdir_p(File.join(appydave_path, 'b61-project'))
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-project'))

    # Create projects for voz brand
    FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
    FileUtils.mkdir_p(File.join(voz_path, 'the-point'))
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
      allow(Appydave::Tools::Dam::Config).to receive(:brand_path).and_call_original
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
      # ProjectResolver.resolve_pattern now expects brand shortcut, not brand_path
      allow(Appydave::Tools::Dam::ProjectResolver).to receive(:resolve_pattern)
        .with('appydave', 'b6*')
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
        .with('appydave', 'b9*')
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

  describe 'projects_subfolder support' do
    let(:ss_brand_path) { File.join(projects_root, 'v-supportsignal') }
    let(:ss_projects_path) { File.join(ss_brand_path, 'projects') }

    before do
      FileUtils.mkdir_p(ss_brand_path)
      FileUtils.mkdir_p(ss_projects_path)

      # Create organizational folders at brand root (should be ignored)
      FileUtils.mkdir_p(File.join(ss_brand_path, 'brand'))
      FileUtils.mkdir_p(File.join(ss_brand_path, 'personas'))

      # Create actual projects in subfolder
      FileUtils.mkdir_p(File.join(ss_projects_path, 'a01-first-project'))
      FileUtils.mkdir_p(File.join(ss_projects_path, 'a02-second-project'))
      File.write(File.join(ss_projects_path, 'a01-first-project', 'test.txt'), 'content')
      File.write(File.join(ss_projects_path, 'a02-second-project', 'test.txt'), 'content')

      # Mock Config for SupportSignal brand
      allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('supportsignal').and_return(ss_brand_path)
      allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('v-supportsignal').and_return(ss_brand_path)
      allow(Appydave::Tools::Dam::Config).to receive(:expand_brand).with('supportsignal').and_return('v-supportsignal')

      # Mock project_path to return paths in subfolder
      allow(Appydave::Tools::Dam::Config).to receive(:project_path) do |_brand, project|
        File.join(ss_projects_path, project)
      end

      # Mock ProjectResolver to return projects from subfolder
      # ProjectResolver now expects the original brand key, not the expanded v-* version
      allow(Appydave::Tools::Dam::ProjectResolver).to receive(:list_projects).with('supportsignal')
                                                                             .and_return(%w[a01-first-project a02-second-project])
    end

    describe '.list_brand_projects' do
      it 'lists projects from subfolder, not brand root' do
        output = capture_stdout { described_class.list_brand_projects('supportsignal') }

        expect(output).to match(/Projects in v-supportsignal:/)
        expect(output).to match(/a01-first-project/)
        expect(output).to match(/a02-second-project/)
        expect(output).not_to match(/brand/)
        expect(output).not_to match(/personas/)
      end

      it 'calculates sizes correctly for subfolder projects' do
        output = capture_stdout { described_class.list_brand_projects('supportsignal') }

        # Should show file sizes (both files have "content" = 7 bytes each)
        expect(output).to match(/7\.0 B/)
      end
    end

    describe '.calculate_total_size' do
      it 'calculates total size from projects in subfolder' do
        total_size = described_class.calculate_total_size('v-supportsignal', %w[a01-first-project a02-second-project])

        # Two files with "content" = 7 bytes each = 14 bytes total
        expect(total_size).to eq(14)
      end
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
