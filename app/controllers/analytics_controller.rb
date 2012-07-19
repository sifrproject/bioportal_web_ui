class AnalyticsController < ApplicationController
  def track
    entry = Analytics.new
    entry.segment = params[:segment]
    entry.action = params[:analytics_action]
    entry.slice = @subdomain_filter[:active] ? @subdomain_filter[:acronym] : nil
    entry.ip = request.remote_ip
    entry.user = session[:user].nil? ? nil : session[:user].id
    entry.params = params.except(:segment, :analytics_action, :action, :controller)
    entry.save
    render :text => ""
  end
end
