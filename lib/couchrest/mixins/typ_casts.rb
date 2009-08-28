['time', 'date', 'string', 'float', 'boolean'].each do |fname|
    require File.join(File.dirname(__FILE__), 'typ_casts', fname)
end

