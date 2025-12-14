# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Test PathValidator that returns predetermined results
#
# Use this in tests instead of the real PathValidator to avoid
# filesystem dependencies.
#
# @example
#   validator = TestPathValidator.new(valid_paths: ['~/real-path'])
#   validator.exists?('~/real-path')  # => true
#   validator.exists?('~/fake-path')  # => false
class TestPathValidator
  def initialize(valid_paths: [])
    @valid_paths = valid_paths.map { |p| File.expand_path(p) }
  end

  def exists?(path)
    expanded = File.expand_path(path)
    @valid_paths.include?(expanded)
  end

  def file_exists?(path)
    exists?(path)
  end

  def expand(path)
    File.expand_path(path)
  end
end

# Shared context for Jump specs that need temporary filesystem fixtures
#
# Provides:
# - temp_folder: Temporary root directory (auto-cleaned)
# - config_path: Path to test locations.json
# - Helper methods for building test configs
#
# Usage:
#   include_context 'with jump filesystem'
#
RSpec.shared_context 'with jump filesystem' do
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_folder, 'locations.json') }

  before do
    # Create temp directory
    FileUtils.mkdir_p(temp_folder)

    # Mock the config path
    allow(Appydave::Tools::Configuration::Config).to receive(:config_path).and_return(temp_folder)
  end

  after do
    # Clean up temp directory
    FileUtils.rm_rf(temp_folder)
  end

  # Helper to create a test config with specified data
  def create_test_config(data)
    File.write(config_path, JSON.pretty_generate(data))
    Appydave::Tools::Jump::Config.new(config_path: config_path)
  end

  # Helper to build a minimal valid config
  def minimal_config(locations: [])
    {
      'meta' => { 'version' => '1.0' },
      'categories' => {},
      'brands' => {},
      'clients' => {},
      'locations' => locations
    }
  end

  # Helper to build a full config with brands/clients
  def full_config(locations: [], brands: {}, clients: {})
    {
      'meta' => { 'version' => '1.0' },
      'categories' => {
        'type' => { 'values' => %w[tool gem brand] },
        'technology' => { 'values' => %w[ruby javascript] }
      },
      'brands' => brands,
      'clients' => clients,
      'locations' => locations
    }
  end
end

# Helper module for building test locations
module JumpTestLocations
  def self.ad_tools
    {
      'key' => 'ad-tools',
      'path' => '~/dev/ad/appydave-tools',
      'jump' => 'jad-tools',
      'brand' => 'appydave',
      'type' => 'tool',
      'tags' => %w[ruby cli],
      'description' => 'AppyDave CLI tools'
    }
  end

  def self.flivideo
    {
      'key' => 'flivideo',
      'path' => '~/dev/ad/flivideo',
      'jump' => 'jfli',
      'brand' => 'flivideo',
      'type' => 'tool',
      'tags' => %w[ruby react video],
      'description' => 'FliVideo asset management'
    }
  end

  def self.supportsignal
    {
      'key' => 'ss-app',
      'path' => '~/dev/clients/supportsignal/app',
      'jump' => 'jss-app',
      'client' => 'supportsignal',
      'type' => 'tool',
      'tags' => %w[typescript nextjs],
      'description' => 'SupportSignal app'
    }
  end

  def self.sample_brands
    {
      'appydave' => {
        'aliases' => %w[ad appy],
        'description' => 'AppyDave brand'
      },
      'flivideo' => {
        'aliases' => ['fli'],
        'description' => 'FliVideo brand'
      }
    }
  end

  def self.sample_clients
    {
      'supportsignal' => {
        'aliases' => ['ss'],
        'description' => 'SupportSignal client'
      }
    }
  end
end
