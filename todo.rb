require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do 
	enable :sessions 
	set :session_secret, 'secret'
end 

before do 
	session[:lists] ||= []
end 

get "/" do 
	redirect "/lists"
end 

# View all the lists 
get "/lists" do
	@lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form 
get "/lists/new" do 

	erb :new_list, layout: :layout
end 

# Return an error message if the name is invalid
def error_for_todo(name)
	if !(1..100).cover? name.size
		"Todo must be between 1 and 100 characters."
	end 
end 

# REturn an error message if the name is invalid. Return nil if name is valid. 
def error_for_list_name(name)
	if !(1..100).cover? name.size
		"List name must be between 1 and 100 characters."
	end 
end 

# Create new list 
post "/lists" do
	list_name = params[:list_name].strip

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :new_list, layout: :layout
	else 
		session[:lists] << {name: list_name, todos: []}
		session[:success] = "The list has been created"
		redirect "/lists"
	end
end 
#view single todo list 
get "/lists/:id" do 
	@list_id = params[:id].to_i
	@list = session[:lists][@list_id]

	erb :list, layout: :layout 
end 

# edit the todo list 
get "/lists/:id/edit" do 
	id = params[:id].to_i
	@list = session[:lists][id]	
	
	erb :edit_list, layout: :layout 
end 

#update the todolist 
post "/lists/:id" do
	list_name = params[:list_name].strip
	id = params[:id].to_i
	@list = session[:lists][id]	

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :edit_list, layout: :layout
	else 
		@list[:name] = list_name 
		session[:success] = "The list has been updated"
		redirect "/lists/#{id}"
	end	
end 

# delete a todolist 

post "/lists/:id/destroy" do 

	id = params[:id].to_i 
	session[:lists].delete_at(id)
	session[:success] = "The list has been deleted"
	redirect "/lists"
end 

#add new todo
post "/lists/:list_id/todos" do 
	@list_id = params[:list_id].to_i 
	@list = session[:lists][@list_id]
	text = params[:todo].strip

	error = error_for_todo(text)
	if error 
		session[:error] = error 
		erb :list, layout: :layout
	else 
		@list[:todos] << {name: text, completed: false}
		session[:success] = "The todo has been created"
		redirect "/lists/#{@list_id}"
	end 
end 

#delete todo
post "/lists/:id/:index/destroy" do
	id = params[:id].to_i 
	todos = session[:lists][id][:todos]
	index = params[:index].to_i

	todos.delete_at(index)
	session[:success] = "The todo has been deleted"
	redirect "/lists/#{id}"
end 

