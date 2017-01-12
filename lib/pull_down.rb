require_relative'curb_dsl'
require 'nokogiri'
require 'csv'
class Pull_Down

  Meta_Tags = %w{listing mpc sub_page}
  Fields = %w{type name website location manager otm rm zoop}
  include Curb_DSL

  def initialize(loc,&block)
    @location = loc
    @inc ||= 1
    @sub_uri = ""

    super(&block)
  end


    (Fields + Meta_Tags).each do |field|
      define_singleton_method "set_%s_tag" % field do |path,meta={}|
        @tag_info ||= {}
        @tag_info[field] = {
          path: path,
          meta: meta
        }
      end

      define_method "get_%s_tag" % field do
        self.class.instance_variable_get(:@tag_info)[field]
      end
    end


  def self.set_uri_template(base,queries)
    @uri_template = {
      base: base,
      queries: queries
    }
  end

  def make_uri(*args)
    @template ||= self.class.instance_variable_get(:@uri_template)
    if args.length >= 2
      ("%s%s" % @template.values) % args
    else
      "%s%s" % [@template[:base],args.first]
    end
  end

  def uri
    @uri ||= self.class.instance_variable_get(:@uri)
  end

  def self.set_incriment(value)
    @inc = value
  end

  def inc
    @inc ||= self.class.instance_variable_get(:@inc)
  end


  def pull_and_store
    doc = pull_initial
    @agent = []
    class_name = self.class.to_s.split('::').last
    CSV.open("%s_%s_agent_data.csv" % [class_name,@location],"wb") do |agent_csv|
      agent_csv << ["name", "sales", "lettings", "sales and lettings", "website", "On the Market", "Zoopla"]
      CSV.open("%s_%s_branch_data.csv" % [class_name,@location],"wb") do |branch_csv|
        branch_csv << ["Agency", "Road", "City", "Post Code"]
        pull_infomation_down(doc) do |listing,index|
          unless @agent.first == listing["name"].split('-').first
            @agent = set_agent(listing)
            agent_csv << @agent
          end
          branch_csv << set_branch(listing)
          yield if block_given?
        end
      end
    end
  end

  def pull_and_check
    puts make_uri(@location,0)
    doc = pull_initial
    # puts doc.methods.sort.each_slice(5) {|c| puts c.to_s}
    seperator = "}#{'-' * 40}{"
    puts seperator
    puts mpc(doc)
    puts seperator
    test_item = doc.xpath(get_listing_tag[:path]).first
    puts test_item.to_html
    puts seperator
    puts sub_page(test_item)
    puts seperator
    @agent = []
    sep = '%s%s%s' % [index,seperator,index]
    pull_infomation_down(doc) do |listing,index|
      unless @agent.first == listing["name"].split('-').first
        @agent = set_agent(listing)
        puts @agent.join(',')
        puts sep
      end
      puts set_branch(listing).join(',')
      puts sep
      sleep 0.5
    end
  end
  private

  def set_agent(listing={})
    listing ||= {}
    type = listing.fetch("type",{})
    [
       listing["name"].split('-').first,
       type.fetch(:sales,false),
       type.fetch(:lettings,false),
       type.fetch(:sales,false) && type.fetch(:lettings,false),
       listing["website"] || "",
       listing["otm"],
       listing["zoop"]
    ]
  end

  def set_branch(listing)
    [
       listing["name"],
       listing["location"][:road],
       listing["location"][:city],
       listing["location"][:post_code]
    ]
  end

  def sub_page(html_listing)
    html_listing.xpath(".%s" % get_sub_page_tag[:path]).attr('href').to_s
  end

  def mpc(doc)
    get_mpc(doc.xpath(get_mpc_tag[:path]))
  end

  def pull_initial
    set_uri(make_uri(@location,0))
    get
    to_doc(body)
  end

  def to_doc(html)
    Nokogiri::HTML(html)
  end

  def pull_infomation_down(doc=nil)
    doc ||= pull_initial
    (mpc(doc) * @inc).times.inject(doc) do |node_doc,index|
      get_listing(node_doc) do |listing|
        yield [listing,index]
      end
      set_uri(make_uri(@location,index))
      get
      to_doc(body)
    end
  end

  def create_agent_record(listing)
    Agent.create(listing)
    Agent.save
  end

  def create_branch_record(listing)
    Branch.create(listing)
    Branch.save
  end

  def get_listing(doc,field_data = nil)
    doc.xpath(get_listing_tag[:path]).each do |html_listing|
      fd = get_field_data_from(html_listing,field_data || {})
      if !field_data && Fields.detect {|field| !fd[field] }
        uri = make_uri(sub_page(html_listing))
        set_uri uri
        get
        fd = get_field_data_from(Nokogiri::HTML(body),fd)
      end
      yield fd
    end
  end


  def get_field_data_from(item,data)
    Fields.inject(data) do |res,field|
      # puts field
      tag = send("get_%s_tag" % field)
      unless !tag || res[field]
        begin
          node =
            (tag[:meta][:before] ? self.send(tag[:meta][:before],item,res) : item)
            .xpath(".%s" % tag[:path])
          if !node.empty?
            res[field] = node.send(*tag[:meta].fetch(:attr,:inner_text)).send(tag[:meta].fetch(:type,:to_s))
            if tag[:meta][:after]
              res[field] = self.send(tag[:meta][:after],res[field],res)
            end
          else
            res[field] = tag[:meta].fetch(:x_path_fail,nil)
          end
        rescue NoMethodError => e
        rescue Exception => e
          puts "Error for field: %s" % field
          raise e
        end
      end
      res
    end
  end

end
