# frozen_string_literal: true

RSpec.describe 'gpt_context CLI help' do
  let(:script) { File.expand_path('../../../../bin/gpt_context.rb', __dir__) }

  describe '--help' do
    subject(:output) { `ruby #{script} --help 2>&1` }

    it 'includes SYNOPSIS section' do
      expect(output).to include('SYNOPSIS')
    end

    it 'includes EXAMPLES section' do
      expect(output).to include('EXAMPLES')
    end

    it 'includes OUTPUT FORMATS section' do
      expect(output).to include('OUTPUT FORMATS')
    end
  end

  describe '--version' do
    it 'shows version number' do
      output = `ruby #{script} --version 2>&1`
      expect(output).to match(/gpt_context version \d+\.\d+\.\d+/)
    end
  end

  describe 'no arguments' do
    it 'prints an error message when no patterns provided' do
      output = `ruby #{script} 2>&1`
      expect(output).to include('No options provided')
      expect($CHILD_STATUS.exitstatus).to eq(0)
    end
  end
end
