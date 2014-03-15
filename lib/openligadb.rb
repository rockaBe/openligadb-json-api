require 'savon'

class String
  def lower_camelcase
    str = dup
    str.gsub!(/\/(.?)/) { "::#{$1.upcase}" }
    str.gsub!(/(?:_+|-+)([a-z])/) { $1.upcase }
    str.gsub!(/(\A|\s)([A-Z])/) { $1 + $2.downcase }
    str
  end
end

class OpenLigaDB
  def initialize
    @client = Savon.client(
      wsdl: "http://www.openligadb.de/Webservices/Sportsdata.asmx?wsdl", log_level: :error
    )
  end

  # sends request to WSDL endpoint
  # @params
  # action:   wsdl operation name as underscored string
  # params:   params required for wsdl operation to work
  def request(action, params)
    action = "get_#{action}"
    
    message = params.each_with_object({}) do |(key, value), msg|
      key = key.lower_camelcase
      unless ["get_next_match_by_league_team", "get_last_match_by_league_team"].include?(action)
        key = key.gsub(/Id/, 'ID')
      end
      msg[key] = value
    end
    response = @client.call(action.to_sym, message: message)
    result = format_response(response, action)
  end

  private

  # @params
  # response: Savon::Response object
  # @returns
  # a cleaned Hash of data elements (including root_object, if available)
  def format_response(response, action)
    hash = response.body
    hash = hash[hash.keys.first]
    hash.delete :@xmlns
    # needed to always return a hash and not just the bare result
    # to make the method consistent
    unless ['get_current_group_order_id'].include? action
      result = hash[hash.keys.first] 
    else
      result = hash
    end
    result = {:last_change_date => result} if result.class == DateTime
    result
  end

end