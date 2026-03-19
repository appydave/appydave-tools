# frozen_string_literal: true

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
