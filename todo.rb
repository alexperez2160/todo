require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do 
	enable :sessions 
	set :session_secret, 'secret'
end 

configure do
  set :erb, :escape_html => true
end

before do 
	session[:lists] ||= []
end 

helpers do
	 def all_complete(list)
	 		if list[:todos].size == 0
	 			false 
	 		else
	 		list[:todos].select { |todo| todo[:completed] == true }.size == list[:todos].size 
	 		end 
	 end 

	 def count(list)
	 		list[:todos].select {|todo| todo[:completed] == true}.size
	 end 

	 def sort_lists(lists, &block)
	 		incomplete_lists = {}
	 		complete_lists = {}

	 		lists.each_with_index do |list, index|
	 			if all_complete(list)
	 				complete_lists[list] = index
	 			else
	 				incomplete_lists[list] = index
	 			end 
	 		end 
	 			incomplete_lists.each(&block)
	 			complete_lists.each(&block)	
	 end 

	 def sort_todos(todos, &block)
	 	incomplete_todos = {}
	 	complete_todos = {}

	 	todos.each_with_index do |todo, index| 
	 		if todo[:completed] == true 
	 			complete_todos[todo] = index
	 		else 
	 			incomplete_todos[todo] = index
	 		end 
	 	end 
	 	incomplete_todos.each(&block)
	 	complete_todos.each(&block)
	 end 
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
	if @list_id > session[:lists].size
		session[:success] = "The list does not exits"
		redirect "/lists"
	else 
	erb :list, layout: :layout 
	end 
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
	if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
		"/lists"
	else 
		session[:success] = "The list has been deleted"
		redirect "/lists"
	end 
end 

def next_todo_id(todos)
	max = todos.map{ |todo| todo[:id]}.max || 0
	max + 1 
end 

#add a new todo
post "/lists/:list_id/todos" do 
	@list_id = params[:list_id].to_i 
	@list = session[:lists][@list_id]
	text = params[:todo].strip

	error = error_for_todo(text)
	if error 
		session[:error] = error 
		erb :list, layout: :layout
	else 
		id = next_todo_id(@list[:todos]) # refine this later
		@list[:todos] << {id: id, name: text, completed: false}
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
	if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
		status 204
	else 
		session[:success] = "The todo has been deleted"
		redirect "/lists/#{id}"
	end 
end 

# mark completed todo
post "/lists/:id/todos/:index" do
	@list_id = params[:id].to_i
	@list = session[:lists][@list_id]
	index = params[:index].to_i
	is_completed = params[:completed] == "true"


	@list[:todos][index][:completed] = is_completed
	session[:success] = "The todo has been updated."
	redirect "/lists/#{@list_id}"


end 

# complete all todos
post "/lists/:id/complete_all" do 
	@list_id = params[:id].to_i
	@list = session[:lists][@list_id]

	@list[:todos].each do |todo| 
		todo[:completed] = true 
	end 
	session[:success] = "The todos have been all marked completed"
	redirect "/lists/#{@list_id}"

end 