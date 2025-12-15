# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Formatters::TableFormatter do
  subject(:formatter) { described_class.new(data, options) }

  let(:options) { { color: false } }

  describe '#format' do
    context 'when formatting error result' do
      let(:data) do
        {
          success: false,
          error: 'Location not found',
          suggestion: 'Did you mean: ad-tools?'
        }
      end

      it 'displays error message' do
        output = formatter.format

        expect(output).to include('Error: Location not found')
      end

      it 'displays suggestion when available' do
        output = formatter.format

        expect(output).to include('Did you mean: ad-tools?')
      end
    end

    context 'when formatting empty results' do
      let(:data) do
        {
          success: true,
          results: [],
          count: 0
        }
      end

      it 'displays no locations message' do
        output = formatter.format

        expect(output).to include('No locations found.')
      end
    end

    context 'when formatting info result' do
      let(:data) do
        {
          success: true,
          config_path: '/home/user/.config/appydave/locations.json',
          exists: true,
          version: '1.0',
          last_updated: '2025-12-10 14:30:00',
          last_validated: '2025-12-10 14:30:00',
          location_count: 5,
          brand_count: 2,
          client_count: 1
        }
      end

      it 'displays config metadata instead of "No locations found"' do
        output = formatter.format

        expect(output).to include('Config Path:')
        expect(output).to include('/home/user/.config/appydave/locations.json')
        expect(output).to include('Locations: 5')
        expect(output).not_to include('No locations found')
      end

      it 'displays header' do
        output = formatter.format

        expect(output).to include('Jump Location Tool - Configuration Info')
      end

      it 'displays config existence status' do
        output = formatter.format

        expect(output).to include('Config Exists:')
      end

      it 'displays version' do
        output = formatter.format

        expect(output).to include('Version:')
        expect(output).to include('1.0')
      end

      it 'displays statistics section' do
        output = formatter.format

        expect(output).to include('Statistics:')
        expect(output).to include('Locations: 5')
        expect(output).to include('Brands:    2')
        expect(output).to include('Clients:   1')
      end

      context 'when config does not exist' do
        let(:data) do
          {
            success: true,
            config_path: '/path/to/missing.json',
            exists: false,
            version: nil,
            location_count: 0,
            brand_count: 0,
            client_count: 0
          }
        end

        it 'shows N/A for version' do
          output = formatter.format

          expect(output).to include('N/A')
        end

        it 'shows zero counts' do
          output = formatter.format

          expect(output).to include('Locations: 0')
        end
      end
    end

    context 'when formatting single location result (from get command)' do
      let(:data) do
        {
          success: true,
          results: [
            {
              index: 1,
              key: 'ad-tools',
              jump: 'jad-tools',
              type: 'project',
              brand: 'appydave',
              description: 'AppyDave Tools CLI',
              score: 100
            }
          ],
          count: 1
        }
      end

      it 'displays the single location' do
        output = formatter.format

        expect(output).to include('ad-tools')
        expect(output).to include('jad-tools')
        expect(output).to include('Total: 1 location(s)')
      end

      it 'does not display "No locations found"' do
        output = formatter.format

        expect(output).not_to include('No locations found')
      end
    end

    context 'when formatting location results' do
      let(:data) do
        {
          success: true,
          results: [
            {
              index: 1,
              key: 'ad-tools',
              jump: 'jad-tools',
              type: 'project',
              brand: 'appydave',
              description: 'AppyDave Tools CLI',
              score: 100
            },
            {
              index: 2,
              key: 'flivideo',
              jump: 'jfli',
              type: 'product',
              brand: 'appydave',
              description: 'Video asset management',
              score: 85
            }
          ],
          count: 2
        }
      end

      it 'displays table header' do
        output = formatter.format

        expect(output).to include('#')
        expect(output).to include('KEY')
        expect(output).to include('JUMP')
        expect(output).to include('TYPE')
      end

      it 'displays location rows' do
        output = formatter.format

        expect(output).to include('ad-tools')
        expect(output).to include('jad-tools')
        expect(output).to include('flivideo')
        expect(output).to include('jfli')
      end

      it 'displays total count footer' do
        output = formatter.format

        expect(output).to include('Total: 2 location(s)')
      end
    end
  end
end
