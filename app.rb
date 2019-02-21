require'slim'
require'sqlite3'
require'sinatra'
require 'byebug'
require 'BCrypt'
enable :sessions

get('/') do
    slim(:index)
end

get('/create') do
    slim(:create_acc)
end

post('/creating_acc') do
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    #Kryptera lösen
    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("INSERT INTO users(Username, Password) VAlUES(?, ?)", params["name"], hashed_password)
    #Redirecta till första sidan
    redirect('/')
end

post('/login') do
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true

    result = db.execute("SELECT Username, Password FROM users WHERE users.Username = ?", params["name"])

    if result.length > 0 && BCrypt::Password.new(result.first["Password"]) == params["password"]
        session[:name] = result[0]["Username"]
        session[:loggedin?] = true
        redirect('/')
    else
        redirect('/')
    end
end

post('/logout') do
    session.destroy
    redirect('/')
end 

get('/your_profile') do 
    slim(:your_profile)
end 
