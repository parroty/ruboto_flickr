require 'ruboto/widget'
require "ruboto/util/stack"
with_large_stack {
  require 'flickr_reader'
}

java_import "android.widget.ArrayAdapter"
java_import "android.widget.ListView"
java_import "android.graphics.drawable.Drawable"
java_import "android.os.AsyncTask"
java_import "android.app.ProgressDialog"
java_import "android.content.Context"
java_import "android.content.DialogInterface"
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
    view.setScrollingCacheEnabled(false)

    btn = findViewById(Ruboto::R::id::search_button)
    btn.setOnClickListener(MyOnClickListner.new(self))
  end

  def update_list_view(search_word)
    ImageCache.clear
    view = findViewById(Ruboto::R::id::list_view)
    task = SearchTask.new(self, view, search_word)
    task.execute
  end
end

class MyOnClickListner
  def initialize(activity)
    @activity = activity
  end

  def onClick(view)
    text_view = @activity.findViewById(Ruboto::R::id::search_text)
    @activity.update_list_view("#{text_view.text}")
  end
end

class IconicAdapter < ArrayAdapter
  def initialize(activity, items)
    @activity = activity
    @items    = items

    super(@activity, Ruboto::R::layout::row, Ruboto::R::id::label, @items.map(&:to_s))
  end

  def getView(position, convert_view, parent)
    row  = super
    item = @items[position]

    view = row.findViewById(Ruboto::R::id::icon)
    task = ImageLoadTask.new(@activity, self, item, view)
    task.execute

    size = row.findViewById(Ruboto::R::id::size)
    text = "(#{item.info.owner}) #{item.info.description}"
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

class SearchTask < AsyncTask
  PROGRESS_MAX = 100

  def initialize(context, view, search_word)
    super()
    @context = context
    @view = view
    @search_word = search_word
  end

  def onPreExecute
    @dialog = ProgressDialog.new(@context)
    @dialog.setTitle("Please wait for images to load")
    @dialog.setMessage("Searching flickr ...")
    @dialog.setProgressStyle(ProgressDialog::STYLE_HORIZONTAL)
    @dialog.setCancelable(false)
    @dialog.setMax(PROGRESS_MAX)
    @dialog.setProgress(0)
    @dialog.show
  end

  def onProgressUpdate(values)
    @dialog.setProgress(values.first)
  end

  def doInBackground(param)
    with_large_stack {
      reader = FlickrReader.new
      reader.search(:tag => @search_word, :per_page => IMAGE_PER_PAGE) do |index|
        publishProgress((index + 1) * (PROGRESS_MAX / IMAGE_PER_PAGE))
      end
    }
  end

  def onPostExecute(items)
    @dialog.dismiss
    @view.setAdapter(IconicAdapter.new(@context, items))
  end
end

class ImageLoadTask < AsyncTask
  def initialize(activity, adapter, item, view)
    super()
    @activity = activity
    @adapter  = adapter
    @item     = item
    @view     = view
  end

  def doInBackground(param)
    url = @item.small_image_url
    ImageCache.get(url) || ImageCache.put(url, @adapter.fetch_image(url))
  end

  def onPostExecute(param)
    @view.setImageDrawable(param)
  end
end

class ImageCache
  @@image_hash = {}

  def self.put(key, image)
    @@image_hash[key] = image
  end

  def self.get(key)
    @@image_hash[key]
  end

  def self.clear
    @@image_hash = {}
  end
end
