class HomeController < ApplicationController
  def index

  end

  def voice
    response = Twilio::TwiML::Response.new do |r|
      r.Say 'Stop wasting time! Welcome to Tro-tron!', :voice => 'man'
    end

    render :xml => response.text
  end

  def sms
    message_body = params["Body"]
    from_number = params["From"]

    new_event_keywords = ["N", "NE", "NEW", "", "+"] #TODO: Make this customizable via config file later
    end_event_keywords = ["CLOSE", "END", "DONE", "X", "C"]
    join_event_keywords = ["J", "JOIN"]
    stop_keywords = ["OPT-OUT"]

    original_message = message_body.strip
    tokenized_message = original_message.split
    keyword = (message_body.strip.upcase)[0]

    if new_event_keywords.include? keyword && tokenized_message.count == 1
      # Create a new event
      event = Event.new
      event.owner = from_number
      event.save

      PhoneNumber.send_sms_message_to_number("Your Code is: #{event.code}", from_number)

    elsif stop_keywords.include? keyword
      #Lazy way to do it, opt attendee out of everything
      Attendee.where(phone_number: from_number, status: 'ACTIVE').each do |a|
        a.status = 'INACTIVE';
        a.save
      end
      PhoneNumber.send_sms_message_to_number("Notifications turned off. Thank you.", from_number)

    elsif join_event_keywords.include? keyword
      if tokenized_message.size > 1
        event_code = tokenized_message[1]
        event = Event.where(status: 'ACTIVE', code: event_code).first   #TODO: should also take expiry into consideration

        if event.present?
          event.add_attendee(from_number)
          PhoneNumber.send_sms_message_to_number("You have been added. Thank you.", from_number)
        end
      end
      # Add attendee to event
    else
      event = Event.where(owner: from_number, status: 'ACTIVE').first
      if event.present?
        if end_event_keywords.include? keyword && tokenized_message.count == 1
          event.status = 'INACTIVE'
          event.save
          PhoneNumber.send_sms_message_to_number("Close successful. Thank you.", from_number)
        else
          event.attendees.each do |attendee|
            PhoneNumber.send_sms_message_to_number("Notification (Reply \"STOP\" to stop receiving): #{original_message}", attendee.phone_number)
          end
          PhoneNumber.send_sms_message_to_number("Notifications sent", from_number)
        end
      end
      # if num is from an event organizer with active event, forward message to everyone on event
    end

    render :text => "Done"

  end
end
