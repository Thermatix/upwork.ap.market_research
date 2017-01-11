require_relative "pull_down"

class Pull_Down

  class Right_Move < Pull_Down
    set_mpc_tag "//div[contains(@class,'clearfix') and contains(@class, 'slidercontainer') ]//ul[contains(@class,'items')]"

    set_listing_tag "//li[contains(@class,'summarymaincontent') and contains(@class, 'summary-list-item')]"
    set_sub_page_tag "//h2[contains(@class,'branchname')]//a"
    set_type_tag "//div[contains(@class,'photos')]//div[contains(@class,'channels')]", {after: :set_type}

    set_name_tag "//h2[contains(@class,'branchname')]"
    set_website_tag ""
    set_location_tag "//div[contains(@id, 'branchdetails')]//p[contains(@class,'address')]"

    set_incriment 20
    set_uri_template "http://www.rightmove.co.uk","/estate-agents/%s-87490.html?index=%s"
    def set_type(string)
      res = {}
        if string =~ /sales/
      res[:sales] = true
        end
      if string =~ /lettings/
        res[:lettings] = true
      end
      res
    end


  end

end
