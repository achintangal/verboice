class ApiController < ApplicationController
  before_filter :authenticate_account!

  def call
    call_log = current_account.call params
    render :json => {:call_id => call_log.id, :state => call_log.state}
  end
end