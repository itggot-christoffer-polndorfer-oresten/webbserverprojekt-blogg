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
        db = SQLite3::Database.new("db/blogg_db.db")
        db.results_as_hash = true
        profile_info = db.execute("SELECT * FROM users WHERE UserId = ?", session[:id])
        slim(:your_profile, locals:{profile_info: profile_info})
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
    #VARNIG DIREKT PLAGIAT FRÅN EMIL LINDBLAD 
        imgname = params[:img][:filename]
        img = params[:img][:tempfile]
        if imgname.include?(".png") or imgname.include?(".jpg")
            newname = SecureRandom.hex(10) + "." + /(.*)\.(jpg|bmp|png|jpeg)$/.match(imgname)[2]
            File.open("public/img/#{newname}", 'wb') do |f|
                f.write(img.read)
            end
        end 
    db.execute("INSERT INTO posts (PostText, img_path) VALUES (?,?)", params["post"], newname)
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
        post_info = db.execute("SELECT * FROM posts WHERE PostId = ?", params["postid"])
        
        slim(:edit_post, locals:{post_info: post_info})
    else
        redirect('/')
    end 
end 

post('/updating_profile') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    db.execute("UPDATE users SET Username = ?, Email = ?, Phone = ? WHERE UserId = ?", params["name"], params["email"], params["tel"], session[:id])
    session[:name] = params["name"]
    redirect("/")
end 

post('/updating/:postid') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    db.execute("UPDATE posts SET PostText = ? WHERE PostId = ?", params["edit_post"], params["postid"])
    redirect('/')
end 
 

post('/deleting_post/:postid') do 
    db = SQLite3::Database.new("db/blogg_db.db")
    db.results_as_hash = true
    db.execute("DELETE FROM posts WHERE PostId = ?", params["postid"])
    redirect('/')
end