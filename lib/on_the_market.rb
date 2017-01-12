require_relative "pull_down"
require 'uri'


class Pull_Down

  class On_The_Market < Pull_Down
    include Common
    # puts self.methods.sort
    set_mpc_tag "//div[contains(@id,'results')]//div[contains(@class,'page-nav')]//ul[contains(@class,'pagination-tabs')]//li"

    set_listing_tag "//li[contains(@class,'result') and contains(@class,'panel') and contains(@class,'agent-result')]"
    set_sub_page_tag "//h3[contains(@class,'agent-name')]//a"
    set_type_tag "//div[contains(@class,'agent-links')]",{after: :set_type}

    set_name_tag "//h3[contains(@class,'agent-name')]"
    set_website_tag "//div[contains(@class,'panel')]//div[contains(@class,'single-link')]//a[contains(@id,'agents-website')]", {attr: [:attr, "href"], after: :extract_url}
    set_location_tag "//p[contains(@class,'address')]//a", {after: :transform_address}


    set_uri_template "www.onthemarket.com","/agents/%s/?agent-search-type=branches&page=%s"
    set_zoop_tag "//div[contains(@id,'content')]//div[contains(@class,'agents-results-branch') and contains(@class,'clearfix')]", {
          before: :pull_zoop, after: :set_zoop,
          attr: :to_html,
          x_path_fail: false
        }

    after_pull do |field_data|
      field_data[:otm] = true
      field_data
    end

    def transform_address(string,_)
      @parts ||= [:road,:city,:post_code]
      string.split("\n").each_with_index.inject({}) do |address,(part,index)|
        address[@parts[index]] = part
        address
      end
    end


    def extract_url(url,_)
      url[ @urlrgx ||= /\?redirect-url=(.*)/]
      URI.unescape($1)
    end

  end
end
