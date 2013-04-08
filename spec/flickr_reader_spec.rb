require 'rspec'
require 'spec_helper'
require 'flickr_reader'

describe 'FlickrReader' do
  it 'creates instance' do
    FlickrReader.new.should_not be_nil
  end

  it 'search keyword', :vcr do
    reader = FlickrReader.new
    list = reader.search(:tag => 'flower', :per_page => 3)

    list.length.should == 3

    list.each do |photo|
      photo.server.should match(/[0-9]{4}/)
      photo.id.should match(/[0-9]+/)
      photo.secret.should match(/\w{10}/)
      photo.title.should_not be_nil
      photo.small_image_url.should match(/http:\/\/static.flickr.com/)

      photo.info.description.should_not be_nil
      photo.info.url.should match(/http:\/\/www.flickr.com/)
      photo.info.owner.should match(/\w+/)
    end
  end
end
