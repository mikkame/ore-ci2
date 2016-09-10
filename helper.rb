require 'net/https'
require 'fileutils'
require 'systemu'
require 'shellwords'
require 'octokit'

class Helper
  def self.diff(before, after)
    out = ''
    command = 'cd ' + __dir__ + '/workdir; git diff --name-only ' + (before.shellescape) + ' ' + (after.shellescape)+ ''
    systemu command, :out => out
    out.split(/\n/)
  end

  def self.blame(filename, row_number)
    out = ''
    command = 'cd ' + __dir__ + '/workdir; git blame --abbrev=100 ' + (filename.shellescape)
    systemu command, :out => out
    return out.split(/\n/)[row_number.to_i-1].match(/(.+?) /).to_a[1]
  end

  def self.test(repo, before, after)
    command = 'cd ' + __dir__ + ';git clone git@github.com:' + repo + '.git workdir'
    systemu command
    self.diff(before, after).each do |file_name|
      return self.rubocop(repo, file_name)
    end
    FileUtils.rm_rf(__dir__+'/workdir/')
    Dir.mkdir(__dir__+'/workdir/')
  end

  def self.rubocop(repo, file_name)
    out = ''
    command = 'cd ' + __dir__ + '/workdir; rubocop  ' + (file_name.shellescape)
    systemu command, :out => out
    out.split(/\n/).each_with_index do |row, index|
      if index < 5
        next
      end
        path, position, col, level, message = row.match(/.+?:(\d):(\d): (.): (.+)/).to_a
        sha = self.blame(file_name, position)
        self.comment(repo, sha, message, position, path)
    end
  end

  def self.comment(repo, sha, message, position, path)
    client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
    client.create_commit_comment(repo, sha, message, path, position)

  end
end
