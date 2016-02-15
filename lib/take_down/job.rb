
module TakeDown
  class Job
    def initialize(hash)
      @hash = hash
      @hash.freeze
    end

    def method_missing(name, *args, &block)
      @hash.send(name, *args, &block)
    end
    
    def [](key)
      unless @hash.has_key?(key)
        if key.respond_to?(:to_sym) && @hash.has_key?(key.to_sym)
          key = key.to_sym
        elsif key.respond_to?(:to_s) && @hash.has_key?(key.to_s)
          key = key.to_s
        end
      end

      @hash[key]
    end
    
  end
end