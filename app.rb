require 'sinatra'
require 'sinatra/reloader'
require './helper.rb'
require 'json'

get '/' do
  key = deployKey
  'deploy key '+ key
end

get '/test' do
  command = 'cd ' + __dir__ + '/workdir; git status'
  systemu command, :out => out
  out
end

post '/push' do
  payload = JSON.parse(request.body.read)
  repo = payload['repository']['full_name']
  before = payload['before']
  after = payload['after']
  Helper.test(repo, before, after)
  'done'
end


def deployKey
  if File.exist?(ENV["HOME"]+'/.ssh/id_rsa.pub') then
    return File.read(ENV["HOME"]+'/.ssh/id_rsa.pub')
  else
    begin
      system('ssh-keygen -b 2048 -t rsa -f '+ENV["HOME"]+'/.ssh/id_rsa'+' -q -N ""')
    rescue
    end
    return File.read(ENV["HOME"]+'/.ssh/id_rsa.pub')
  end
end
