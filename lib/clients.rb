module Kyuji
  module Clients
    @@clients = Hash.new

    Dir.glob('clients/*.yml') do |client_settings|
        client = YAML::load_file client_settings
        @@clients.merge! client
    end

    def self.[](key)
      @@clients[key]
    end

    def self.exists?(key)
      @@clients.key? key
    end
  end
end