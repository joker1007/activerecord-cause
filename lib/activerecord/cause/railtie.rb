module ActiveRecord
  module Cause
    class Railtie < ::Rails::Railtie
      initializer "activerecord-cause" do
        ActiveRecord::Cause.match_paths = [/#{Rails.root.join("app").to_s}/]
      end
    end
  end
end
