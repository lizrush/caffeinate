require 'algorithmia'
require 'geocoder'
require 'yaml'
require 'yelp'

class Caffeinate

  def initialize(config_file)
    secrets = YAML.load_file(config_file)
    auth_algorithmia_client(secrets)
    @yelp = create_yelp_client(secrets)
    @current_location = nil
  end

  def and_go!
    find_nearest_coffee
    geocode
    calculate_distances
    sort_by_distance
    print_results
  end

  private

  def auth_algorithmia_client(config_hash)
    Algorithmia.api_key = config_hash['ALGORITHMIA_KEY']
  end

  def calculate_distances
    @coffeeshops.each do |shop|
      # https://algorithmia.com/algorithms/Geo/LatLongDistance
      query = Algorithmia.call('/Geo/LatLongDistance',
                                [ @current_location[0],
                                  @current_location[1],
                                  shop[:lat_long][0],
                                  shop[:lat_long][1],
                                  "mile"])

      shop[:distance] = query.result
    end
  end

  def create_yelp_client(config_hash)
    Yelp::Client.new({
      consumer_key: config_hash['CONSUMER_KEY'],
      consumer_secret: config_hash['CONSUMER_SECRET'],
      token: config_hash['TOKEN'],
      token_secret: config_hash['TOKEN_SECRET']
    })
  end

  def find_nearest_coffee
    get_current_location
    response = @yelp.search(@address, { term: 'coffee' })
    @coffeeshops = [
      { name: response.businesses[0].name,
        address: response.businesses[0].location.display_address.join(' '),
        lat_long: nil,
        distance: nil
      },

      { name: response.businesses[1].name,
        address: response.businesses[1].location.display_address.join(' '),
        lat_long: nil,
        distance: nil
      },

      { name: response.businesses[2].name,
        address: response.businesses[2].location.display_address.join(' '),
        lat_long: nil,
        distance: nil
      },
    ]
  end

  def get_current_location
    puts "Enter your address:"
    @address = $stdin.gets.chomp
    location = Geocoder.search(@address)
    @current_location = [location[0].latitude, location[0].longitude]
  end

  def geocode
    @coffeeshops.each do |shop|
      location = Geocoder.search(shop[:address])
      shop[:lat_long] = [location[0].latitude, location[0].longitude]
    end
  end

  def sort_by_distance
    @coffeeshops.sort_by! { |k| k[:distance] }
  end

  def print_results
    puts "The closest three coffeeshops to you are:"

    @coffeeshops.each do |shop|
      puts shop[:name]
      puts "Approximately #{shop[:distance]} miles away."
    end

    puts "Go get caffeinated!"
  end
end

