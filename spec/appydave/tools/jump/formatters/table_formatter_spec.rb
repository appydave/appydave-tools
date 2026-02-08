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

    context 'when formatting count reports with --limit flag' do
      context 'when formatting tags report' do
        let(:data) do
          {
            success: true,
            report: 'tags',
            count: 5,
            total_count: 50,
            limit: 20,
            truncated: true,
            results: [
              { tag: 'ruby', location_count: 15 },
              { tag: 'cli', location_count: 12 },
              { tag: 'tool', location_count: 10 },
              { tag: 'gem', location_count: 8 },
              { tag: 'youtube', location_count: 5 }
            ]
          }
        end

        it 'displays top N items' do
          output = formatter.format

          expect(output).to include('ruby')
          expect(output).to include('cli')
          expect(output).to include('tool')
        end

        it 'displays truncation message' do
          output = formatter.format

          expect(output).to include('Showing top 5 of 50 (45 more)')
        end

        it 'does not show regular total when truncated' do
          output = formatter.format

          expect(output).not_to include('Total: 5 tags')
        end
      end

      context 'when formatting types report' do
        let(:data) do
          {
            success: true,
            report: 'types',
            count: 3,
            total_count: 10,
            limit: 5,
            truncated: true,
            results: [
              { type: 'tool', location_count: 20 },
              { type: 'gem', location_count: 15 },
              { type: 'app', location_count: 10 }
            ]
          }
        end

        it 'displays top N types' do
          output = formatter.format

          expect(output).to include('tool')
          expect(output).to include('gem')
          expect(output).to include('app')
        end

        it 'displays truncation message' do
          output = formatter.format

          expect(output).to include('Showing top 3 of 10 (7 more)')
        end
      end

      context 'when not truncated' do
        let(:data) do
          {
            success: true,
            report: 'tags',
            count: 5,
            total_count: 5,
            results: [
              { tag: 'ruby', location_count: 15 },
              { tag: 'cli', location_count: 12 }
            ]
          }
        end

        it 'displays regular total' do
          output = formatter.format

          expect(output).to include('Total: 5 tags')
        end

        it 'does not show truncation message' do
          output = formatter.format

          expect(output).not_to include('more)')
        end
      end
    end

    context 'when formatting grouped reports with --limit flag' do
      context 'when formatting by-brand report' do
        let(:data) do
          {
            success: true,
            report: 'by-brand',
            limit: 5,
            skip_unassigned: false,
            groups: {
              'appydave' => {
                items: [
                  { key: 'ad-tools', jump: 'jad-tools', description: 'Tools CLI' },
                  { key: 'ad-brand', jump: 'jad-brand', description: 'Brand site' },
                  { key: 'flivideo', jump: 'jfli', description: 'Video app' },
                  { key: 'storyline', jump: 'jstory', description: 'Storyline app' },
                  { key: 'klueless', jump: 'jklue', description: 'Klueless DSL' }
                ],
                total: 26,
                truncated: true
              },
              'voz' => {
                items: [
                  { key: 'voz-app', jump: 'jvoz-app', description: 'VOZ main app' }
                ],
                total: 1,
                truncated: false
              }
            }
          }
        end

        it 'displays group headers with total count' do
          output = formatter.format

          expect(output).to include('APPYDAVE (26 locations)')
          expect(output).to include('VOZ (1 location)')
        end

        it 'displays limited items per group' do
          output = formatter.format

          expect(output).to include('ad-tools')
          expect(output).to include('flivideo')
          expect(output).to include('klueless')
        end

        it 'displays truncation message for truncated groups' do
          output = formatter.format

          expect(output).to include('... and 21 more')
        end

        it 'does not display truncation for non-truncated groups' do
          output = formatter.format

          lines = output.split("\n")
          voz_section = lines.drop_while { |line| !line.include?('VOZ') }.take(5)
          voz_text = voz_section.join("\n")

          expect(voz_text).not_to include('... and')
        end

        it 'displays total footer' do
          output = formatter.format

          expect(output).to include('Total: 27 location(s) in 2 group(s)')
        end
      end
    end

    context 'when formatting grouped reports with --skip-unassigned (default)' do
      context 'when formatting by-brand report' do
        let(:data) do
          {
            success: true,
            report: 'by-brand',
            skip_unassigned: true,
            groups: {
              'appydave' => [
                { key: 'ad-tools', jump: 'jad-tools', description: 'Tools CLI' },
                { key: 'flivideo', jump: 'jfli', description: 'Video app' }
              ],
              'voz' => [
                { key: 'voz-app', jump: 'jvoz-app', description: 'VOZ main app' }
              ]
            }
          }
        end

        it 'does not include unassigned group' do
          output = formatter.format

          expect(output).not_to include('UNASSIGNED')
        end

        it 'displays skip message in footer' do
          output = formatter.format

          expect(output).to include('(unassigned hidden)')
        end

        it 'displays other groups' do
          output = formatter.format

          expect(output).to include('APPYDAVE')
          expect(output).to include('VOZ')
        end
      end

      context 'when formatting by-client report' do
        let(:data) do
          {
            success: true,
            report: 'by-client',
            skip_unassigned: true,
            groups: {
              'supportsignal' => [
                { key: 'ss-app', jump: 'jss-app', description: 'SupportSignal app' }
              ]
            }
          }
        end

        it 'shows skip message in footer' do
          output = formatter.format

          expect(output).to include('(unassigned hidden)')
        end
      end
    end

    context 'when formatting grouped reports with --include-unassigned' do
      let(:data) do
        {
          success: true,
          report: 'by-brand',
          skip_unassigned: false,
          groups: {
            'appydave' => [
              { key: 'ad-tools', jump: 'jad-tools', description: 'Tools CLI' }
            ],
            'unassigned' => [
              { key: 'old-project', jump: 'jold', description: 'Old project' }
            ]
          }
        }
      end

      it 'includes unassigned group' do
        output = formatter.format

        expect(output).to include('UNASSIGNED')
        expect(output).to include('old-projec') # Truncated in table display
      end

      it 'does not show skip message in footer' do
        output = formatter.format

        expect(output).not_to include('(unassigned hidden)')
      end
    end

    context 'when formatting grouped reports with both --limit and --skip-unassigned' do
      let(:data) do
        {
          success: true,
          report: 'by-type',
          limit: 3,
          skip_unassigned: true,
          groups: {
            'tool' => {
              items: [
                { key: 'tool1', jump: 'jtool1', description: 'Tool 1' },
                { key: 'tool2', jump: 'jtool2', description: 'Tool 2' },
                { key: 'tool3', jump: 'jtool3', description: 'Tool 3' }
              ],
              total: 10,
              truncated: true
            }
          }
        }
      end

      it 'displays limited items with truncation message' do
        output = formatter.format

        expect(output).to include('tool1')
        expect(output).to include('tool3')
        expect(output).to include('... and 7 more')
      end

      it 'displays skip message in footer' do
        output = formatter.format

        expect(output).to include('(unassigned hidden)')
      end
    end

    context 'when formatting grouped reports with old array format (backward compatibility)' do
      let(:data) do
        {
          success: true,
          report: 'by-brand',
          skip_unassigned: false,
          groups: {
            'appydave' => [
              { key: 'ad-tools', jump: 'jad-tools', description: 'Tools CLI' },
              { key: 'flivideo', jump: 'jfli', description: 'Video app' }
            ]
          }
        }
      end

      it 'handles old array format correctly' do
        output = formatter.format

        expect(output).to include('APPYDAVE (2 locations)')
        expect(output).to include('ad-tools')
        expect(output).to include('flivideo')
      end

      it 'does not show truncation message' do
        output = formatter.format

        expect(output).not_to include('... and')
      end
    end
  end
end
