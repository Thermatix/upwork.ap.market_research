require_relative 'pull_down'


class Pull_Down
    class Zoopla < Pull_Down
      include Common
      set_mpc_tag "//div[contains(@id,'content')]//div[contains(@class,'paginate') and contains(@class,'bg-muted')]//a"
      set_listing_tag "//div[contains(@id,'content')]//div[contains(@class,'agents-results-branch') and contains(@class,'clearfix')]"
      set_sub_page_tag "//h2[contains(@itemprop,'name')]//a"
      set_type_tag "//table[contains(@class,'property-type-table') and contains(@class, 'agent-stats')]",{after: :set_type}

      set_name_tag "//h2[contains(@itemprop,'name')]"
      set_website_tag "//div[contains(@id,'sidebar')]//div[contains(@class,'sidebar') and contains(@class, 'sbt')]/h5//a", {attr: [:attr, "href"]}
      set_location_tag "//span[contains(@itemprop,'streetAddress')]", {after: :transform_address}

      set_uri_template "http://www.zoopla.co.uk","/find-agents/%s/?radius=0&pn=%s"

      set_otm_tag "//li[contains(@class,'result') and contains(@class,'panel') and contains(@class,'agent-result')]",         {
        before: :pull_otm, after: :set_otm,
        attr: :to_html,
        x_path_fail: false
      }

      after_pull do |field_data|
        field_data["zoop"] = true
        field_data
      end

      # set_arla_tag "//div[contains(@class, 'resultsarea')]//a[contains(@class,'resulttitle')]", {
        # before: :search_arla,
      #   after: :confirm_arla
      # }
      # set_otm_tag "", {before: :pull_otm, after: :set_otm}
      # set_rm_tag "", {before: :pull_otm, after: :set_otm}
      # set_zoop_tag "", {before: :pull_otm, after: :set_otm}


      def search_arla(item,field_data)
        set_uri "http://www.arla.co.uk/find-agent/"
        set_payload(query_params({
          "ctl00$ctl00$body$umbBodyContent$BranchSearch_1$txtLocation" => field_data["location"][:post_code],
          "ctl00$ctl00$body$umbBodyContent$BranchSearch_1$ddlRadius" => 5,
          "ctl00$ctl00$body$umbBodyContent$BranchSearch_1$txtName" => field_data["name"],
          "ctl00$ctl00$body$umbBodyContent$BranchSearch_1$btnSearch" => "Search"
        }))
        post
        if status_code == 200
          doc = to_doc(body)
          puts body
          puts doc.xpath(".//div[contains(@class, 'resultsarea')]//a[contains(@class,'resulttitle')]").inspect
          doc
        else
          puts body
          item
        end

      end


      def transform_address(string,field_data)
        address = string.delete("\n").split(',')
        {
          road: address[0].strip,
          city: address[2] ? address[2].strip : "",
          post_code: address.last.split('-').first.strip
        }
      end



    end
end
