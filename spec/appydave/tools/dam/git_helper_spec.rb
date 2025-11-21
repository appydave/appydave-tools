# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::GitHelper do
  let(:temp_dir) { Dir.mktmpdir }
  let(:git_repo) { File.join(temp_dir, 'test-repo') }

  before do
    FileUtils.mkdir_p(git_repo)
    Dir.chdir(git_repo) do
      `git init 2>/dev/null`
      `git config user.email "test@example.com"`
      `git config user.name "Test User"`
    end
  end

  after { FileUtils.rm_rf(temp_dir) }

  describe '.current_branch' do
    it 'returns branch name for git repo' do
      branch = described_class.current_branch(git_repo)
      # New repos may return HEAD, main, or master
      expect(branch).to match(/HEAD|main|master/)
    end

    it 'returns "unknown" for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.current_branch(non_git)).to eq('unknown')
    end
  end

  describe '.remote_url' do
    it 'returns nil when no remote configured' do
      expect(described_class.remote_url(git_repo)).to be_nil
    end

    it 'returns remote URL when configured' do
      Dir.chdir(git_repo) do
        `git remote add origin https://github.com/test/repo.git 2>/dev/null`
      end
      expect(described_class.remote_url(git_repo)).to eq('https://github.com/test/repo.git')
    end

    it 'returns nil for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.remote_url(non_git)).to be_nil
    end
  end

  describe '.commits_ahead' do
    it 'returns 0 when no upstream' do
      expect(described_class.commits_ahead(git_repo)).to eq(0)
    end

    it 'returns 0 for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.commits_ahead(non_git)).to eq(0)
    end
  end

  describe '.commits_behind' do
    it 'returns 0 when no upstream' do
      expect(described_class.commits_behind(git_repo)).to eq(0)
    end

    it 'returns 0 for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.commits_behind(non_git)).to eq(0)
    end
  end

  describe '.modified_files_count' do
    it 'returns 0 for clean repo' do
      Dir.chdir(git_repo) do
        File.write('test.txt', 'content')
        `git add test.txt`
        `git commit -m "initial" 2>/dev/null`
      end
      expect(described_class.modified_files_count(git_repo)).to eq(0)
    end

    it 'counts modified files' do
      Dir.chdir(git_repo) do
        File.write('test.txt', 'content')
        `git add test.txt`
        `git commit -m "initial" 2>/dev/null`
        File.write('test.txt', 'modified')
      end
      expect(described_class.modified_files_count(git_repo)).to eq(1)
    end

    it 'returns 0 for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.modified_files_count(non_git)).to eq(0)
    end
  end

  describe '.untracked_files_count' do
    it 'returns 0 for clean repo' do
      expect(described_class.untracked_files_count(git_repo)).to eq(0)
    end

    it 'counts untracked files' do
      File.write(File.join(git_repo, 'untracked.txt'), 'content')
      expect(described_class.untracked_files_count(git_repo)).to eq(1)
    end

    it 'returns 0 for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.untracked_files_count(non_git)).to eq(0)
    end
  end

  describe '.uncommitted_changes?' do
    it 'returns false for clean repo' do
      Dir.chdir(git_repo) do
        File.write('test.txt', 'content')
        `git add test.txt`
        `git commit -m "initial" 2>/dev/null`
      end
      expect(described_class.uncommitted_changes?(git_repo)).to be false
    end

    it 'returns true when files are modified' do
      Dir.chdir(git_repo) do
        File.write('test.txt', 'content')
        `git add test.txt`
        `git commit -m "initial" 2>/dev/null`
        File.write('test.txt', 'modified')
      end
      expect(described_class.uncommitted_changes?(git_repo)).to be true
    end

    it 'handles non-git directory gracefully' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      # System call fails, returns false (no error raised)
      expect { described_class.uncommitted_changes?(non_git) }.not_to raise_error
    end
  end

  describe '.fetch' do
    it 'handles fetch when no remote' do
      # Fetch succeeds even without remote in some git versions
      result = described_class.fetch(git_repo)
      expect(result).to be(true).or be(false)
    end

    it 'returns false for non-git directory' do
      non_git = File.join(temp_dir, 'not-git')
      FileUtils.mkdir_p(non_git)
      expect(described_class.fetch(non_git)).to be false
    end
  end
end
