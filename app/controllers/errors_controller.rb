class ErrorsController < ApplicationController

  layout 'ontology'

  def show
  	# Use this variable in the views to access detailed error information.
    @exception = env["action_dispatch.exception"]
    
    status_code = request.path[1..-1]
    render action: status_code
  end  
end
