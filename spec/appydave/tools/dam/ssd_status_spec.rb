# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubleReference
RSpec.describe Appydave::Tools::Dam::SsdStatus do
  let(:temp_dir) { Dir.mktmpdir }
  let(:brand_path) { File.join(temp_dir, 'v-test') }
  let(:ssd_backup) { '/Volumes/TestSSD/backup/test' }

  let(:brand_location) do
    instance_double(
      'BrandLocation',
      video_projects: brand_path,
      ssd_backup: ssd_backup
    )
  end

  let(:brand_info) do
    instance_double(
      'BrandInfo',
      key: 'test',
      name: 'Test Brand',
      locations: brand_location
    )
  end

  let(:brands_config) do
    config = instance_double('BrandsConfig')
    allow(config).to receive(:brands).and_return([brand_info])
    allow(config).to receive(:get_brand).with('test').and_return(brand_info)
    config
  end

  let(:ssd_status) do
    described_class.new(brands_config: brands_config)
  end

  before do
    FileUtils.mkdir_p(brand_path)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#show_all' do
    context 'when SSD volume is mounted and backup folder exists' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('/Volumes/TestSSD').and_return(true)
        allow(Dir).to receive(:exist?).with(ssd_backup).and_return(true)
      end

      it 'shows MOUNTED status' do
        expect { ssd_status.show_all }.to output(/MOUNTED/).to_stdout
      end

      it 'shows Ready status for brand' do
        expect { ssd_status.show_all }.to output(/Ready/).to_stdout
      end

      it 'shows the brand name' do
        expect { ssd_status.show_all }.to output(/test/).to_stdout
      end
    end

    context 'when SSD volume is not mounted' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('/Volumes/TestSSD').and_return(false)
        allow(Dir).to receive(:exist?).with(ssd_backup).and_return(false)
      end

      it 'shows NOT MOUNTED status' do
        expect { ssd_status.show_all }.to output(/NOT MOUNTED/).to_stdout
      end
    end

    context 'when SSD volume is mounted but folder does not exist' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('/Volumes/TestSSD').and_return(true)
        allow(Dir).to receive(:exist?).with(ssd_backup).and_return(false)
      end

      it 'shows No folder status' do
        expect { ssd_status.show_all }.to output(/No folder/).to_stdout
      end
    end
  end

  describe '#show' do
    context 'when SSD is mounted for brand' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('/Volumes/TestSSD').and_return(true)
        allow(Dir).to receive(:exist?).with(ssd_backup).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(ssd_backup, '*')).and_return([])
      end

      it 'shows detailed status for the brand' do
        expect { ssd_status.show('test') }.to output(/SSD is mounted/).to_stdout
      end

      it 'shows brand name in header' do
        expect { ssd_status.show('test') }.to output(/Test Brand/).to_stdout
      end

      it 'shows project count' do
        expect { ssd_status.show('test') }.to output(/Projects on SSD/).to_stdout
      end
    end

    context 'when SSD backup folder does not exist' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('/Volumes/TestSSD').and_return(false)
        allow(Dir).to receive(:exist?).with(ssd_backup).and_return(false)
      end

      it 'shows NOT mounted message' do
        expect { ssd_status.show('test') }.to output(/NOT mounted/).to_stdout
      end
    end

    context 'when SSD backup is not configured' do
      let(:unconfigured_location) do
        instance_double(
          'BrandLocation',
          video_projects: brand_path,
          ssd_backup: 'NOT-SET'
        )
      end

      let(:unconfigured_brand_info) do
        instance_double(
          'BrandInfo',
          key: 'unconfigured',
          name: 'Unconfigured Brand',
          locations: unconfigured_location
        )
      end

      before do
        allow(brands_config).to receive(:get_brand).with('unconfigured').and_return(unconfigured_brand_info)
      end

      it 'shows not configured message' do
        expect { ssd_status.show('unconfigured') }.to output(/not configured/).to_stdout
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubleReference
