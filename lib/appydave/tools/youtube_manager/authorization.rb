# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      # Handle YouTube API Authorization
      class Authorization
        REDIRECT_URI = 'http://localhost:8080/'
        CLIENT_SECRETS_PATH = File.join(Dir.home, '.config', 'appydave-google-youtube.json')
        CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'ad_youtube.yaml')

        SCOPE = [
          'https://www.googleapis.com/auth/youtube.readonly',
          'https://www.googleapis.com/auth/youtube'
        ].freeze

        def self.authorize
          FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

          client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
          token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
          authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
          user_id = 'default'
          credentials = authorizer.get_credentials(user_id)
          credentials = wait_for_authorization(authorizer) if credentials.nil?
          credentials
        end

        def self.wait_for_authorization(authorizer)
          url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
          puts 'Open the following URL in your browser and authorize the application:'
          puts url

          server = WEBrick::HTTPServer.new(Port: 8080, AccessLog: [], Logger: WEBrick::Log.new(nil, 0))
          trap('INT') { server.shutdown }

          server.mount_proc '/' do |req, res|
            auth_code = req.query['code']
            res.body = 'Authorization successful. You can close this window now.'
            server.shutdown
            authorizer.get_and_store_credentials_from_code(
              user_id: user_id, code: auth_code, base_url: REDIRECT_URI
            )
          end

          server.start
        end
      end
    end
  end
end
