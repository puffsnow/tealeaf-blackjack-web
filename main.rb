require 'rubygems'
require 'sinatra'
#require 'sinatra/reloader'

set :sessions, true

get '/' do
  redirect to('new_game')
end

get '/new_game' do
  clear_session_data()
  @info = "Welcome! Player! Please type your name to start a new game!"
  erb :new_game
end

post '/new_game' do
  if params[:username] == nil || params[:username] == ""
    @error = "Please type in your name."
    return erb :new_game
  end
  
  session[:username] = params[:username]
  session[:chips] = 500
  redirect to('/bet')
end

get '/bet' do
  redirect to('/new_game') until user_is_valid?
  session[:bet] = 0
  if session[:round] == 0
    @info = "Welcome! " + session[:username] + "! Let's start the game. You have $" + session[:chips].to_s + " in the beginning. Please type your bet in this round."
  elsif session[:chips] == 0
    @error = "Oops, you have lose all chips. Please start a new game."
  else
    @info = session[:username] + ", you have $" + session[:chips].to_s + " now. How much you want to bet in next round?"
  end
  erb :bet
end

post '/bet' do
  bet = params[:bet].to_i
  if bet <= 0 || bet > session[:chips]
    @error = "Please type in your bet and it should be the amount you can afford."
    return erb :bet
  end

  session[:bet] = bet
  session[:chips] = session[:chips] - bet
  session[:round] += 1
  initial_round()
  redirect to('/game')
end

get '/game' do
  player_score = calculate_score(session[:player_card])
  if player_score > 21
    @error = "Sorry, you busted."
    @show_command_type = 'result'
  elsif player_score == 21
    @success = "Congratulation! You Blackjack!"
    @show_command_type = 'result'
  else
    @info = session[:username] + ", your current score is " + player_score.to_s + ". It's your turn, you can hit to pick one more cards or stay to wait for dealer's turn."
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_card] << session[:deck].pop
  player_score = calculate_score(session[:player_card])
  if player_score > 21
    @error = "Sorry, you busted."
    @show_command_type = 'result'
  elsif player_score == 21
    @success = "Congratulation! You Blackjack!"
    @show_command_type = 'result'
  else
    @info = session[:username] + ", you pick a card and your current score is " + player_score.to_s + ". What's your next step?"
  end
  erb :game
end

post '/game/player/stay' do
  dealer_score = calculate_score(session[:dealer_card])
  if dealer_score > 21
    @success = "Oh! Dealer busted!"
    @show_command_type = 'result'
  elsif dealer_score == 21
    @error = "NO! Dealer gets BLACKJACK!"
    @show_command_type = 'result'
  elsif dealer_score >= 17
    @success = "Dealer is end his turn."
    @show_command_type = 'result'
  else
    @info = "It's dealer's turn, please click button [Dealer's next step]."
    @show_command_type = 'dealer'
  end
  erb :game
end

post '/game/dealer/turn' do
  session[:dealer_card] << session[:deck].pop
  dealer_score = calculate_score(session[:dealer_card])
  if dealer_score > 21
    @success = "Oh! Dealer busted! :P"
    @show_command_type = 'result'
  elsif dealer_score == 21
    @error = "NO! Dealer gets BLACKJACK!"
    @show_command_type = 'result'
  elsif dealer_score >= 17
    @success = "Dealer is end his turn."
    @show_command_type = 'result'
  else
    @show_command_type = 'dealer'
    @info = "Dealer picks a card, please click button [Dealer's next step]."
  end
  erb :game
end

post '/game/result' do

  player_score = calculate_score(session[:player_card])
  dealer_score = calculate_score(session[:dealer_card])

  if player_score == 21
    result_message = "You get BLACKJACK. "
    winner = "player"
  elsif player_score > 21
    result_message = "You Busted. "
    winner = "dealer"
  elsif dealer_score == 21
    result_message = "Dealer get BLACKJACK. "
    winner = "dealer"
  elsif dealer_score > 21
    result_message = "Dealer busted."
    winner = "player"
  elsif player_score > dealer_score
    result_message = "Your score is " + player_score.to_s + ", and dealer's score is " + dealer_score.to_s + ". "
    winner = "player"
  elsif player_score < dealer_score
    result_message = "Your score is " + player_score.to_s + ", and dealer's score is " + dealer_score.to_s + ". "
    winner = "dealer"
  else
    result_message = "Your score is " + player_score.to_s + ", and dealer's score is " + dealer_score.to_s + ". "
    winner = "draw"
  end

  if winner == 'player'
    session[:chips] += 2 * session[:bet]
    @success = result_message + "You win the game and the bet in this round!"
  elsif winner == 'dealer'
    @error = result_message + "Sorry, you lose the game and your bet."
  else
    session[:chips] += session[:bet]
    @info = result_message + "This game is draw, you can take your bet back."
  end
    
  erb :result
end

post '/new_round' do
  redirect to('/bet')
end

post '/end' do
  redirect to('/new_game')
end

before do
  @show_command_type = 'player'
end

helpers do

  def initial_round
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

  def clear_session_data
    session[:username] = nil
    session[:chips] = nil
    session[:round] = 0
  end

  def user_is_valid? 
    return false if session[:username] == nil || session[:username] == ""
    return false if session[:chips] < 0
    return true
  end

  def calculate_score(cards)
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

  def card_to_image_file_src(card)
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