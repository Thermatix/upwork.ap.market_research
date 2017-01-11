class Pull_Down
  module Common

    def get_mpc(doc)
      doc[-2].inner_text.to_i
    end

    def set_type(string,field_data)
      res = {}
      if string =~ /sale/
        res[:sales] = true
      end
      if string =~ /rent/
        res[:lettings] = true
      end
      res
    end

    def self.included(into)
      into.instance_exec do
        set_otm_tag "//li[contains(@class,'result') and contains(@class,'panel') and contains(@class,'agent-result')]", {
          before: :pull_otm, after: :set_otm,
          attr: :to_html,
          x_path_fail: false
        }
        set_zoop_tag "//div[contains(@id,'content')]//div[contains(@class,'agents-results-branch') and contains(@class,'clearfix')]", {
          before: :pull_zoop, after: :set_zoop,
          attr: :to_html,
          x_path_fail: false
        }

        {
          pull_otm: "https://www.onthemarket.com/agents/%{pc}/?agent-name=%{cn}&agent-search-type=branches&view=list",
          pull_zoop: "http://www.zoopla.co.uk/find-agents/%{pc}/?company_name=%{cn}"
        }.each do |name,url_temp|
          define_method name do |item,field_data|
            a = url_temp % {
              pc: field_data["location"][:post_code].split(' ').first,
              cn: field_data["name"].gsub(" ","%20").split('-').first
            }
            set_uri a
            get
            if status_code == 200
              a = to_doc(body)
              # if name == :pull_otm
              # puts '=' * 100
              # puts a.css('body').to_html
              # puts '=' * 100
              # end
              a
            else
              item
            end
          end
        end

        {
          set_otm: "//h3[contains(@class,'agent-name')]",
          set_zoop: "//h2[contains(@itemprop,'name')]"
        }.each do |name,name_tag|
          define_method name do |string,field_data|
            searching = to_doc(string)
            searching.xpath(name_tag).detect(-> {false}) do |node|
              node.inner_text.to_s == field_data["name"]
            end ? true : false
          end
        end
      end
    end

  end

end
