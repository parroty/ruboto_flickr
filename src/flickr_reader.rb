require 'open-uri'
require 'rexml/document'
require 'cgi'

class FlickrReader
  def search(options)
    photos_xml = API.search(options[:tag], options[:per_page])

    photos = Parser.parse_photos_search(photos_xml)
    photos.each do |photo|
      info_xml = API.get_info(photo.id)
      photo.info = Parser.parse_photos_get_info(info_xml)
    end
    photos
  end
end

class API
  FLICKR_API_URL = "http://www.flickr.com/services/rest/?api_key=%s&method=%s&%s"

  def self.search(tag, per_page = 10)
    exec('flickr.photos.search', 'tags' => tag, 'license' => '4', 'per_page' => per_page.to_s)
  end

  def self.get_info(photo_id)
    exec('flickr.photos.getInfo', 'photo_id' => photo_id.to_s)
  end

private
  def self.exec(method_name, arg_map = {}.freeze)
    args = arg_map.collect do |k,v|
      CGI.escape(k) << '=' << CGI.escape(v)
    end.join('&')

    if ENV['FLICKR_API_KEY']
      api_key = ENV['FLICKR_API_KEY']
    else
      require 'flickr_api_key'
      api_key = FLICKR_API_KEY
    end

    url = FLICKR_API_URL % [api_key, method_name, args]
    REXML::Document.new(open(url).read)
  end
end

class Parser
  def self.parse_photos_search(xml)
    list = []
    REXML::XPath.each(xml, '//photo') do |elem|
      photo = Photo.new
      photo.server = elem.attribute('server').to_s
      photo.id     = elem.attribute('id').to_s
      photo.secret = elem.attribute('secret').to_s
      photo.title  = elem.attribute('title').to_s

      list << photo
    end
    list
  end

  def self.parse_photos_get_info(xml)
    info = PhotoInfo.new
    info.description = REXML::XPath.first(xml, '//description').text || ""
    info.url         = REXML::XPath.first(xml, '//url').text || ""
    info.owner       = REXML::XPath.first(xml, '//owner').attribute('username').to_s
    info
  end
end

class Photo
  attr_accessor :server, :id, :secret, :title, :info

  def small_image_url
    "http://static.flickr.com/#{@server}/#{@id}_#{@secret}_m.jpg"
  end

  def info=(info)
    @info = info
  end

  def to_s
    title
  end
end

class PhotoInfo
  attr_accessor :description, :url, :owner
end
