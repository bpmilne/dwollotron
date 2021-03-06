require 'spec_helper_lite'
require 'account_state_machine'
require 'state_machine'

class AccountStateMachineStub
  include AccountStateMachine
  attr_accessor :state
  
  def create_new_payment(args=nil); end;
  def update_account_record(args=nil); end
  def cancel_current_payment(args=nil); end
  def reset_from_cancel(args=nil); end
  def enqueue_payment(args=nil); end
end

describe AccountStateMachine do
  subject { AccountStateMachineStub.new }

  describe 'payment_completed state' do
    before do
      subject.state = "payment_completed"
    end
    
    it 'can finalize and go to waiting state' do
      subject.finalize_records.should == true
      subject.should be_waiting
    end
  end
  
  
  describe 'error state' do
    before do
      subject.state = "error"
    end
    
    it 'can recover_from_error' do
      subject.should_receive(:reset_payments_after_error)
      subject.recover_from_error.should == true
      subject.should be_waiting
    end
  end
  
  
  describe 'queued state' do
    before do
      subject.state = "queued"
    end
    
    it 'can complete payment' do
      subject.should_receive(:update_account_record)
      subject.complete_payment.should == true
      subject.should be_payment_completed
    end
    
    it "can go to the error state" do
      subject.handle_error.should == true
      subject.should be_error
    end
  end
  
  describe 'waiting state' do
    it 'should be waiting by default' do
      subject.should be_waiting
    end
    
    it 'can queue' do
      subject.should_receive(:create_new_payment)
      subject.should_receive(:enqueue_payment)
      subject.queue.should == true
      subject.should be_queued
    end
    
  end
end