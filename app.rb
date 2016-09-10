require 'sinatra'
require 'sinatra/reloader'
require './helper.rb'

get '/' do
   key = deployKey
  'deploy key '+ key
end

post '/push' do
  repo = params[:repository][:full_name]
  before = params[:before]
  after = params[:after]
  Helper.test(repo, before, after)
  render text: 'done'
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
