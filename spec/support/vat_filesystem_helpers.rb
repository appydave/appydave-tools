# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Shared context for VAT specs that need temporary filesystem fixtures
#
# Provides:
# - temp_folder: Temporary root directory (auto-cleaned)
# - projects_root: /path/to/temp/video-projects
# - Mock configuration for SettingsConfig.video_projects_root
#
# Usage:
#   include_context 'with vat filesystem'
#
# Optional brand paths (create on demand):
#   include_context 'with vat filesystem and brands', brands: %w[appydave voz]
#
# rubocop:disable RSpec/AnyInstance
RSpec.shared_context 'with vat filesystem' do
  let(:temp_folder) { Dir.mktmpdir }
  let(:projects_root) { File.join(temp_folder, 'video-projects') }

  before do
    # Create projects_root directory
    FileUtils.mkdir_p(projects_root)

    # Mock SettingsConfig to return our test projects_root
    allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
      .to receive(:video_projects_root).and_return(projects_root)
  end

  after do
    # Clean up temp directory
    FileUtils.rm_rf(temp_folder)
  end
end

# Extended context with pre-created brand directories
#
# Usage:
#   include_context 'with vat filesystem and brands', brands: %w[appydave voz aitldr]
#
# Provides additional lets:
#   - appydave_path, voz_path, aitldr_path, etc. (one for each brand)
#
RSpec.shared_context 'with vat filesystem and brands' do |brands: []|
  include_context 'with vat filesystem'

  # Dynamically create let() helpers for each brand
  # e.g., brands: ['appydave'] creates let(:appydave_path)
  brands.each do |brand|
    let(:"#{brand}_path") do
      expanded = Appydave::Tools::Vat::Config.expand_brand(brand)
      path = File.join(projects_root, expanded)
      FileUtils.mkdir_p(path)
      path
    end
  end
end
# rubocop:enable RSpec/AnyInstance
