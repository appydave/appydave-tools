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

    it 'does not produce file content output when no patterns provided' do
      output = `ruby #{script} 2>&1`
      expect(output).not_to include('# file:')
      expect(output).not_to include('No output target provided')
    end
  end

  describe '-i include pattern' do
    it 'collects files matching the include pattern' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# test content')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -b #{tmpdir} -o #{outfile} 2>&1`

        expect(File.read(outfile)).to include('# file: test.rb')
        expect(File.read(outfile)).to include('# test content')
      end
    end

    it 'does not include files that do not match the pattern' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# ruby file')
        File.write(File.join(tmpdir, 'readme.md'), '# markdown file')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -b #{tmpdir} -o #{outfile} 2>&1`

        content = File.read(outfile)
        expect(content).to include('# file: test.rb')
        expect(content).not_to include('readme.md')
        expect(content).to include('# ruby file')
        expect(content).not_to include('# markdown file')
      end
    end
  end

  describe '-e exclude pattern' do
    it 'excludes files matching the exclude pattern' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'keep.rb'), '# keep')
        File.write(File.join(tmpdir, 'exclude.rb'), '# exclude')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -e 'exclude.rb' -b #{tmpdir} -o #{outfile} 2>&1`

        content = File.read(outfile)
        expect(content).to include('# file: keep.rb')
        expect(content).not_to include('# file: exclude.rb')
        expect(content).to include('# keep')
        expect(content).not_to include('# exclude')
      end
    end

    it 'keeps all files when exclude pattern matches nothing' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'keep.rb'), '# keep')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -e 'nomatch.rb' -b #{tmpdir} -o #{outfile} 2>&1`

        expect(File.read(outfile)).to include('# file: keep.rb')
        expect(File.read(outfile)).to include('# keep')
      end
    end
  end

  describe '-f format' do
    it 'outputs tree format when -f tree specified' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# test')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -f tree -b #{tmpdir} -o #{outfile} 2>&1`

        expect(File.read(outfile)).to include('test.rb')
      end
    end

    it 'outputs content format with file headers when -f content specified' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# test content')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -f content -b #{tmpdir} -o #{outfile} 2>&1`

        expect(File.read(outfile)).to include('# file: test.rb')
      end
    end

    it 'outputs both tree and content when -f tree,content specified' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# test content')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -f tree,content -b #{tmpdir} -o #{outfile} 2>&1`

        content = File.read(outfile)
        expect(content).to include('test.rb')
        expect(content).to include('# file: test.rb')
      end
    end

    it 'outputs valid JSON when -f json specified' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'test.rb'), '# test content')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -f json -b #{tmpdir} -o #{outfile} 2>&1`

        content = File.read(outfile)
        expect { JSON.parse(content) }.not_to raise_error
        parsed = JSON.parse(content)
        expect(parsed).to have_key('tree')
        expect(parsed).to have_key('content')
      end
    end
  end

  describe '-o output target' do
    it 'writes output to a file when -o specifies a filename' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'source.rb'), '# source content')
        outfile = File.join(tmpdir, 'output.txt')

        `ruby #{script} -i '*.rb' -b #{tmpdir} -o #{outfile} 2>&1`

        expect(File.exist?(outfile)).to be true
        expect(File.read(outfile)).to include('# file: source.rb')
      end
    end

    it 'creates the output file with content from included files' do
      Dir.mktmpdir do |tmpdir|
        File.write(File.join(tmpdir, 'hello.rb'), 'puts "hello"')
        outfile = File.join(tmpdir, 'context.txt')

        `ruby #{script} -i '*.rb' -f content -b #{tmpdir} -o #{outfile} 2>&1`

        content = File.read(outfile)
        expect(content).to include('hello.rb')
        expect(content).to include('puts "hello"')
      end
    end
  end
end
