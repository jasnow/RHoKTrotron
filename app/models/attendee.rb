class Attendee < ActiveRecord::Base
   attr_accessible :name, :phone_number, :event_id

  belongs_to :event

  before_create :set_defaults

  def set_defaults
    self.status = 'ACTIVE'
  end


end
