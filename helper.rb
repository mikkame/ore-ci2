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
    out = ''
    command = 'cd ' + __dir__ + '/workdir;git log --pretty=oneline --abbrev-commit --abbrev=100'
    systemu command, :out => out
    hashs = [];
    current_push = false
    out.split(/\n/).each do |row|
      hash = row.split(' ')[0]
      if hash == after then
        current_push = true;
      end
      if current_push then
        hashs << hash
      end
      if hash == before then
        current_push = false;
      end
    end

    self.diff(before, after).each do |file_name|
      start = self.diffstart(before, after,file_name)
      self.rubocop(repo, file_name, hashs, start)
    end
    FileUtils.rm_rf(__dir__+'/workdir/')
    Dir.mkdir(__dir__+'/workdir/')
  end
  def self.diffstart(before ,after ,file)
    out = ''
    command = 'cd ' + __dir__ + '/workdir; git --no-pager diff -U10000 ' + (before.shellescape) + ' ' + (after.shellescape)+ ' ' + file.shellescape
    systemu command, :out => out
    out.split(/\n/).each_with_index do |row, index|
      if index < 5 then
        next
      end
      if row[0] == '-' || row[0] == '+' then
        puts row[0]
        return index-6
      end
    end
    return
  end
  def self.rubocop(repo, file_name, hashs, start)
    p '#'+file_name+'#'
    out = ''
    command = 'cd ' + __dir__ + '/workdir; rubocop  ' + (file_name.shellescape)
    systemu command, :out => out
    out.split(/\n/).each_with_index do |row, index|
      if index < 5
        next
      end
      if index % 3 != 2
        next
      end

      matched, path, position, col, level, message = row.match(/(.+?):(\d+):(\d+): (.): (.+)/).to_a
      if position.nil?
        next
      end

      sha = self.blame(file_name, position)
      if hashs.include? sha
        position = position.to_i - start.to_i
        p '----'
        p position
        self.comment(repo, sha, message, position, path)
      end
    end
  end

  def self.comment(repo, sha, message, position, path)
    client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
    p client.create_commit_comment(repo, sha, message, path, position,position)

  end
end
