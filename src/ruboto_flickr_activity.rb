require 'ruboto/widget'
require "ruboto/util/stack"
with_large_stack {
  require 'flickr_reader'
}

java_import "android.widget.ArrayAdapter"
java_import "android.widget.ListView"
java_import "android.graphics.drawable.Drawable"
java_import "android.os.AsyncTask"
java_import "android.util.Log"
java_import "java.net.URL"

ruboto_import_widgets :Button, :LinearLayout, :TextView

IMAGE_PER_PAGE = 10

class RubotoFlickrActivity
  def on_create(bundle)
    super
    setTitle 'Flickr Searcher'
    self.setContentView(Ruboto::R::layout::activity_main)

    view = findViewById(Ruboto::R::id::list_view)
    view.setAdapter(IconicAdapter.new(self, []))

    btn = findViewById(Ruboto::R::id::search_button)
    btn.setOnClickListener(MyOnClickListner.new(self))
  end

  def update_content(text)
    reader = FlickrReader.new
    items = reader.search(:tag => text, :per_page => IMAGE_PER_PAGE)

    view = findViewById(Ruboto::R::id::list_view)
    view.setAdapter(IconicAdapter.new(self, items))
  end
end

class MyOnClickListner
  def initialize(activity)
    @activity = activity
  end

  def onClick(view)
    text_view = @activity.findViewById(Ruboto::R::id::search_text)
    @activity.update_content("#{text_view.text}")
  end
end

class IconicAdapter < ArrayAdapter
  def initialize(activity, items)
    @activity = activity
    @items = items
    @text_items = items.map {|item| item.to_s }

    super(@activity, Ruboto::R::layout::row, Ruboto::R::id::label, @text_items)
  end

  def getView(position, convert_view, parent)
    row = super
    row_item = @items[position]

    view = row.findViewById(Ruboto::R::id::icon)
    task = ImageLoadTask.new(@activity, self, row_item, view)
    task.execute(view)

    size = row.findViewById(Ruboto::R::id::size)
    text = "(#{row_item.info.owner}) #{row_item.info.description}"
    size.setText(text)

    row
  end

  def fetch_image(address)
    input_stream = URL.new(address).getContent
    drawable = Drawable.createFromStream(input_stream, "")
    input_stream.close

    drawable
  end
end

class ImageLoadTask < AsyncTask
  @@image_hash = {}

  def initialize(activity, adapter, item, view)
    super()
    @activity = activity
    @adapter  = adapter
    @item     = item
    @view     = view
  end

  def doInBackground(param)
    url = @item.small_image_url
    @@image_hash[url] ||= @adapter.fetch_image(url)
  end

  def onPostExecute(param)
    @view.setImageDrawable(param)
  end
end
