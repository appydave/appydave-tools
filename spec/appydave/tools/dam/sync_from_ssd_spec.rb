# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubleReference
RSpec.describe Appydave::Tools::Dam::SyncFromSsd do
  let(:brand) { 'test' }
  let(:brand_path) { File.join(temp_dir, 'v-test') }
  let(:ssd_backup) { File.join(temp_dir, 'ssd-backup') }
  let(:temp_dir) { Dir.mktmpdir }

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

  let(:sync_from_ssd) do
    described_class.new(brand, brand_info: brand_info, brand_path: brand_path)
  end

  before do
    FileUtils.mkdir_p(brand_path)
    FileUtils.mkdir_p(ssd_backup)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'creates SyncFromSsd with brand and dependency injection' do
      expect(sync_from_ssd.brand).to eq('test')
      expect(sync_from_ssd.brand_path).to eq(brand_path)
      expect(sync_from_ssd.brand_info).to eq(brand_info)
    end
  end

  describe '#sync' do
    let(:manifest_file) { File.join(brand_path, 'projects.json') }

    context 'when SSD backup not configured' do
      before do
        allow(brand_location).to receive(:ssd_backup).and_return(nil)
      end

      it 'shows error message' do
        expect { sync_from_ssd.sync }.to output(/SSD backup location not configured/).to_stdout
      end
    end

    context 'when SSD not mounted' do
      before do
        allow(brand_location).to receive(:ssd_backup).and_return('/nonexistent/path')
      end

      it 'shows error message' do
        expect { sync_from_ssd.sync }.to output(/SSD not mounted/).to_stdout
      end
    end

    context 'when manifest not found' do
      it 'shows error message' do
        expect { sync_from_ssd.sync }.to output(/projects\.json not found/).to_stdout
      end
    end

    context 'when manifest exists' do
      let(:manifest_data) do
        {
          config: {
            brand: 'test',
            last_updated: '2025-11-10T00:00:00Z'
          },
          projects: [
            {
              id: 'b65-test-project',
              storage: {
                ssd: { exists: true, path: 'b65-test-project' },
                local: { exists: false, structure: nil }
              }
            }
          ]
        }
      end

      before do
        File.write(manifest_file, JSON.pretty_generate(manifest_data))
      end

      context 'with no projects to sync' do
        let(:manifest_data) do
          {
            config: {
              brand: 'test',
              last_updated: '2025-11-10T00:00:00Z'
            },
            projects: [
              {
                id: 'b65-test-project',
                storage: {
                  ssd: { exists: false },
                  local: { exists: true, structure: 'flat' }
                }
              }
            ]
          }
        end

        it 'shows nothing to sync message' do
          expect { sync_from_ssd.sync }.to output(/Nothing to sync/).to_stdout
        end
      end

      context 'with projects to sync' do
        let(:ssd_project_dir) { File.join(ssd_backup, 'b65-test-project') }

        before do
          FileUtils.mkdir_p(ssd_project_dir)
          File.write(File.join(ssd_project_dir, 'subtitle.srt'), 'subtitle content')
          File.write(File.join(ssd_project_dir, 'image.jpg'), 'image content')
          File.write(File.join(ssd_project_dir, 'video.mp4'), 'video content') # Should be excluded
        end

        it 'syncs light files only' do
          expect { sync_from_ssd.sync }.to output(/Sync complete/).to_stdout

          # Check light files copied
          local_archived = File.join(brand_path, 'archived', '60-69', 'b65-test-project')
          expect(File.exist?(File.join(local_archived, 'subtitle.srt'))).to be true
          expect(File.exist?(File.join(local_archived, 'image.jpg'))).to be true

          # Check heavy file NOT copied
          expect(File.exist?(File.join(local_archived, 'video.mp4'))).to be false
        end

        it 'shows sync summary' do
          output = capture_output { sync_from_ssd.sync }

          expect(output).to include('Total projects in manifest: 1')
          expect(output).to include('Projects to sync: 1')
          expect(output).to include('2 file(s)') # Only light files
        end

        context 'with dry-run mode' do
          it 'previews sync without copying files' do
            expect { sync_from_ssd.sync(dry_run: true) }.to output(/DRY-RUN MODE/).to_stdout

            local_archived = File.join(brand_path, 'archived', '60-69', 'b65-test-project')
            expect(File.exist?(File.join(local_archived, 'subtitle.srt'))).to be false
            expect(File.exist?(File.join(local_archived, 'image.jpg'))).to be false
          end

          it 'shows what would be copied' do
            output = capture_output { sync_from_ssd.sync(dry_run: true) }

            expect(output).to include('[DRY-RUN] Would copy: subtitle.srt')
            expect(output).to include('[DRY-RUN] Would copy: image.jpg')
          end
        end

        context 'when SSD path does not exist' do
          before do
            FileUtils.rm_rf(ssd_project_dir)
          end

          it 'skips project with reason' do
            output = capture_output { sync_from_ssd.sync }

            expect(output).to include('Skipped: SSD path not found')
          end
        end

        context 'when flat folder exists (stale manifest)' do
          before do
            FileUtils.mkdir_p(File.join(brand_path, 'b65-test-project'))
          end

          it 'skips project with warning' do
            output = capture_output { sync_from_ssd.sync }

            expect(output).to include('Skipped: Flat folder exists')
          end
        end

        context 'when files already synced' do
          before do
            # Pre-sync files
            sync_from_ssd.sync
          end

          it 'skips already synced files' do
            # Sync again
            output = capture_output { sync_from_ssd.sync }

            # Should show 0 files synced (all skipped) in summary
            expect(output).to include('Files copied: 0')
            expect(output).to include('Total size: 0B')
          end
        end
      end

      context 'with multiple projects' do
        let(:manifest_data) do
          {
            config: {
              brand: 'test',
              last_updated: '2025-11-10T00:00:00Z'
            },
            projects: [
              {
                id: 'b40-project-one',
                storage: {
                  ssd: { exists: true, path: 'b40-project-one' },
                  local: { exists: false }
                }
              },
              {
                id: 'b41-project-two',
                storage: {
                  ssd: { exists: true, path: 'b41-project-two' },
                  local: { exists: false }
                }
              },
              {
                id: 'b42-project-three',
                storage: {
                  ssd: { exists: false }, # Not on SSD
                  local: { exists: true, structure: 'flat' }
                }
              }
            ]
          }
        end

        before do
          # Create SSD projects
          %w[b40-project-one b41-project-two].each do |project_id|
            project_dir = File.join(ssd_backup, project_id)
            FileUtils.mkdir_p(project_dir)
            File.write(File.join(project_dir, 'subtitle.srt'), 'content')
          end
        end

        it 'syncs all eligible projects' do
          output = capture_output { sync_from_ssd.sync }

          expect(output).to include('Total projects in manifest: 3')
          expect(output).to include('Projects to sync: 2')
          expect(output).to include('Skipped (already local): 1')
        end

        it 'creates proper directory structure for each project' do
          sync_from_ssd.sync

          expect(Dir.exist?(File.join(brand_path, 'archived', '40-49', 'b40-project-one'))).to be true
          expect(Dir.exist?(File.join(brand_path, 'archived', '40-49', 'b41-project-two'))).to be true
        end
      end
    end
  end

  describe '#determine_range' do
    it 'determines range for FliVideo pattern b40-b49' do
      range = sync_from_ssd.send(:determine_range, 'b40-test-project')
      expect(range).to eq('40-49')
    end

    it 'determines range for FliVideo pattern b65-b69' do
      range = sync_from_ssd.send(:determine_range, 'b65-guy-monroe')
      expect(range).to eq('60-69')
    end

    it 'determines range for FliVideo pattern b99-b99' do
      range = sync_from_ssd.send(:determine_range, 'b99-final-project')
      expect(range).to eq('90-99')
    end

    it 'returns default range for non-FliVideo pattern' do
      range = sync_from_ssd.send(:determine_range, 'boy-baker')
      expect(range).to eq('000-099')
    end
  end

  describe '#heavy_file?' do
    it 'identifies MP4 as heavy file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/video.mp4')).to be true
    end

    it 'identifies MOV as heavy file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/video.mov')).to be true
    end

    it 'identifies AVI as heavy file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/video.avi')).to be true
    end

    it 'identifies MKV as heavy file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/video.mkv')).to be true
    end

    it 'identifies WEBM as heavy file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/video.webm')).to be true
    end

    it 'identifies SRT as light file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/subtitle.srt')).to be false
    end

    it 'identifies JPG as light file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/image.jpg')).to be false
    end

    it 'identifies MD as light file' do
      expect(sync_from_ssd.send(:heavy_file?, '/path/to/readme.md')).to be false
    end
  end

  describe '#file_already_synced?' do
    let(:source_file) { File.join(temp_dir, 'source.txt') }
    let(:dest_file) { File.join(temp_dir, 'dest.txt') }

    before do
      File.write(source_file, 'content')
    end

    it 'returns true when files have same size' do
      File.write(dest_file, 'content')
      expect(sync_from_ssd.send(:file_already_synced?, source_file, dest_file)).to be true
    end

    it 'returns false when dest file does not exist' do
      expect(sync_from_ssd.send(:file_already_synced?, source_file, dest_file)).to be false
    end

    it 'returns false when files have different sizes' do
      File.write(dest_file, 'different content')
      expect(sync_from_ssd.send(:file_already_synced?, source_file, dest_file)).to be false
    end
  end

  describe '#format_bytes' do
    it 'formats bytes' do
      expect(sync_from_ssd.send(:format_bytes, 500)).to eq('500B')
    end

    it 'formats kilobytes' do
      expect(sync_from_ssd.send(:format_bytes, 2048)).to eq('2.0KB')
    end

    it 'formats megabytes' do
      expect(sync_from_ssd.send(:format_bytes, 2_097_152)).to eq('2.0MB')
    end
  end

  # Helper method to capture stdout
  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
# rubocop:enable RSpec/VerifiedDoubleReference
