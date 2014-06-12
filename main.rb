require 'rubygems'
require 'sinatra'
require "sinatra/reloader"

set :sessions, true

get '/inline' do
  "Hello World!!!"
end

get '/template' do
  erb :template
end

get '/nested_template' do
  erb :"/users/profile"
end

get '/form' do 
  erb :form
end