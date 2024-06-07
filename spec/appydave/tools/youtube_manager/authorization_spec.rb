# frozen_string_literal: true

# # frozen_string_literal: true

# RSpec.describe Appydave::Tools::YouTubeManager::Authorization do
#   subject { described_class }

#   let(:client_id) { instance_double(Google::Auth::ClientId) }
#   let(:token_store) { instance_double(Google::Auth::Stores::FileTokenStore) }
#   let(:authorizer) { instance_double(Google::Auth::UserAuthorizer) }
#   let(:credentials) { instance_double(Google::Auth::UserRefreshCredentials) }
#   let(:authorization_url) { 'http://example.com/auth' }

#   before do
#     allow(Google::Auth::ClientId).to receive(:from_file).and_return(client_id)
#     allow(Google::Auth::Stores::FileTokenStore).to receive(:new).and_return(token_store)
#     allow(Google::Auth::UserAuthorizer).to receive(:new).and_return(authorizer)
#     allow(FileUtils).to receive(:mkdir_p)
#     allow(authorizer).to receive_messages(get_credentials: nil, get_authorization_url: authorization_url, get_and_store_credentials_from_code: credentials)
#     allow(subject).to receive(:wait_for_authorization).and_return(credentials)
#   end

#   it 'creates the necessary directories' do
#     subject.authorize
#     expect(FileUtils).to have_received(:mkdir_p).with(File.dirname(Appydave::Tools::YouTubeManager::Authorization::CREDENTIALS_PATH))
#   end

#   it 'creates client id from file' do
#     subject.authorize
#     expect(Google::Auth::ClientId).to have_received(:from_file).with(Appydave::Tools::YouTubeManager::Authorization::CLIENT_SECRETS_PATH)
#   end

#   it 'creates token store' do
#     subject.authorize
#     expect(Google::Auth::Stores::FileTokenStore).to have_received(:new).with(file: Appydave::Tools::YouTubeManager::Authorization::CREDENTIALS_PATH)
#   end

#   it 'creates user authorizer' do
#     subject.authorize
#     expect(Google::Auth::UserAuthorizer).to have_received(:new).with(client_id, Appydave::Tools::YouTubeManager::Authorization::SCOPE, token_store)
#   end

#   it 'returns credentials if they exist' do
#     allow(authorizer).to receive(:get_credentials).and_return(credentials)
#     expect(subject.authorize).to eq(credentials)
#   end

#   it 'calls wait_for_authorization when credentials are nil' do
#     allow(authorizer).to receive(:get_credentials).and_return(nil)
#     expect(subject).to receive(:wait_for_authorization).with(authorizer)
#     subject.authorize
#   end
# end
