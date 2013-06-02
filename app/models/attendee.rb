class Attendee < ActiveRecord::Base
   attr_accessible :name, :phone_number

  belongs_to :event

  before_create :set_defaults

  def set_defaults
    self.status = 'ACTIVE'
  end


end
