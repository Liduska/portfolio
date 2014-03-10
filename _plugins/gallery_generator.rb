require 'exifr'
require 'RMagick'
include Magick

include FileUtils

$image_extensions = [".png", ".jpg", ".jpeg", ".gif"]

module Jekyll
  class GalleryFile < StaticFile
    def write(dest)
      return false
    end
  end

  class GalleryPage < Page
    def initialize(site, base, dir, gallery_name)
      @gallery_name = gallery_name
      @site = site
      @base = base
      @dest_dir = dir.gsub("source/", "")
      @dir = @dest_dir
      @name = "index.html"
      @images = []

      max_size_x = 400
      max_size_y = 400
      scale_method = site.config["gallery"]["scale_method"] || "fit"
      begin
        max_size_x = site.config["gallery"]["thumbnail_size"]["x"]
      rescue
      end
      begin
        max_size_y = site.config["gallery"]["thumbnail_size"]["y"]
      rescue
      end
      self.process(@name)
      self.read_yaml(dir, "index.txt")
      self.data["gallery"] = gallery_name
      self.data["name"] = gallery_name
      thumbs_dir = "#{site.dest}/#{@dest_dir}/thumbs"

      FileUtils.mkdir_p(thumbs_dir, :mode => 0755)
      Dir.foreach(dir) do |image|
        if image.chars.first != "." and image.downcase().end_with?(*$image_extensions)
          @images.push(image)
          @site.static_files << GalleryFile.new(site, base, "#{@dest_dir}/thumbs/", image)
          if File.file?("#{thumbs_dir}/#{image}") == false or File.mtime("#{dir}/#{image}") > File.mtime("#{thumbs_dir}/#{image}")
            begin
              m_image = ImageList.new("#{dir}/#{image}")
              m_image.send("resize_to_#{scale_method}!", max_size_x, max_size_y)
              puts "Writing thumbnail to #{thumbs_dir}/#{image}"
              m_image.write("#{thumbs_dir}/#{image}")
            rescue
              puts "error"
              puts $!
            end
            GC.start
          end
        end
      end
      self.data["images"] = @images
    end

    def template
        '/:path/index.html'
    end

    def url_placeholders
      {
        :path => @gallery_name
      }
    end

  end

  class GalleryGenerator < Generator
    safe true

    def generate(site)
      dir = site.config["gallery"]["dir"] || "photos"
      begin
        Dir.foreach(dir) do |gallery_dir|
          gallery_path = File.join(dir, gallery_dir)
          if File.directory?(gallery_path) and gallery_dir.chars.first != "."
            gallery = GalleryPage.new(site, site.source, gallery_path, gallery_dir)
            gallery.render(site.layouts, site.site_payload)
            gallery.write(site.dest)
            site.pages << gallery
          end
        end
      rescue
        puts $!
      end

    end
  end
end
