class Payment < ActiveRecord::Base
  include PaymentStateMachine
  
  belongs_to :account
  has_many :payment_events
  
  validates_presence_of :account_id, :started_at, :effective_at
  
  attr_accessor :raw_response, :remote_transaction_id, :error
  
  def log_payment_event(transition)
    event = payment_events.create!(:created_at => Time.now, 
                           :from_state => transition.from_name, 
                           :to_state => transition.to_name, 
                           :remote_transaction_id => remote_transaction_id, 
                           :raw_response => raw_response,
                           :error => error)
    self.raw_response = nil
    self.remote_transaction_id = nil
    self.error = nil
    event
  end
  
  def has_existing_payments_in_the_same_effective_month?
    account.payments.where("effective_at >= ? and effective_at <= ? and state = ?", effective_at.getgm.beginning_of_month, effective_at.getgm.end_of_month, :completed).count > 0
  end
  
  def call_remote_dwolla_api(args=nil)
    raise InvalidStateError unless self.processing?
    
    return handle_duplicate! if has_existing_payments_in_the_same_effective_month?
    
    begin
      amount = account.scheduled_amount_at(effective_at).amount
      # call the dwolla api
      complete!
    rescue Exception => ex
      self.error = {:exception => ex.inspect, :trace => ex.backtrace}
      handle_error!
    end
  end
  
  def cancel_duplicate(args=nil)
    raise InvalidStateError unless self.duplicate?
    account.cancel_current_payment
  end 
  
  def complete_records(args=nil)
    raise InvalidStateError unless self.completed?
    update_attributes(:completed_at => Time.now)
    account.complete_payment!
  end
  
  def set_account_error(args=nil)
    raise InvalidStateError unless self.error?
    account.handle_error!
  end
  
  class InvalidStateError < StandardError
  end
  
end