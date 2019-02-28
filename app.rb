require'slim'
require'sqlite3'
require'sinatra'
require'byebug'
require'BCrypt'

enable :sessions

get('/') do #main sidan
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    post_text = db.execute("SELECT * FROM posts")
    slim(:index, locals:{post_text: post_text})
end

get('/create') do #skapa konto sidan
    session[:remove_login] = true
    slim(:create_acc)
end

post('/creating_acc') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    #Kryptera lösen
    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("INSERT INTO users(Username, Password, Email, Phone) VALUES(?, ?, ?, ?)", params["name"], hashed_password, params["email"], params["phone"])
    #Redirecta till första sidan
    session[:remove_login] = nil
    redirect('/')
end

post('/login') do
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    result = db.execute("SELECT Username, Password, UserId FROM users WHERE users.Username = ?", params["name"])
    if result.length > 0 && BCrypt::Password.new(result.first["Password"]) == params["password"]
        session[:name] = result[0]["Username"]
        session[:id] = result[0]["UserId"]
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
    if session[:loggedin?] == true 
        slim(:your_profile)
    else
        redirect('/')
    end 
end 

get('/post') do 
    if session[:loggedin?] == true 
        slim(:post)
    else
        redirect('/')
    end 
end 

post('/submit_post') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    db.execute("INSERT INTO posts (PostText) VALUES (?)", params["post"])
    redirect('/')
end 

post('/edit_post') do 
    post_id = params["PostId"]
    redirect("/edit_post/#{post_id}")
end 

get('/edit_post/:postid') do 
    if session[:loggedin?] == true 
        db = SQLite3::Database.new("db/blogg_db.db")
        db.results_as_hash = true
        post_info = db.execute("SELECT PostText FROM posts WHERE PostId = ?", params["PostId"])
        slim(:edit_post, locals:{post_info: post_info})
    else
        redirect('/')
    end 
end 

post('/updating') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    db.execute("UPDATE users SET Username = ?, Password = ?, Email = ?, Phone = ? WHERE UserId = ?", params["name"], params["password"], params["email"], params["phone"], session[:id])

    redirect('/')
end 
 

# post('/deleting_post') do 
#     db = SQLite3::Database.new("db/blogg_db.db")
#     db.results_as_hash = true
#     db.execute("DELETE FROM posts WHERE PostId = ?", params[""])

# end 