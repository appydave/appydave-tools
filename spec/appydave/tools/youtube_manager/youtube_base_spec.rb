# frozen_string_literal: true

# # frozen_string_literal: true

# RSpec.describe Appydave::Tools::YouTubeManager::YouTubeBase do
#   subject { instance }

#   let(:instance) { described_class.new }
#   let(:mock_service) { instance_double(Google::Apis::YoutubeV3::YouTubeService) }
#   let(:mock_authorization) { instance_double(Google::Auth::UserRefreshCredentials) }
#   let(:mock_client_options) { double('client_options') }

#   before do
#     allow(Google::Apis::YoutubeV3::YouTubeService).to receive(:new).and_return(mock_service)
#     allow(mock_service).to receive(:client_options).and_return(mock_client_options)
#     allow(mock_client_options).to receive(:application_name=)
#     allow(Appydave::Tools::YouTubeManager::Authorization).to receive(:authorize).and_return(mock_authorization)
#     allow(mock_service).to receive(:authorization=).with(mock_authorization)
#   end

#   it 'creates a new YouTubeService' do
#     subject
#     expect(Google::Apis::YoutubeV3::YouTubeService).to have_received(:new)
#   end

#   it 'sets the application name' do
#     subject
#     expect(mock_client_options).to have_received(:application_name=).with('YouTube Video Manager')
#   end

#   it 'authorizes the service' do
#     subject
#     expect(mock_service).to have_received(:authorization=).with(mock_authorization)
#   end
# end
