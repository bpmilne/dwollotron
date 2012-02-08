class Payment < ActiveRecord::Base
  include PaymentStateMachine
  
  belongs_to :account
  has_many :payment_events
  
  validates_presence_of :account_id, :started_at, :effective_at
  
  attr_accessor :raw_response, :remote_transaction_id, :error
  
  def log_state_change!(transition)
    payment_events.create!(:created_at => Time.now, 
                           :from_state => transition.from_name, 
                           :to_state => transition.to_name, 
                           :remote_transaction_id => remote_transaction_id, 
                           :raw_response => raw_response,
                           :error => error)
  end
  
end