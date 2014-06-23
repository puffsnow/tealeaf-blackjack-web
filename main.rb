require 'rubygems'
require 'sinatra'
require "sinatra/reloader"

set :sessions, true

get '/' do
  redirect to('NewGame')
end

get '/NewGame' do
  ClearSessionData()
  erb :NewGame
end

post '/NewGame' do
  if params[:username] == nil || params[:username] == ""
    @error = "Please type in your name."
    return erb :NewGame
  end
  
  session[:username] = params[:username]
  session[:chips] = 500
  redirect to('/Bet')
end

get '/Bet' do
  redirect to('/NewGame') until UserIsValid?
  session[:bet] = 0

  erb :Bet
end

post '/Bet' do
  bet = params[:bet].to_i
  if bet <= 0 || bet > session[:chips]
    @error = "Please type in your bet and it should be the amount you can afford."
    return erb :bet
  end

  session[:bet] = bet
  session[:chips] = session[:chips] - bet
  InitialRound()
  redirect to('/Game')
end

get '/Game' do
  player_score = CalculateScore(session[:player_card])
  if player_score > 21
    @error = "Sorry, you busted."
    @show_command_type = 'result'
    session[:winner] = 'dealer'
  elsif player_score == 21
    @success = "Congratulation! You Blackjack!"
    @show_command_type = 'result'
    session[:winner] = 'player'
  end
  erb :Game
end

post '/Game/Player/Hit' do
  session[:player_card] << session[:deck].pop
  player_score = CalculateScore(session[:player_card])
  if player_score > 21
    @error = "Sorry, you busted."
    @show_command_type = 'result'
    session[:winner] = 'dealer'
  elsif player_score == 21
    @success = "Congratulation! You Blackjack!"
    @show_command_type = 'result'
    session[:winner] = 'player'
  end
  erb :Game
end

post '/Game/Player/Stay' do
  @success = "OK, wait for dealer."
  @show_command_type = 'dealer'
  erb :Game
end

post '/Game/Dealer/Turn' do
  dealer_score = CalculateScore(session[:dealer_card])
  if dealer_score > 21
    @success = "Oh! Dealer busted!"
    @show_command_type = 'result'
    session[:winner] = 'player'
  elsif dealer_score == 21
    @error = "NO! Dealer BLACKJACK!"
    @show_command_type = 'result'
    session[:winner] = 'dealer'
  elsif dealer_score >= 17
    @success = "Dealer is end his turn:)"
    @show_command_type = 'result'
  else
    @show_command_type = 'dealer'
    session[:dealer_card] << session[:deck].pop
  end
  erb :Game
end

post '/Game/Result' do

  player_score = CalculateScore(session[:player_card])
  dealer_score = CalculateScore(session[:dealer_card])
  if session[:winner] == 'player'
    session[:chips] += 2 * session[:bet]
  elsif session[:winner] == 'dealer'
  elsif player_score > dealer_score
    session[:winner] = 'player'
    session[:chips] += 2 * session[:bet]
  elsif player_score == dealer_score
    session[:winner] = 'draw'
    session[:chips] += session[:bet]
  else
    session[:winner] = 'dealer'
  end

  if session[:winner] == 'player'
    @success = "Congratulation! You win $" + session[:bet].to_s + "!"
  elsif session[:winner] == 'dealer'
    @error = "Oh! No! You lose $" + session[:bet].to_s + "!"
  else
    @success = "Draw. You can take your bet back."
  end
    
  erb :Result
end

post '/NewRound' do
  redirect to('/Bet')
end

post '/End' do
  redirect to('/NewGame')
end

before do
  @show_command_type = 'player'
end

helpers do

  def InitialRound
    suits = ['C', 'D', 'H', 'S']
    values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
    session[:deck] = suits.product(values).shuffle!
    session[:dealer_card] = []
    session[:player_card] = []
    session[:dealer_card] << session[:deck].pop
    session[:dealer_card] << session[:deck].pop
    session[:player_card] << session[:deck].pop
    session[:player_card] << session[:deck].pop
    session[:winner] = nil
  end

  def ClearSessionData
    session[:username] = nil
    session[:chips] = nil
  end

  def UserIsValid? 
    return false if session[:username] == nil || session[:username] == ""
    return false if session[:chips] < 0
    return true
  end

  def CalculateScore(cards)
    point = 0
    cards.each do |card|
      value = card[1]
      if value.to_i > 0
        point += value.to_i
      elsif value == "A"
        point += 11
      else
        point += 10
      end
    end

    cards.select{|card| card[1] == "A"}.count.times do
      point -= 10 if point > 21
    end
    point
  end

  def CardToImageFileSrc(card)
    suit = card[0]
    value = card[1]

    suit_str = "clubs" if suit == "C"
    suit_str = "diamonds" if suit == "D"
    suit_str = "hearts" if suit == "H"
    suit_str = "spades" if suit == "S"

    value_str = "ace" if value == "A"
    value_str = value if value.to_i > 0
    value_str = "jack" if value == "J"
    value_str = "queen" if value == "Q"
    value_str = "king" if value == "K"

    "/images/cards/" + suit_str + "_" + value_str + ".jpg"
  end

end